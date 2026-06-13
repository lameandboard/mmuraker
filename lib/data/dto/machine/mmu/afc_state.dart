// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'afc_state.freezed.dart';

/// AFC (Automatic Filament Changer) state aggregated from Moonraker AFC objects.
@freezed
class AfcState with _$AfcState {
  const factory AfcState({
    /// Overall AFC status.
    @Default('unknown') String status,

    /// All lanes indexed by lane name.
    @Default({}) Map<String, AfcLaneStatus> lanes,

    /// Optional hub status.
    AfcHubStatus? hub,

    /// Active lane name.
    String? activeLane,

    /// Optional buffer status.
    AfcBufferStatus? buffer,

    /// Last AFC error string.
    @Default('') String lastError,
  }) = _AfcState;

  const AfcState._();

  bool get hasError => lastError.isNotEmpty;

  int get loadedLaneCount =>
      lanes.values.where((lane) => lane.filamentPresent).length;

  static AfcState fromMoonrakerJson(Map<String, dynamic> json) {
    final root = _extractMoonrakerObject(json, 'AFC');

    final lanes = <String, AfcLaneStatus>{};
    Map<String, dynamic> extruderMap = const <String, dynamic>{};
    for (final entry in json.entries) {
      if (entry.key.startsWith('AFC_lane ')) {
        final laneName = entry.key.substring('AFC_lane '.length).trim();
        lanes[laneName] = _parseAfcLane(laneName, entry.value);
      } else if (entry.key.startsWith('AFC_extruder ') && extruderMap.isEmpty) {
        extruderMap = _asMap(entry.value);
      }
    }

    final nestedLanes = _asMap(root['lanes']);
    for (final entry in nestedLanes.entries) {
      lanes.putIfAbsent(entry.key, () => _parseAfcLane(entry.key, entry.value));
    }

    final hubMap = _firstMap(root['hub'], json['AFC_hub'], extruderMap);
    final bufferValue = _firstValue(root['buffer'], json['AFC_buffer']);

    return AfcState(
      status: _toStringValue(_firstValue(root['status'], root['state'])) ??
          'unknown',
      lanes: lanes,
      hub: hubMap.isEmpty ? null : _parseAfcHub(hubMap),
      activeLane: _toStringValue(
        _firstValue(root['active_lane'], root['current_lane'], root['lane']),
      ),
      buffer: bufferValue == null ? null : _parseAfcBuffer(bufferValue),
      lastError:
          _toStringValue(_firstValue(root['last_error'], root['error'])) ?? '',
    );
  }
}

@freezed
class AfcLaneStatus with _$AfcLaneStatus {
  const factory AfcLaneStatus({
    required String laneName,
    @Default('unknown') String state,
    @Default(false) bool filamentPresent,
    @Default(false) bool extruderPresent,
    @Default('') String material,
    @Default('') String color,
    @Default(-1) int spoolId,
    @Default(-1) double remainingMm,
  }) = _AfcLaneStatus;

  const AfcLaneStatus._();
}

@freezed
class AfcHubStatus with _$AfcHubStatus {
  const factory AfcHubStatus({
    @Default(false) bool filamentPresent,
    @Default('unknown') String state,
  }) = _AfcHubStatus;

  const AfcHubStatus._();
}

@freezed
class AfcBufferStatus with _$AfcBufferStatus {
  const factory AfcBufferStatus({
    @Default('unknown') String state,
  }) = _AfcBufferStatus;

  const AfcBufferStatus._();
}

AfcLaneStatus _parseAfcLane(String laneName, Object? rawValue) {
  final map = _asMap(rawValue);
  if (map.isEmpty) {
    return AfcLaneStatus(laneName: laneName);
  }

  return AfcLaneStatus(
    laneName: _toStringValue(_firstValue(map['lane_name'], map['name'])) ?? laneName,
    state: _toStringValue(_firstValue(map['state'], map['status'])) ?? 'unknown',
    filamentPresent: _toBool(_firstValue(
          map['filament_present'],
          map['loaded'],
          map['has_filament'],
        )) ??
        false,
    extruderPresent: _toBool(_firstValue(
          map['extruder_present'],
          map['tool_loaded'],
          map['at_extruder'],
        )) ??
        false,
    material: _toStringValue(map['material']) ?? '',
    color: _toStringValue(_firstValue(map['color'], map['colour'])) ?? '',
    spoolId: _toInt(_firstValue(map['spool_id'], map['spoolId'])) ?? -1,
    remainingMm: _toDouble(_firstValue(
          map['remaining_mm'],
          map['remaining'],
        )) ??
        -1,
  );
}

AfcHubStatus _parseAfcHub(Object? rawValue) {
  final map = _asMap(rawValue);
  return AfcHubStatus(
    filamentPresent: _toBool(_firstValue(
          map['filament_present'],
          map['loaded'],
          map['has_filament'],
        )) ??
        false,
    state: _toStringValue(_firstValue(map['state'], map['status'])) ?? 'unknown',
  );
}

AfcBufferStatus _parseAfcBuffer(Object? rawValue) {
  if (rawValue is String) return AfcBufferStatus(state: rawValue);
  final map = _asMap(rawValue);
  return AfcBufferStatus(
    state: _toStringValue(_firstValue(map['state'], map['status'])) ?? 'unknown',
  );
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
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
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
