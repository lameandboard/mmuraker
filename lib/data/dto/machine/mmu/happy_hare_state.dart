// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'happy_hare_state.freezed.dart';

/// Full Happy Hare MMU state as exposed through Moonraker's `mmu` object.
@freezed
class HappyHareState with _$HappyHareState {
  const factory HappyHareState({
    /// Overall MMU state string from Happy Hare.
    @Default('idle') String state,

    /// Currently selected tool index, -1 = no tool, -2 = bypass.
    @Default(-1) int toolSelected,

    /// Number of configured gates/tools.
    @Default(0) int numGates,

    /// Per-gate state snapshots.
    @Default([]) List<HappyHareGateStatus> gates,

    /// Whether the MMU is paused and waiting for user action.
    @Default(false) bool isPaused,

    /// Whether the MMU is running in bypass mode.
    @Default(false) bool isBypass,

    /// Last MMU error string.
    @Default('') String lastError,

    /// Whether endless spool mode is enabled.
    @Default(false) bool endlessSpoolEnabled,

    /// Endless spool group mapping (tool index -> group id).
    @Default({}) Map<int, int> endlessSpoolGroups,

    /// Servo state: up/down/move/unknown.
    @Default('unknown') String servoState,

    /// Filament position in the MMU path.
    @Default('unknown') String filamentPosition,

    /// Remaining filament in grams (-1 when unknown).
    @Default(-1) double filamentRemaining,

    /// Whether Happy Hare reports an active print job.
    @Default(false) bool isPrinting,

    /// Calibrated per-gate offsets in mm.
    @Default([]) List<double> gateOffsets,

    /// Optional Happy Hare print statistics.
    HappyHarePrintStats? printStats,
  }) = _HappyHareState;

  const HappyHareState._();

  bool get hasError => lastError.isNotEmpty;

  bool get isIdle =>
      state == 'idle' || state == 'ready' || state == 'standby';

  bool get isBusy => !isIdle && !hasError && !isPaused;

  String get stateDisplay {
    if (state.isEmpty) return 'Unknown';
    return state
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(_capitalizeWord)
        .join(' ');
  }

  static HappyHareState fromMoonrakerJson(Map<String, dynamic> json) {
    final data = _extractMoonrakerObject(json, 'mmu');
    final endlessSpool = _asMap(data['endless_spool']);
    final printStatsMap = _firstMap(
      data['print_stats'],
      data['mmu_print_stats'],
      data['statistics'],
    );

    final gates = _parseHappyHareGates(
      _firstValue(
        data['gates'],
        data['gate_status'],
        data['gate_states'],
        data['gate_statuses'],
      ),
    );

    final gateOffsets = _parseDoubleList(
      _firstValue(data['gate_offsets'], data['selector_offsets']),
    );

    final endlessSpoolGroups = _parseIntMap(
      _firstValue(
        data['endless_spool_groups'],
        endlessSpool['groups'],
        data['spool_groups'],
      ),
    );

    final numGates =
        _toInt(_firstValue(data['num_gates'], data['tool_count'], data['gates'])) ??
            gates.length;

    return HappyHareState(
      state: _toStringValue(_firstValue(data['state'], data['print_state'])) ??
          'idle',
      toolSelected: _toInt(_firstValue(
            data['tool_selected'],
            data['tool'],
            data['current_tool'],
            data['selected_tool'],
          )) ??
          -1,
      numGates: numGates,
      gates: gates,
      isPaused: _toBool(_firstValue(data['is_paused'], data['paused'])) ?? false,
      isBypass: _toBool(_firstValue(data['is_bypass'], data['bypass'])) ??
          ((_toInt(_firstValue(
                    data['tool_selected'],
                    data['tool'],
                    data['current_tool'],
                    data['selected_tool'],
                  )) ??
                  -1) ==
              -2),
      lastError:
          _toStringValue(_firstValue(data['last_error'], data['error'])) ?? '',
      endlessSpoolEnabled: _toBool(_firstValue(
            data['endless_spool_enabled'],
            endlessSpool['enabled'],
          )) ??
          false,
      endlessSpoolGroups: endlessSpoolGroups,
      servoState:
          _toStringValue(_firstValue(data['servo_state'], data['servo'])) ??
              'unknown',
      filamentPosition: _toStringValue(_firstValue(
            data['filament_position'],
            data['filament_pos'],
            data['filament_state'],
          )) ??
          'unknown',
      filamentRemaining: _toDouble(_firstValue(
            data['filament_remaining'],
            data['remaining_grams'],
            data['spoolman_remaining'],
          )) ??
          -1,
      isPrinting: _toBool(_firstValue(
            data['is_printing'],
            data['printing'],
          )) ??
          (_toStringValue(_asMap(data['job'])['state']) == 'printing') ||
          (_toStringValue(_asMap(data['print_stats'])['state']) == 'printing'),
      gateOffsets: gateOffsets,
      printStats: printStatsMap.isEmpty
          ? null
          : HappyHarePrintStats(
              totalTool_changes: _toInt(_firstValue(
                    printStatsMap['total_tool_changes'],
                    printStatsMap['totalTool_changes'],
                    printStatsMap['totalTool_changesCount'],
                    printStatsMap['totalTool_changesCount'],
                  )) ??
                  0,
              toolChanges: _toInt(_firstValue(
                    printStatsMap['tool_changes'],
                    printStatsMap['toolChanges'],
                  )) ??
                  0,
              loadRetries: _toInt(_firstValue(
                    printStatsMap['load_retries'],
                    printStatsMap['loadRetries'],
                  )) ??
                  0,
              failedLoadRetries: _toInt(_firstValue(
                    printStatsMap['failed_load_retries'],
                    printStatsMap['failedLoadRetries'],
                  )) ??
                  0,
            ),
    );
  }
}

@freezed
class HappyHareGateStatus with _$HappyHareGateStatus {
  const factory HappyHareGateStatus({
    required int gateIndex,
    @Default('unknown') String status,
    @Default('') String material,
    @Default('') String color,
    @Default(-1) int spoolId,
    @Default(1.0) double speedFactor,
  }) = _HappyHareGateStatus;

  const HappyHareGateStatus._();
}

@freezed
class HappyHarePrintStats with _$HappyHarePrintStats {
  const factory HappyHarePrintStats({
    @Default(0) int totalTool_changes,
    @Default(0) int toolChanges,
    @Default(0) int loadRetries,
    @Default(0) int failedLoadRetries,
  }) = _HappyHarePrintStats;

  const HappyHarePrintStats._();
}

Map<String, dynamic> _extractMoonrakerObject(
  Map<String, dynamic> json,
  String key,
) {
  final nested = _asMap(json[key]);
  if (nested.isNotEmpty) return nested;
  return json;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is List) return value;
  return const [];
}

Object? _firstValue(Object? first, [Object? second, Object? third, Object? fourth]) {
  for (final value in [first, second, third, fourth]) {
    if (value != null) return value;
  }
  return null;
}

Map<String, dynamic> _firstMap(Object? first, [Object? second, Object? third]) {
  for (final value in [first, second, third]) {
    final map = _asMap(value);
    if (map.isNotEmpty) return map;
  }
  return const <String, dynamic>{};
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is List) return value.length;
  return null;
}

double? _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case 'on':
      case 'yes':
      case '1':
        return true;
      case 'false':
      case 'off':
      case 'no':
      case '0':
        return false;
    }
  }
  return null;
}

String? _toStringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

List<double> _parseDoubleList(Object? value) {
  return _asList(value)
      .map(_toDouble)
      .whereType<double>()
      .toList(growable: false);
}

Map<int, int> _parseIntMap(Object? value) {
  if (value is List) {
    final result = <int, int>{};
    for (int i = 0; i < value.length; i++) {
      final groupId = _toInt(value[i]);
      if (groupId != null) result[i] = groupId;
    }
    return result;
  }

  final map = _asMap(value);
  final result = <int, int>{};
  for (final entry in map.entries) {
    final key = _toInt(entry.key);
    final val = _toInt(entry.value);
    if (key != null && val != null) {
      result[key] = val;
    }
  }
  return result;
}

List<HappyHareGateStatus> _parseHappyHareGates(Object? value) {
  if (value is List) {
    return List<HappyHareGateStatus>.generate(value.length, (index) {
      final raw = value[index];
      if (raw is Map) {
        final map = _asMap(raw);
        return HappyHareGateStatus(
          gateIndex: _toInt(_firstValue(
                map['gate_index'],
                map['index'],
                map['gate'],
              )) ??
              index,
          status:
              _toStringValue(_firstValue(map['status'], map['state'])) ??
                  'unknown',
          material: _toStringValue(map['material']) ?? '',
          color:
              _toStringValue(_firstValue(map['color'], map['colour'])) ?? '',
          spoolId: _toInt(_firstValue(
                map['spool_id'],
                map['spoolId'],
                map['spoolman_id'],
              )) ??
              -1,
          speedFactor: _toDouble(_firstValue(
                map['speed_factor'],
                map['speedFactor'],
                map['speed_override'],
              )) ??
              1.0,
        );
      }

      return HappyHareGateStatus(
        gateIndex: index,
        status: _toStringValue(raw) ?? 'unknown',
      );
    }, growable: false);
  }

  final map = _asMap(value);
  if (map.isEmpty) return const [];

  final keys = map.keys.toList()
    ..sort((a, b) => (_toInt(a) ?? 0).compareTo(_toInt(b) ?? 0));

  return keys.map((key) {
    final raw = map[key];
    final gateIndex = _toInt(key) ?? 0;
    if (raw is Map) {
      final gate = _asMap(raw);
      return HappyHareGateStatus(
        gateIndex: _toInt(_firstValue(
              gate['gate_index'],
              gate['index'],
              gate['gate'],
            )) ??
            gateIndex,
        status:
            _toStringValue(_firstValue(gate['status'], gate['state'])) ??
                'unknown',
        material: _toStringValue(gate['material']) ?? '',
        color: _toStringValue(_firstValue(gate['color'], gate['colour'])) ?? '',
        spoolId: _toInt(_firstValue(
              gate['spool_id'],
              gate['spoolId'],
              gate['spoolman_id'],
            )) ??
            -1,
        speedFactor: _toDouble(_firstValue(
              gate['speed_factor'],
              gate['speedFactor'],
              gate['speed_override'],
            )) ??
            1.0,
      );
    }

    return HappyHareGateStatus(
      gateIndex: gateIndex,
      status: _toStringValue(raw) ?? 'unknown',
    );
  }).toList(growable: false);
}

String _capitalizeWord(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
