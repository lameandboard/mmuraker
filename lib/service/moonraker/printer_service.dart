// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/dto/machine/mmu/mmu_state.dart';
import '../../data/dto/machine/printer.dart';
import '../../util/logger.dart';

part 'printer_service.g.dart';

@riverpod
PrinterService printerService(Ref ref, String machineId) =>
    PrinterService(ref, machineId);

/// Manages the WebSocket connection to a single Moonraker instance and
/// exposes a live [Printer] state stream.
///
/// Architecture note: mirrors the printer service pattern in mobileraker's
/// `common/lib/service/moonraker/printer_service.dart`.
///
/// Key Moonraker JSON-RPC methods used:
///   • printer.objects.list   — discover available objects (MMU detection)
///   • printer.objects.query  — initial full state fetch
///   • printer.objects.subscribe — receive state deltas
///   • printer.gcode.script   — send G-code (tool changes, macros)
class PrinterService {
  PrinterService(this._ref, this.machineId);

  final Ref _ref;
  final String machineId;

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  int _msgId = 1;

  final _printerSubject = BehaviorSubject<Printer>.seeded(const Printer());
  Stream<Printer> get printerStream => _printerSubject.stream;
  Printer get current => _printerSubject.value;

  final _pendingRequests = <int, Completer<Map<String, dynamic>>>{};

  /// Connect to Moonraker at [wsUrl] with an optional [apiKey].
  Future<void> connect(String wsUrl, {String? apiKey}) async {
    await disconnect();
    logger.info('PrinterService[$machineId]: connecting to $wsUrl');

    final headers = <String, dynamic>{};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['X-Api-Key'] = apiKey;
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: const ['moonraker'],
      );
      _wsSub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      await _initializePrinterState();
    } catch (e, st) {
      logger.error('PrinterService[$machineId]: connection failed', e, st);
    }
  }

  Future<void> disconnect() async {
    await _wsSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _wsSub = null;
  }

  // ── Public control API (all features free) ────────────────────────────────

  /// Send any G-code script.  Used for tool changes, MMU commands, macros.
  Future<void> sendGcode(String script) async {
    await _call('printer.gcode.script', {'script': script});
  }

  /// Select an MMU tool by index (sends T0, T1, … G-code).
  Future<void> selectMmuTool(int toolIndex) =>
      sendGcode('T$toolIndex');

  /// Call a named G-code macro with optional parameters.
  Future<void> runMacro(String macroName, [Map<String, String>? params]) {
    var script = macroName;
    if (params != null && params.isNotEmpty) {
      final args = params.entries.map((e) => '${e.key}=${e.value}').join(' ');
      script = '$macroName $args';
    }
    return sendGcode(script);
  }

  /// Set extruder target temperature.
  Future<void> setExtruderTemp(int extruderIndex, double temp) {
    final extruder = extruderIndex == 0 ? 'extruder' : 'extruder$extruderIndex';
    return sendGcode('SET_HEATER_TEMPERATURE HEATER=$extruder TARGET=$temp');
  }

  /// Set heated bed target temperature.
  Future<void> setBedTemp(double temp) =>
      sendGcode('SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=$temp');

  /// Emergency stop.
  Future<void> emergencyStop() => sendGcode('M112');

  /// Pause / resume / cancel print.
  Future<void> pausePrint() => sendGcode('PAUSE');
  Future<void> resumePrint() => sendGcode('RESUME');
  Future<void> cancelPrint() => sendGcode('CANCEL_PRINT');

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _initializePrinterState() async {
    // 1. Discover available objects (used for MMU detection).
    final listResult = await _call('printer.objects.list', {});
    final objects = (listResult['objects'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // 2. Discover available G-code macros.
    final macros = objects
        .where((o) => o.startsWith('gcode_macro '))
        .map((o) => o.replaceFirst('gcode_macro ', '').toUpperCase())
        .toList();

    // 3. Detect MMU from available objects and macros.
    final hasMmu = _detectMmu(objects, macros);
    final mmuObjectKey = _findMmuObjectKey(objects);

    // 4. Build subscription object map.
    final subscribeObjects = _buildSubscribeObjects(objects, mmuObjectKey);

    // 5. Query current full state.
    final queryResult = await _call('printer.objects.query', {
      'objects': subscribeObjects,
    });
    final status = queryResult['status'] as Map<String, dynamic>? ?? {};

    // 6. Build initial printer state.
    var printer = _buildPrinter(
      status: status,
      availableObjects: objects,
      availableMacros: macros,
      hasMmu: hasMmu,
      mmuObjectKey: mmuObjectKey,
    );
    _printerSubject.add(printer);

    // 7. Subscribe to live updates.
    await _call('printer.objects.subscribe', {
      'objects': subscribeObjects,
    });

    logger.info(
      'PrinterService[$machineId]: initialised '
      '(klippy=${printer.klippyState}, hasMmu=$hasMmu)',
    );
  }

  // ── MMU detection ─────────────────────────────────────────────────────────

  static bool _detectMmu(List<String> objects, List<String> macros) {
    // Happy Hare / Enraged Rabbit / generic MMU object names.
    const mmuObjectPrefixes = ['mmu', 'ercf', 'trad_rack'];
    if (objects.any((o) =>
        mmuObjectPrefixes.any((p) => o == p || o.startsWith('$p ')))) {
      return true;
    }
    // T0/T1/… tool-change macros are a strong MMU signal.
    if (macros.any((m) => RegExp(r'^T\d+$').hasMatch(m))) {
      return true;
    }
    return false;
  }

  static String? _findMmuObjectKey(List<String> objects) {
    const candidates = ['mmu', 'ercf', 'trad_rack'];
    for (final key in candidates) {
      if (objects.contains(key)) return key;
    }
    return null;
  }

  Map<String, dynamic> _buildSubscribeObjects(
    List<String> objects,
    String? mmuObjectKey,
  ) {
    final sub = <String, dynamic>{
      'toolhead': null,
      'extruder': null,
      'heater_bed': null,
      'print_stats': null,
      'display_status': null,
    };
    // Add extra extruders if present.
    for (int i = 1; i <= 8; i++) {
      if (objects.contains('extruder$i')) sub['extruder$i'] = null;
    }
    // Subscribe to MMU object if found.
    if (mmuObjectKey != null) sub[mmuObjectKey] = null;
    return sub;
  }

  // ── State parsing ─────────────────────────────────────────────────────────

  Printer _buildPrinter({
    required Map<String, dynamic> status,
    required List<String> availableObjects,
    required List<String> availableMacros,
    required bool hasMmu,
    String? mmuObjectKey,
  }) {
    final toolheadData = status['toolhead'] as Map<String, dynamic>? ?? {};
    final printStatsData = status['print_stats'] as Map<String, dynamic>? ?? {};
    final bedData = status['heater_bed'] as Map<String, dynamic>? ?? {};

    final toolhead = Toolhead(
      activeExtruder: toolheadData['extruder'] as String? ?? 'extruder',
      position: (toolheadData['position'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0, 0, 0, 0],
      printSpeed: (toolheadData['max_velocity'] as num?)?.toDouble() ?? 0,
    );

    final extruders = _parseExtruders(status);

    final heatedBed = bedData.isNotEmpty
        ? TemperatureSensor(
            name: 'heater_bed',
            temperature: (bedData['temperature'] as num?)?.toDouble() ?? 0,
            target: (bedData['target'] as num?)?.toDouble() ?? 0,
            power: (bedData['power'] as num?)?.toDouble() ?? 0,
          )
        : null;

    MmuState? mmuState;
    if (hasMmu && mmuObjectKey != null) {
      final mmuData =
          status[mmuObjectKey] as Map<String, dynamic>? ?? {};
      mmuState = _parseMmuState(mmuData, mmuObjectKey);
    }

    return Printer(
      klippyReady: true,
      klippyState: 'ready',
      toolhead: toolhead,
      extruders: extruders,
      printState: printStatsData['state'] as String? ?? 'idle',
      printProgress: (printStatsData['progress'] as num?)?.toDouble() ?? 0,
      heatedBed: heatedBed,
      mmuState: mmuState,
      hasMmu: hasMmu,
      availableObjects: availableObjects,
      availableMacros: availableMacros,
    );
  }

  List<Extruder> _parseExtruders(Map<String, dynamic> status) {
    final result = <Extruder>[];
    final names = ['extruder', ...List.generate(8, (i) => 'extruder${i + 1}')];
    for (int i = 0; i < names.length; i++) {
      final data = status[names[i]] as Map<String, dynamic>?;
      if (data == null) break;
      result.add(Extruder(
        index: i,
        temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
        target: (data['target'] as num?)?.toDouble() ?? 0,
        power: (data['power'] as num?)?.toDouble() ?? 0,
        canExtrude: data['can_extrude'] as bool? ?? false,
        pressureAdvance: (data['pressure_advance'] as num?)?.toDouble() ?? 0,
        smoothTime: (data['smooth_time'] as num?)?.toDouble() ?? 0,
      ));
    }
    if (result.isEmpty) result.add(const Extruder());
    return result;
  }

  MmuState _parseMmuState(Map<String, dynamic> data, String objectKey) {
    final activeTool = (data['tool'] as num?)?.toInt() ??
        (data['current_tool'] as num?)?.toInt() ??
        -1;
    final toolCount = (data['num_gates'] as num?)?.toInt() ??
        (data['tool_count'] as num?)?.toInt() ??
        0;
    final busy = data['is_homed'] == false ||
        (data['print_state'] as String? ?? '') == 'loading' ||
        (data['print_state'] as String? ?? '') == 'unloading';
    final error = data['last_error'] as String? ??
        data['error'] as String?;
    final colors = (data['slicer_colors'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return MmuState(
      activeTool: activeTool,
      toolCount: toolCount,
      busy: busy,
      error: error,
      printState: data['print_state'] as String? ?? 'unknown',
      filamentColors: colors,
      objectKey: objectKey,
    );
  }

  // ── WebSocket I/O ─────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;

      // Response to a request we sent.
      final id = msg['id'] as int?;
      if (id != null) {
        final completer = _pendingRequests.remove(id);
        if (completer != null) {
          final error = msg['error'];
          if (error != null) {
            completer.completeError(error);
          } else {
            completer.complete(
              (msg['result'] as Map<String, dynamic>?) ?? {},
            );
          }
        }
        return;
      }

      // Unsolicited notification.
      final method = msg['method'] as String?;
      if (method == 'notify_status_update') {
        final params = msg['params'] as List?;
        if (params != null && params.isNotEmpty) {
          final delta = params[0] as Map<String, dynamic>;
          _applyDelta(delta);
        }
      } else if (method == 'notify_klippy_ready') {
        _printerSubject.add(current.copyWith(
          klippyReady: true,
          klippyState: 'ready',
        ));
      } else if (method == 'notify_klippy_shutdown' ||
          method == 'notify_klippy_disconnected') {
        _printerSubject.add(current.copyWith(
          klippyReady: false,
          klippyState: method == 'notify_klippy_shutdown'
              ? 'shutdown'
              : 'disconnected',
        ));
      }
    } catch (e) {
      logger.warning('PrinterService[$machineId]: parse error: $e');
    }
  }

  void _applyDelta(Map<String, dynamic> delta) {
    var printer = current;

    if (delta.containsKey('toolhead')) {
      final th = delta['toolhead'] as Map<String, dynamic>;
      printer = printer.copyWith(
        toolhead: printer.toolhead.copyWith(
          activeExtruder:
              th['extruder'] as String? ?? printer.toolhead.activeExtruder,
          printSpeed: (th['max_velocity'] as num?)?.toDouble() ??
              printer.toolhead.printSpeed,
        ),
      );
    }

    if (delta.containsKey('print_stats')) {
      final ps = delta['print_stats'] as Map<String, dynamic>;
      printer = printer.copyWith(
        printState: ps['state'] as String? ?? printer.printState,
        printProgress: (ps['progress'] as num?)?.toDouble() ??
            printer.printProgress,
      );
    }

    // MMU delta.
    final mmuKey = printer.mmuState?.objectKey;
    if (mmuKey != null && delta.containsKey(mmuKey)) {
      final mmuDelta = delta[mmuKey] as Map<String, dynamic>;
      final existing = printer.mmuState!;
      printer = printer.copyWith(
        mmuState: existing.copyWith(
          activeTool: (mmuDelta['tool'] as num?)?.toInt() ??
              (mmuDelta['current_tool'] as num?)?.toInt() ??
              existing.activeTool,
          printState: mmuDelta['print_state'] as String? ?? existing.printState,
          error: mmuDelta['last_error'] as String? ?? existing.error,
          busy: mmuDelta['print_state'] == 'loading' ||
              mmuDelta['print_state'] == 'unloading',
        ),
      );
    }

    _printerSubject.add(printer);
  }

  void _onError(Object error) {
    logger.error('PrinterService[$machineId]: WebSocket error', error);
    _printerSubject.add(current.copyWith(
      klippyReady: false,
      klippyState: 'error',
      klippyStateMessage: error.toString(),
    ));
  }

  void _onDone() {
    logger.info('PrinterService[$machineId]: WebSocket closed');
    _printerSubject.add(current.copyWith(
      klippyReady: false,
      klippyState: 'disconnected',
    ));
  }

  // ── JSON-RPC helpers ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(
    String method,
    Map<String, dynamic> params,
  ) async {
    final id = _msgId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': id,
    });
    _channel?.sink.add(payload);

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('Moonraker call timed out: $method');
      },
    );
  }
}
