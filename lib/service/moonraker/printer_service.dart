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

import '../../data/dto/machine/mmu/afc_state.dart';
import '../../data/dto/machine/mmu/happy_hare_state.dart';
import '../../data/dto/machine/mmu/mmu_state.dart';
import '../../data/dto/machine/printer.dart';
import '../../util/url_utils.dart';
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
  String? _httpBaseUrl;

  final _printerSubject = BehaviorSubject<Printer>.seeded(const Printer());
  Stream<Printer> get printerStream => _printerSubject.stream;
  Printer get current => _printerSubject.value;
  final _objectState = <String, Object?>{};
  String? _detectedWebcamUrl;

  String? get detectedWebcamUrl => _detectedWebcamUrl;
  Map<String, dynamic>? objectData(String key) => _asMap(_objectState[key]);
  Object? objectValue(String key) => _objectState[key];

  List<MapEntry<String, Map<String, dynamic>>> get thermalSensors {
    final sensors = <MapEntry<String, Map<String, dynamic>>>[];
    for (final entry in _objectState.entries) {
      if (!_isThermalObjectKey(entry.key)) continue;
      final value = _asMap(entry.value);
      if (value != null) {
        sensors.add(MapEntry(entry.key, value));
      }
    }
    return sensors;
  }

  List<MapEntry<String, Object?>> get binarySensors => _objectState.entries
      .where((entry) => _isBinarySensorObjectKey(entry.key))
      .toList(growable: false);

  AfcState? get afcState {
    if (_objectState.keys.every((key) => key != 'AFC' && !key.startsWith('AFC_'))) {
      return null;
    }
    return AfcState.fromMoonrakerJson(Map<String, dynamic>.from(_objectState));
  }

  HappyHareState? get happyHareState {
    final mmu = _objectState['mmu'];
    if (mmu == null) return null;
    return HappyHareState.fromMoonrakerJson({'mmu': mmu});
  }

  final _pendingRequests = <int, Completer<dynamic>>{};

  /// Connect to Moonraker at [wsUrl] with an optional [apiKey].
  Future<void> connect(String wsUrl, {String? apiKey}) async {
    await disconnect();
    appLogger.info('PrinterService[$machineId]: connecting to $wsUrl');
    _httpBaseUrl = _deriveHttpBaseUrl(wsUrl);
    _objectState.clear();
    _detectedWebcamUrl = null;

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
      appLogger.error('PrinterService[$machineId]: connection failed', e, st);
    }
  }

  Future<void> disconnect() async {
    await _wsSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _wsSub = null;
    _objectState.clear();
    _detectedWebcamUrl = null;
  }

  // ── Public control API (all features free) ────────────────────────────────

  /// Send any G-code script.  Used for tool changes, MMU commands, macros.
  Future<void> sendGcode(String script) async {
    await _call('printer.gcode.script', {'script': script});
  }

  /// Send a raw Moonraker JSON-RPC request and return the decoded result.
  Future<dynamic> sendJsonRpc(
    String method, [
    Map<String, dynamic> params = const {},
  ]) {
    return _call(method, params);
  }

  /// Select an MMU tool by index (sends T0, T1, … G-code).
  Future<void> selectMmuTool(int toolIndex) =>
      sendGcode('T$toolIndex');

  /// Alias used by some dashboard widgets.
  Future<void> changeTool(int toolIndex) => selectMmuTool(toolIndex);

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
    final listResult =
        await _call('printer.objects.list', {}) as Map<String, dynamic>;
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
    //    This step is best-effort: large Happy Hare responses can trigger a
    //    StackOverflowError in jsonDecode (deeply nested JSON).  When that
    //    happens we fall back to an empty-but-correct Printer so we can still
    //    subscribe to live updates and populate state incrementally.
    Printer printer;
    try {
      final queryResult = await _call('printer.objects.query', {
        'objects': subscribeObjects,
      }) as Map<String, dynamic>;
      final status = queryResult['status'] as Map<String, dynamic>? ?? {};
      _replaceObjectState(status);
      printer = _buildPrinter(
        status: status,
        availableObjects: objects,
        availableMacros: macros,
        hasMmu: hasMmu,
        mmuObjectKey: mmuObjectKey,
      );
    } catch (e) {
      appLogger.warning(
        'PrinterService[$machineId]: initial state query failed ($e) '
        '– will populate state via subscription updates',
      );
      // Seed a minimal-but-correct Printer so _applyDelta can process MMU
      // deltas as soon as they arrive (it keys off mmuState.objectKey).
      printer = Printer(
        klippyReady: true,
        klippyState: 'ready',
        hasMmu: hasMmu,
        mmuState: hasMmu && mmuObjectKey != null
            ? MmuState(objectKey: mmuObjectKey)
            : null,
        availableObjects: objects,
        availableMacros: macros,
      );
    }
    _printerSubject.add(printer);

    // 7. Subscribe to live updates.
    try {
      await _call('printer.objects.subscribe', {
        'objects': subscribeObjects,
      });
      unawaited(_discoverWebcamUrl());
    } catch (e) {
      appLogger.warning(
        'PrinterService[$machineId]: subscribe call failed ($e) '
        '– live updates may not arrive',
      );
    }

    appLogger.info(
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
      'toolhead': const ['extruder', 'position', 'homed_axes', 'max_velocity'],
      'gcode_move': const [
        'speed_factor',
        'extrude_factor',
        'homing_origin',
        'gcode_position',
      ],
      'extruder': const [
        'temperature',
        'target',
        'power',
        'can_extrude',
        'pressure_advance',
        'smooth_time',
      ],
      'heater_bed': const ['temperature', 'target', 'power'],
      'print_stats': const [
        'state',
        'filename',
        'message',
        'info',
        'progress',
        'print_duration',
      ],
      'display_status': const ['progress', 'message'],
    };
    // Add extra extruders if present.
    for (int i = 1; i <= 8; i++) {
      if (objects.contains('extruder$i')) {
        sub['extruder$i'] = const [
          'temperature',
          'target',
          'power',
          'can_extrude',
          'pressure_advance',
          'smooth_time',
        ];
      }
    }

    for (final object in objects) {
      if (_isThermalObjectKey(object)) {
        sub[object] = const ['temperature', 'target', 'power'];
      } else if (_isBinarySensorObjectKey(object)) {
        sub[object] = const [
          'filament_detected',
          'enabled',
          'state',
          'detected',
          'triggered',
        ];
      }
    }

    _addObjectIfPresent(sub, objects, 'bed_mesh', const [
      'profile_name',
      'mesh_matrix',
      'probed_matrix',
    ]);
    _addObjectIfPresent(sub, objects, 'probe', const ['last_z_result']);
    _addObjectIfPresent(sub, objects, 'bltouch', const ['mode']);
    _addObjectIfPresent(sub, objects, 'z_tilt', const ['applied']);
    _addObjectIfPresent(sub, objects, 'quad_gantry_level', const ['applied']);
    _addObjectIfPresent(sub, objects, 'screws_tilt_adjust', const ['results']);
    _addObjectIfPresent(sub, objects, 'fan', const ['speed']);

    for (final object in objects.where((value) => value.startsWith('AFC_'))) {
      if (object.startsWith('AFC_lane ')) {
        sub[object] = const [
          'lane_name',
          'name',
          'state',
          'status',
          'filament_present',
          'loaded',
          'has_filament',
          'extruder_present',
          'tool_loaded',
          'at_extruder',
          'material',
          'color',
          'colour',
          'spool_id',
          'remaining_mm',
        ];
      } else if (object == 'AFC_hub' || object.startsWith('AFC_extruder ')) {
        sub[object] = const [
          'filament_present',
          'loaded',
          'has_filament',
          'state',
          'status',
        ];
      } else if (object == 'AFC_buffer') {
        sub[object] = const ['state', 'status'];
      } else {
        sub[object] = null;
      }
    }
    if (objects.contains('AFC')) {
      sub['AFC'] = const [
        'status',
        'state',
        'lanes',
        'hub',
        'buffer',
        'active_lane',
        'current_lane',
        'lane',
        'last_error',
        'error',
      ];
    }

    if (mmuObjectKey != null) {
      sub[mmuObjectKey] = const [
        'tool',
        'current_tool',
        'selected_tool',
        'tool_selected',
        'num_gates',
        'tool_count',
        'is_homed',
        'state',
        'print_state',
        'last_error',
        'error',
        'slicer_colors',
        'gates',
        'gate_status',
        'gate_states',
        'gate_statuses',
        'is_paused',
        'paused',
        'is_bypass',
        'bypass',
        'endless_spool',
        'endless_spool_enabled',
        'endless_spool_groups',
        'servo_state',
        'servo',
        'filament_position',
        'filament_pos',
        'filament_state',
        'filament_remaining',
        'remaining_grams',
        'spoolman_remaining',
        'is_printing',
        'printing',
        'print_stats',
        'mmu_print_stats',
        'statistics',
      ];
    }
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
    final gcodeMoveData = status['gcode_move'] as Map<String, dynamic>? ?? {};
    final printStatsData = status['print_stats'] as Map<String, dynamic>? ?? {};
    final displayStatusData =
        status['display_status'] as Map<String, dynamic>? ?? {};
    final bedData = status['heater_bed'] as Map<String, dynamic>? ?? {};
    final homedAxes =
        (toolheadData['homed_axes'] as String? ?? '').toLowerCase();
    final position = _parsePosition(
      toolheadData['position'] as List?,
      gcodeMoveData['gcode_position'] as List?,
    );

    final toolhead = Toolhead(
      activeExtruder: toolheadData['extruder'] as String? ?? 'extruder',
      position: position,
      homedX: homedAxes.contains('x'),
      homedY: homedAxes.contains('y'),
      homedZ: homedAxes.contains('z'),
      printSpeed: (toolheadData['max_velocity'] as num?)?.toDouble() ?? 0,
      speedFactor: _normalizeFactor(gcodeMoveData['speed_factor']),
      extrudeFactor: _normalizeFactor(gcodeMoveData['extrude_factor']),
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
      printProgress: (printStatsData['progress'] as num?)?.toDouble() ??
          (displayStatusData['progress'] as num?)?.toDouble() ??
          0,
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
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      // This can be a StackOverflowError for very large / deeply-nested Happy
      // Hare responses, or any other decoding failure.  Fail all pending RPC
      // completers immediately so callers don't wait for the full 10 s timeout.
      appLogger.warning('PrinterService[$machineId]: parse error: $e');
      _failPendingRequests(e);
      return;
    }

    // Response to a request we sent.
    final id = msg['id'] as int?;
    if (id != null) {
      final completer = _pendingRequests.remove(id);
      if (completer != null) {
        final error = msg['error'];
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete(msg['result']);
        }
      }
      return;
    }

    // Unsolicited notification.
    final method = msg['method'] as String?;
    if (method == 'notify_status_update') {
      final params = msg['params'];
      if (params is List && params.isNotEmpty) {
        final firstParam = params.first;
        if (firstParam is Map<String, dynamic>) {
          final delta = firstParam;
          _applyDelta(delta);
        } else if (firstParam is Map &&
            firstParam.keys.every((key) => key is String)) {
          final delta = Map<String, dynamic>.from(firstParam);
          _applyDelta(delta);
        }
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
  }

  /// Completes every pending RPC request with [error] and clears the map.
  ///
  /// Called when a WebSocket message cannot be decoded, so callers are not
  /// left waiting for the full 10 s [_call] timeout.
  void _failPendingRequests(Object error) {
    if (_pendingRequests.isEmpty) return;
    final toFail = Map.of(_pendingRequests);
    _pendingRequests.clear();
    final exception =
        error is Exception ? error : Exception('parse error: $error');
    for (final completer in toFail.values) {
      if (!completer.isCompleted) completer.completeError(exception);
    }
  }

  void _applyDelta(Map<String, dynamic> delta) {
    _mergeObjectState(delta);
    final existing = current;
    final rebuilt = _buildPrinter(
      status: _mapStatusSnapshot(),
      availableObjects: existing.availableObjects,
      availableMacros: existing.availableMacros,
      hasMmu: existing.hasMmu,
      mmuObjectKey: existing.mmuState?.objectKey ?? _findMmuObjectKey(existing.availableObjects),
    ).copyWith(
      klippyReady: existing.klippyReady,
      klippyState: existing.klippyState,
      klippyStateMessage: existing.klippyStateMessage,
    );
    _printerSubject.add(rebuilt);
  }

  void _onError(Object error) {
    appLogger.error('PrinterService[$machineId]: WebSocket error', error);
    _printerSubject.add(current.copyWith(
      klippyReady: false,
      klippyState: 'error',
      klippyStateMessage: error.toString(),
    ));
  }

  void _onDone() {
    appLogger.info('PrinterService[$machineId]: WebSocket closed');
    _printerSubject.add(current.copyWith(
      klippyReady: false,
      klippyState: 'disconnected',
    ));
  }

  // ── JSON-RPC helpers ──────────────────────────────────────────────────────

  Future<dynamic> _call(
    String method,
    Map<String, dynamic> params,
  ) async {
    final id = _msgId++;
    final completer = Completer<dynamic>();
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

  Future<void> _discoverWebcamUrl() async {
    final baseUrl = _httpBaseUrl;
    if (baseUrl == null || _detectedWebcamUrl != null) return;

    try {
      final result = await _call('server.webcams.list', const {});
      final webcamUrl = extractMoonrakerWebcamUrl(baseUrl, result);
      if (webcamUrl != null) {
        _detectedWebcamUrl = webcamUrl;
        _printerSubject.add(current);
      }
    } catch (_) {
      // Webcam discovery is best-effort only.
    }
  }

  void _replaceObjectState(Map<String, dynamic> status) {
    _objectState
      ..clear()
      ..addAll(status);
  }

  void _mergeObjectState(Map<String, dynamic> delta) {
    for (final entry in delta.entries) {
      final existing = _asMap(_objectState[entry.key]);
      final next = _asMap(entry.value);
      if (existing != null && next != null) {
        _objectState[entry.key] = {...existing, ...next};
      } else {
        _objectState[entry.key] = entry.value;
      }
    }
  }

  Map<String, dynamic> _mapStatusSnapshot() {
    final snapshot = <String, dynamic>{};
    for (final entry in _objectState.entries) {
      final value = _asMap(entry.value);
      if (value != null) {
        snapshot[entry.key] = value;
      }
    }
    return snapshot;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static void _addObjectIfPresent(
    Map<String, dynamic> target,
    List<String> objects,
    String objectName,
    List<String> fields,
  ) {
    if (objects.contains(objectName)) {
      target[objectName] = fields;
    }
  }

  static bool _isThermalObjectKey(String key) {
    return key.startsWith('temperature_sensor ') ||
        key.startsWith('heater_generic ') ||
        key.startsWith('temperature_fan ') ||
        key == 'chamber' ||
        key == 'frame_temp';
  }

  static bool _isBinarySensorObjectKey(String key) {
    return key.startsWith('filament_switch_sensor ') ||
        key.startsWith('filament_motion_sensor ') ||
        key.startsWith('switch_sensor ') ||
        key.startsWith('endstop_phase ');
  }

  static List<double> _parsePosition(List? primary, List? fallback) {
    final values = (primary ?? fallback ?? const [])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList(growable: true);
    while (values.length < 4) {
      values.add(0);
    }
    return values.take(4).toList(growable: false);
  }

  static double _normalizeFactor(Object? value) {
    final raw = (value as num?)?.toDouble() ?? 1.0;
    // Klipper/Moonraker can report overrides either as decimals (1.0 = 100%)
    // or as whole percentages (100 = 100%), so normalize both formats.
    return raw > 5 ? raw / 100.0 : raw;
  }

  static String? _deriveHttpBaseUrl(String wsUrl) {
    final uri = Uri.tryParse(wsUrl);
    if (uri == null || uri.host.isEmpty) return null;
    final scheme = uri.scheme == 'wss' ? 'https' : 'http';
    final base = Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
    return base.toString().replaceAll(RegExp(r'/$'), '');
  }
}
