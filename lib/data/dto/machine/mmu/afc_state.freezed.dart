// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'afc_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your copy of a freezed class using the '
    'constructor syntax. Please use the factory constructor instead.');

// ── AfcState ─────────────────────────────────────────────────────────────────

mixin _$AfcState {
  String get status => throw _privateConstructorUsedError;
  Map<String, AfcLaneStatus> get lanes => throw _privateConstructorUsedError;
  AfcHubStatus? get hub => throw _privateConstructorUsedError;
  String? get activeLane => throw _privateConstructorUsedError;
  AfcBufferStatus? get buffer => throw _privateConstructorUsedError;
  String get lastError => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AfcStateCopyWith<AfcState> get copyWith => throw _privateConstructorUsedError;
}

abstract class $AfcStateCopyWith<$Res> {
  factory $AfcStateCopyWith(AfcState value, $Res Function(AfcState) then) =
      _$AfcStateCopyWithImpl<$Res, AfcState>;
  @useResult
  $Res call({
    String status,
    Map<String, AfcLaneStatus> lanes,
    AfcHubStatus? hub,
    String? activeLane,
    AfcBufferStatus? buffer,
    String lastError,
  });
}

class _$AfcStateCopyWithImpl<$Res, $Val extends AfcState>
    implements $AfcStateCopyWith<$Res> {
  _$AfcStateCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lanes = null,
    Object? hub = freezed,
    Object? activeLane = freezed,
    Object? buffer = freezed,
    Object? lastError = null,
  }) {
    return _then(_value.copyWith(
      status: null == status ? _value.status : status as String,
      lanes: null == lanes ? _value.lanes : lanes as Map<String, AfcLaneStatus>,
      hub: freezed == hub ? _value.hub : hub as AfcHubStatus?,
      activeLane: freezed == activeLane ? _value.activeLane : activeLane as String?,
      buffer: freezed == buffer ? _value.buffer : buffer as AfcBufferStatus?,
      lastError: null == lastError ? _value.lastError : lastError as String,
    ) as $Val);
  }
}

class _$AfcStateImpl extends _AfcState {
  const _$AfcStateImpl({
    this.status = 'unknown',
    this.lanes = const {},
    this.hub,
    this.activeLane,
    this.buffer,
    this.lastError = '',
  }) : super._();

  @override
  final String status;
  @override
  final Map<String, AfcLaneStatus> lanes;
  @override
  final AfcHubStatus? hub;
  @override
  final String? activeLane;
  @override
  final AfcBufferStatus? buffer;
  @override
  final String lastError;

  @override
  String toString() =>
      'AfcState(status: $status, lanes: ${lanes.length}, activeLane: $activeLane)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$AfcStateImpl &&
          other.status == status &&
          other.activeLane == activeLane &&
          other.lastError == lastError);

  @override
  int get hashCode => Object.hash(runtimeType, status, activeLane, lastError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AfcStateImplCopyWith<_$AfcStateImpl> get copyWith =>
      __$$AfcStateImplCopyWithImpl<_$AfcStateImpl>(this, _$identity);
}

abstract class _$$AfcStateImplCopyWith<$Res>
    implements $AfcStateCopyWith<$Res> {
  factory _$$AfcStateImplCopyWith(
          _$AfcStateImpl value, $Res Function(_$AfcStateImpl) then) =
      __$$AfcStateImplCopyWithImpl<$Res>;
}

class __$$AfcStateImplCopyWithImpl<$Res>
    extends _$AfcStateCopyWithImpl<$Res, _$AfcStateImpl>
    implements _$$AfcStateImplCopyWith<$Res> {
  __$$AfcStateImplCopyWithImpl(
      _$AfcStateImpl _value, $Res Function(_$AfcStateImpl) _then)
      : super(_value, _then);
}

abstract class _AfcState extends AfcState {
  const factory _AfcState({
    String status,
    Map<String, AfcLaneStatus> lanes,
    AfcHubStatus? hub,
    String? activeLane,
    AfcBufferStatus? buffer,
    String lastError,
  }) = _$AfcStateImpl;
  const _AfcState._() : super._();
  @override
  String get status;
  @override
  Map<String, AfcLaneStatus> get lanes;
  @override
  AfcHubStatus? get hub;
  @override
  String? get activeLane;
  @override
  AfcBufferStatus? get buffer;
  @override
  String get lastError;
  @override
  @JsonKey(ignore: true)
  _$$AfcStateImplCopyWith<_$AfcStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// ── AfcLaneStatus ────────────────────────────────────────────────────────────

mixin _$AfcLaneStatus {
  String get laneName => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  bool get filamentPresent => throw _privateConstructorUsedError;
  bool get extruderPresent => throw _privateConstructorUsedError;
  String get material => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  int get spoolId => throw _privateConstructorUsedError;
  double get remainingMm => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AfcLaneStatusCopyWith<AfcLaneStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $AfcLaneStatusCopyWith<$Res> {
  factory $AfcLaneStatusCopyWith(
          AfcLaneStatus value, $Res Function(AfcLaneStatus) then) =
      _$AfcLaneStatusCopyWithImpl<$Res, AfcLaneStatus>;
  @useResult
  $Res call({
    String laneName,
    String state,
    bool filamentPresent,
    bool extruderPresent,
    String material,
    String color,
    int spoolId,
    double remainingMm,
  });
}

class _$AfcLaneStatusCopyWithImpl<$Res, $Val extends AfcLaneStatus>
    implements $AfcLaneStatusCopyWith<$Res> {
  _$AfcLaneStatusCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? laneName = null,
    Object? state = null,
    Object? filamentPresent = null,
    Object? extruderPresent = null,
    Object? material = null,
    Object? color = null,
    Object? spoolId = null,
    Object? remainingMm = null,
  }) {
    return _then(_value.copyWith(
      laneName: null == laneName ? _value.laneName : laneName as String,
      state: null == state ? _value.state : state as String,
      filamentPresent: null == filamentPresent
          ? _value.filamentPresent
          : filamentPresent as bool,
      extruderPresent: null == extruderPresent
          ? _value.extruderPresent
          : extruderPresent as bool,
      material: null == material ? _value.material : material as String,
      color: null == color ? _value.color : color as String,
      spoolId: null == spoolId ? _value.spoolId : spoolId as int,
      remainingMm:
          null == remainingMm ? _value.remainingMm : remainingMm as double,
    ) as $Val);
  }
}

class _$AfcLaneStatusImpl extends _AfcLaneStatus {
  const _$AfcLaneStatusImpl({
    required this.laneName,
    this.state = 'unknown',
    this.filamentPresent = false,
    this.extruderPresent = false,
    this.material = '',
    this.color = '',
    this.spoolId = -1,
    this.remainingMm = -1,
  }) : super._();

  @override
  final String laneName;
  @override
  final String state;
  @override
  final bool filamentPresent;
  @override
  final bool extruderPresent;
  @override
  final String material;
  @override
  final String color;
  @override
  final int spoolId;
  @override
  final double remainingMm;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$AfcLaneStatusImpl &&
          other.laneName == laneName &&
          other.state == state &&
          other.filamentPresent == filamentPresent);

  @override
  int get hashCode => Object.hash(runtimeType, laneName, state, filamentPresent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AfcLaneStatusImplCopyWith<_$AfcLaneStatusImpl> get copyWith =>
      __$$AfcLaneStatusImplCopyWithImpl<_$AfcLaneStatusImpl>(
        this,
        _$identity,
      );
}

abstract class _$$AfcLaneStatusImplCopyWith<$Res>
    implements $AfcLaneStatusCopyWith<$Res> {
  factory _$$AfcLaneStatusImplCopyWith(_$AfcLaneStatusImpl value,
          $Res Function(_$AfcLaneStatusImpl) then) =
      __$$AfcLaneStatusImplCopyWithImpl<$Res>;
}

class __$$AfcLaneStatusImplCopyWithImpl<$Res>
    extends _$AfcLaneStatusCopyWithImpl<$Res, _$AfcLaneStatusImpl>
    implements _$$AfcLaneStatusImplCopyWith<$Res> {
  __$$AfcLaneStatusImplCopyWithImpl(
      _$AfcLaneStatusImpl _value, $Res Function(_$AfcLaneStatusImpl) _then)
      : super(_value, _then);
}

abstract class _AfcLaneStatus extends AfcLaneStatus {
  const factory _AfcLaneStatus({
    required String laneName,
    String state,
    bool filamentPresent,
    bool extruderPresent,
    String material,
    String color,
    int spoolId,
    double remainingMm,
  }) = _$AfcLaneStatusImpl;
  const _AfcLaneStatus._() : super._();
  @override
  String get laneName;
  @override
  String get state;
  @override
  bool get filamentPresent;
  @override
  bool get extruderPresent;
  @override
  String get material;
  @override
  String get color;
  @override
  int get spoolId;
  @override
  double get remainingMm;
  @override
  @JsonKey(ignore: true)
  _$$AfcLaneStatusImplCopyWith<_$AfcLaneStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// ── AfcHubStatus ─────────────────────────────────────────────────────────────

mixin _$AfcHubStatus {
  bool get filamentPresent => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AfcHubStatusCopyWith<AfcHubStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $AfcHubStatusCopyWith<$Res> {
  factory $AfcHubStatusCopyWith(
          AfcHubStatus value, $Res Function(AfcHubStatus) then) =
      _$AfcHubStatusCopyWithImpl<$Res, AfcHubStatus>;
  @useResult
  $Res call({bool filamentPresent, String state});
}

class _$AfcHubStatusCopyWithImpl<$Res, $Val extends AfcHubStatus>
    implements $AfcHubStatusCopyWith<$Res> {
  _$AfcHubStatusCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filamentPresent = null, Object? state = null}) {
    return _then(_value.copyWith(
      filamentPresent: null == filamentPresent
          ? _value.filamentPresent
          : filamentPresent as bool,
      state: null == state ? _value.state : state as String,
    ) as $Val);
  }
}

class _$AfcHubStatusImpl extends _AfcHubStatus {
  const _$AfcHubStatusImpl({
    this.filamentPresent = false,
    this.state = 'unknown',
  }) : super._();

  @override
  final bool filamentPresent;
  @override
  final String state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$AfcHubStatusImpl &&
          other.filamentPresent == filamentPresent &&
          other.state == state);

  @override
  int get hashCode => Object.hash(runtimeType, filamentPresent, state);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AfcHubStatusImplCopyWith<_$AfcHubStatusImpl> get copyWith =>
      __$$AfcHubStatusImplCopyWithImpl<_$AfcHubStatusImpl>(this, _$identity);
}

abstract class _$$AfcHubStatusImplCopyWith<$Res>
    implements $AfcHubStatusCopyWith<$Res> {
  factory _$$AfcHubStatusImplCopyWith(
          _$AfcHubStatusImpl value, $Res Function(_$AfcHubStatusImpl) then) =
      __$$AfcHubStatusImplCopyWithImpl<$Res>;
}

class __$$AfcHubStatusImplCopyWithImpl<$Res>
    extends _$AfcHubStatusCopyWithImpl<$Res, _$AfcHubStatusImpl>
    implements _$$AfcHubStatusImplCopyWith<$Res> {
  __$$AfcHubStatusImplCopyWithImpl(
      _$AfcHubStatusImpl _value, $Res Function(_$AfcHubStatusImpl) _then)
      : super(_value, _then);
}

abstract class _AfcHubStatus extends AfcHubStatus {
  const factory _AfcHubStatus({
    bool filamentPresent,
    String state,
  }) = _$AfcHubStatusImpl;
  const _AfcHubStatus._() : super._();
  @override
  bool get filamentPresent;
  @override
  String get state;
  @override
  @JsonKey(ignore: true)
  _$$AfcHubStatusImplCopyWith<_$AfcHubStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// ── AfcBufferStatus ──────────────────────────────────────────────────────────

mixin _$AfcBufferStatus {
  String get state => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AfcBufferStatusCopyWith<AfcBufferStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $AfcBufferStatusCopyWith<$Res> {
  factory $AfcBufferStatusCopyWith(
          AfcBufferStatus value, $Res Function(AfcBufferStatus) then) =
      _$AfcBufferStatusCopyWithImpl<$Res, AfcBufferStatus>;
  @useResult
  $Res call({String state});
}

class _$AfcBufferStatusCopyWithImpl<$Res, $Val extends AfcBufferStatus>
    implements $AfcBufferStatusCopyWith<$Res> {
  _$AfcBufferStatusCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? state = null}) {
    return _then(_value.copyWith(
      state: null == state ? _value.state : state as String,
    ) as $Val);
  }
}

class _$AfcBufferStatusImpl extends _AfcBufferStatus {
  const _$AfcBufferStatusImpl({this.state = 'unknown'}) : super._();

  @override
  final String state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$AfcBufferStatusImpl &&
          other.state == state);

  @override
  int get hashCode => Object.hash(runtimeType, state);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AfcBufferStatusImplCopyWith<_$AfcBufferStatusImpl> get copyWith =>
      __$$AfcBufferStatusImplCopyWithImpl<_$AfcBufferStatusImpl>(
        this,
        _$identity,
      );
}

abstract class _$$AfcBufferStatusImplCopyWith<$Res>
    implements $AfcBufferStatusCopyWith<$Res> {
  factory _$$AfcBufferStatusImplCopyWith(_$AfcBufferStatusImpl value,
          $Res Function(_$AfcBufferStatusImpl) then) =
      __$$AfcBufferStatusImplCopyWithImpl<$Res>;
}

class __$$AfcBufferStatusImplCopyWithImpl<$Res>
    extends _$AfcBufferStatusCopyWithImpl<$Res, _$AfcBufferStatusImpl>
    implements _$$AfcBufferStatusImplCopyWith<$Res> {
  __$$AfcBufferStatusImplCopyWithImpl(
      _$AfcBufferStatusImpl _value, $Res Function(_$AfcBufferStatusImpl) _then)
      : super(_value, _then);
}

abstract class _AfcBufferStatus extends AfcBufferStatus {
  const factory _AfcBufferStatus({String state}) = _$AfcBufferStatusImpl;
  const _AfcBufferStatus._() : super._();
  @override
  String get state;
  @override
  @JsonKey(ignore: true)
  _$$AfcBufferStatusImplCopyWith<_$AfcBufferStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
