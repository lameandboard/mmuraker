// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'happy_hare_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your copy of a freezed class using the '
    'constructor syntax. Please use the factory constructor instead.');

// ── HappyHareState ───────────────────────────────────────────────────────────

mixin _$HappyHareState {
  String get state => throw _privateConstructorUsedError;
  int get toolSelected => throw _privateConstructorUsedError;
  int get numGates => throw _privateConstructorUsedError;
  List<HappyHareGateStatus> get gates => throw _privateConstructorUsedError;
  bool get isPaused => throw _privateConstructorUsedError;
  bool get isBypass => throw _privateConstructorUsedError;
  String get lastError => throw _privateConstructorUsedError;
  bool get endlessSpoolEnabled => throw _privateConstructorUsedError;
  Map<int, int> get endlessSpoolGroups => throw _privateConstructorUsedError;
  String get servoState => throw _privateConstructorUsedError;
  String get filamentPosition => throw _privateConstructorUsedError;
  double get filamentRemaining => throw _privateConstructorUsedError;
  bool get isPrinting => throw _privateConstructorUsedError;
  List<double> get gateOffsets => throw _privateConstructorUsedError;
  HappyHarePrintStats? get printStats => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HappyHareStateCopyWith<HappyHareState> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $HappyHareStateCopyWith<$Res> {
  factory $HappyHareStateCopyWith(
          HappyHareState value, $Res Function(HappyHareState) then) =
      _$HappyHareStateCopyWithImpl<$Res, HappyHareState>;
  @useResult
  $Res call({
    String state,
    int toolSelected,
    int numGates,
    List<HappyHareGateStatus> gates,
    bool isPaused,
    bool isBypass,
    String lastError,
    bool endlessSpoolEnabled,
    Map<int, int> endlessSpoolGroups,
    String servoState,
    String filamentPosition,
    double filamentRemaining,
    bool isPrinting,
    List<double> gateOffsets,
    HappyHarePrintStats? printStats,
  });
}

class _$HappyHareStateCopyWithImpl<$Res, $Val extends HappyHareState>
    implements $HappyHareStateCopyWith<$Res> {
  _$HappyHareStateCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? toolSelected = null,
    Object? numGates = null,
    Object? gates = null,
    Object? isPaused = null,
    Object? isBypass = null,
    Object? lastError = null,
    Object? endlessSpoolEnabled = null,
    Object? endlessSpoolGroups = null,
    Object? servoState = null,
    Object? filamentPosition = null,
    Object? filamentRemaining = null,
    Object? isPrinting = null,
    Object? gateOffsets = null,
    Object? printStats = freezed,
  }) {
    return _then(_value.copyWith(
      state: null == state ? _value.state : state as String,
      toolSelected:
          null == toolSelected ? _value.toolSelected : toolSelected as int,
      numGates: null == numGates ? _value.numGates : numGates as int,
      gates: null == gates ? _value.gates : gates as List<HappyHareGateStatus>,
      isPaused: null == isPaused ? _value.isPaused : isPaused as bool,
      isBypass: null == isBypass ? _value.isBypass : isBypass as bool,
      lastError: null == lastError ? _value.lastError : lastError as String,
      endlessSpoolEnabled: null == endlessSpoolEnabled
          ? _value.endlessSpoolEnabled
          : endlessSpoolEnabled as bool,
      endlessSpoolGroups: null == endlessSpoolGroups
          ? _value.endlessSpoolGroups
          : endlessSpoolGroups as Map<int, int>,
      servoState: null == servoState ? _value.servoState : servoState as String,
      filamentPosition: null == filamentPosition
          ? _value.filamentPosition
          : filamentPosition as String,
      filamentRemaining: null == filamentRemaining
          ? _value.filamentRemaining
          : filamentRemaining as double,
      isPrinting: null == isPrinting ? _value.isPrinting : isPrinting as bool,
      gateOffsets:
          null == gateOffsets ? _value.gateOffsets : gateOffsets as List<double>,
      printStats: freezed == printStats
          ? _value.printStats
          : printStats as HappyHarePrintStats?,
    ) as $Val);
  }
}

class _$HappyHareStateImpl extends _HappyHareState {
  const _$HappyHareStateImpl({
    this.state = 'idle',
    this.toolSelected = -1,
    this.numGates = 0,
    this.gates = const [],
    this.isPaused = false,
    this.isBypass = false,
    this.lastError = '',
    this.endlessSpoolEnabled = false,
    this.endlessSpoolGroups = const {},
    this.servoState = 'unknown',
    this.filamentPosition = 'unknown',
    this.filamentRemaining = -1,
    this.isPrinting = false,
    this.gateOffsets = const [],
    this.printStats,
  }) : super._();

  @override
  final String state;
  @override
  final int toolSelected;
  @override
  final int numGates;
  @override
  final List<HappyHareGateStatus> gates;
  @override
  final bool isPaused;
  @override
  final bool isBypass;
  @override
  final String lastError;
  @override
  final bool endlessSpoolEnabled;
  @override
  final Map<int, int> endlessSpoolGroups;
  @override
  final String servoState;
  @override
  final String filamentPosition;
  @override
  final double filamentRemaining;
  @override
  final bool isPrinting;
  @override
  final List<double> gateOffsets;
  @override
  final HappyHarePrintStats? printStats;

  @override
  String toString() =>
      'HappyHareState(state: $state, toolSelected: $toolSelected, numGates: $numGates)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$HappyHareStateImpl &&
          other.state == state &&
          other.toolSelected == toolSelected &&
          other.numGates == numGates &&
          other.lastError == lastError);

  @override
  int get hashCode =>
      Object.hash(runtimeType, state, toolSelected, numGates, lastError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HappyHareStateImplCopyWith<_$HappyHareStateImpl> get copyWith =>
      __$$HappyHareStateImplCopyWithImpl<_$HappyHareStateImpl>(
        this,
        _$identity,
      );
}

abstract class _$$HappyHareStateImplCopyWith<$Res>
    implements $HappyHareStateCopyWith<$Res> {
  factory _$$HappyHareStateImplCopyWith(_$HappyHareStateImpl value,
          $Res Function(_$HappyHareStateImpl) then) =
      __$$HappyHareStateImplCopyWithImpl<$Res>;
}

class __$$HappyHareStateImplCopyWithImpl<$Res>
    extends _$HappyHareStateCopyWithImpl<$Res, _$HappyHareStateImpl>
    implements _$$HappyHareStateImplCopyWith<$Res> {
  __$$HappyHareStateImplCopyWithImpl(
      _$HappyHareStateImpl _value, $Res Function(_$HappyHareStateImpl) _then)
      : super(_value, _then);
}

abstract class _HappyHareState extends HappyHareState {
  const factory _HappyHareState({
    String state,
    int toolSelected,
    int numGates,
    List<HappyHareGateStatus> gates,
    bool isPaused,
    bool isBypass,
    String lastError,
    bool endlessSpoolEnabled,
    Map<int, int> endlessSpoolGroups,
    String servoState,
    String filamentPosition,
    double filamentRemaining,
    bool isPrinting,
    List<double> gateOffsets,
    HappyHarePrintStats? printStats,
  }) = _$HappyHareStateImpl;
  const _HappyHareState._() : super._();
  @override
  String get state;
  @override
  int get toolSelected;
  @override
  int get numGates;
  @override
  List<HappyHareGateStatus> get gates;
  @override
  bool get isPaused;
  @override
  bool get isBypass;
  @override
  String get lastError;
  @override
  bool get endlessSpoolEnabled;
  @override
  Map<int, int> get endlessSpoolGroups;
  @override
  String get servoState;
  @override
  String get filamentPosition;
  @override
  double get filamentRemaining;
  @override
  bool get isPrinting;
  @override
  List<double> get gateOffsets;
  @override
  HappyHarePrintStats? get printStats;
  @override
  @JsonKey(ignore: true)
  _$$HappyHareStateImplCopyWith<_$HappyHareStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// ── HappyHareGateStatus ──────────────────────────────────────────────────────

mixin _$HappyHareGateStatus {
  int get gateIndex => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get material => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  int get spoolId => throw _privateConstructorUsedError;
  double get speedFactor => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HappyHareGateStatusCopyWith<HappyHareGateStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $HappyHareGateStatusCopyWith<$Res> {
  factory $HappyHareGateStatusCopyWith(HappyHareGateStatus value,
          $Res Function(HappyHareGateStatus) then) =
      _$HappyHareGateStatusCopyWithImpl<$Res, HappyHareGateStatus>;
  @useResult
  $Res call({
    int gateIndex,
    String status,
    String material,
    String color,
    int spoolId,
    double speedFactor,
  });
}

class _$HappyHareGateStatusCopyWithImpl<$Res, $Val extends HappyHareGateStatus>
    implements $HappyHareGateStatusCopyWith<$Res> {
  _$HappyHareGateStatusCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gateIndex = null,
    Object? status = null,
    Object? material = null,
    Object? color = null,
    Object? spoolId = null,
    Object? speedFactor = null,
  }) {
    return _then(_value.copyWith(
      gateIndex: null == gateIndex ? _value.gateIndex : gateIndex as int,
      status: null == status ? _value.status : status as String,
      material: null == material ? _value.material : material as String,
      color: null == color ? _value.color : color as String,
      spoolId: null == spoolId ? _value.spoolId : spoolId as int,
      speedFactor: null == speedFactor
          ? _value.speedFactor
          : speedFactor as double,
    ) as $Val);
  }
}

class _$HappyHareGateStatusImpl extends _HappyHareGateStatus {
  const _$HappyHareGateStatusImpl({
    required this.gateIndex,
    this.status = 'unknown',
    this.material = '',
    this.color = '',
    this.spoolId = -1,
    this.speedFactor = 1.0,
  }) : super._();

  @override
  final int gateIndex;
  @override
  final String status;
  @override
  final String material;
  @override
  final String color;
  @override
  final int spoolId;
  @override
  final double speedFactor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$HappyHareGateStatusImpl &&
          other.gateIndex == gateIndex &&
          other.status == status &&
          other.spoolId == spoolId);

  @override
  int get hashCode => Object.hash(runtimeType, gateIndex, status, spoolId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HappyHareGateStatusImplCopyWith<_$HappyHareGateStatusImpl> get copyWith =>
      __$$HappyHareGateStatusImplCopyWithImpl<_$HappyHareGateStatusImpl>(
        this,
        _$identity,
      );
}

abstract class _$$HappyHareGateStatusImplCopyWith<$Res>
    implements $HappyHareGateStatusCopyWith<$Res> {
  factory _$$HappyHareGateStatusImplCopyWith(_$HappyHareGateStatusImpl value,
          $Res Function(_$HappyHareGateStatusImpl) then) =
      __$$HappyHareGateStatusImplCopyWithImpl<$Res>;
}

class __$$HappyHareGateStatusImplCopyWithImpl<$Res>
    extends _$HappyHareGateStatusCopyWithImpl<$Res, _$HappyHareGateStatusImpl>
    implements _$$HappyHareGateStatusImplCopyWith<$Res> {
  __$$HappyHareGateStatusImplCopyWithImpl(_$HappyHareGateStatusImpl _value,
      $Res Function(_$HappyHareGateStatusImpl) _then)
      : super(_value, _then);
}

abstract class _HappyHareGateStatus extends HappyHareGateStatus {
  const factory _HappyHareGateStatus({
    required int gateIndex,
    String status,
    String material,
    String color,
    int spoolId,
    double speedFactor,
  }) = _$HappyHareGateStatusImpl;
  const _HappyHareGateStatus._() : super._();
  @override
  int get gateIndex;
  @override
  String get status;
  @override
  String get material;
  @override
  String get color;
  @override
  int get spoolId;
  @override
  double get speedFactor;
  @override
  @JsonKey(ignore: true)
  _$$HappyHareGateStatusImplCopyWith<_$HappyHareGateStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

// ── HappyHarePrintStats ──────────────────────────────────────────────────────

mixin _$HappyHarePrintStats {
  int get totalTool_changes => throw _privateConstructorUsedError;
  int get toolChanges => throw _privateConstructorUsedError;
  int get loadRetries => throw _privateConstructorUsedError;
  int get failedLoadRetries => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HappyHarePrintStatsCopyWith<HappyHarePrintStats> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $HappyHarePrintStatsCopyWith<$Res> {
  factory $HappyHarePrintStatsCopyWith(HappyHarePrintStats value,
          $Res Function(HappyHarePrintStats) then) =
      _$HappyHarePrintStatsCopyWithImpl<$Res, HappyHarePrintStats>;
  @useResult
  $Res call({
    int totalTool_changes,
    int toolChanges,
    int loadRetries,
    int failedLoadRetries,
  });
}

class _$HappyHarePrintStatsCopyWithImpl<$Res, $Val extends HappyHarePrintStats>
    implements $HappyHarePrintStatsCopyWith<$Res> {
  _$HappyHarePrintStatsCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalTool_changes = null,
    Object? toolChanges = null,
    Object? loadRetries = null,
    Object? failedLoadRetries = null,
  }) {
    return _then(_value.copyWith(
      totalTool_changes: null == totalTool_changes
          ? _value.totalTool_changes
          : totalTool_changes as int,
      toolChanges: null == toolChanges ? _value.toolChanges : toolChanges as int,
      loadRetries: null == loadRetries ? _value.loadRetries : loadRetries as int,
      failedLoadRetries: null == failedLoadRetries
          ? _value.failedLoadRetries
          : failedLoadRetries as int,
    ) as $Val);
  }
}

class _$HappyHarePrintStatsImpl extends _HappyHarePrintStats {
  const _$HappyHarePrintStatsImpl({
    this.totalTool_changes = 0,
    this.toolChanges = 0,
    this.loadRetries = 0,
    this.failedLoadRetries = 0,
  }) : super._();

  @override
  final int totalTool_changes;
  @override
  final int toolChanges;
  @override
  final int loadRetries;
  @override
  final int failedLoadRetries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$HappyHarePrintStatsImpl &&
          other.totalTool_changes == totalTool_changes &&
          other.toolChanges == toolChanges &&
          other.loadRetries == loadRetries &&
          other.failedLoadRetries == failedLoadRetries);

  @override
  int get hashCode => Object.hash(
      runtimeType, totalTool_changes, toolChanges, loadRetries, failedLoadRetries);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HappyHarePrintStatsImplCopyWith<_$HappyHarePrintStatsImpl> get copyWith =>
      __$$HappyHarePrintStatsImplCopyWithImpl<_$HappyHarePrintStatsImpl>(
        this,
        _$identity,
      );
}

abstract class _$$HappyHarePrintStatsImplCopyWith<$Res>
    implements $HappyHarePrintStatsCopyWith<$Res> {
  factory _$$HappyHarePrintStatsImplCopyWith(_$HappyHarePrintStatsImpl value,
          $Res Function(_$HappyHarePrintStatsImpl) then) =
      __$$HappyHarePrintStatsImplCopyWithImpl<$Res>;
}

class __$$HappyHarePrintStatsImplCopyWithImpl<$Res>
    extends _$HappyHarePrintStatsCopyWithImpl<$Res, _$HappyHarePrintStatsImpl>
    implements _$$HappyHarePrintStatsImplCopyWith<$Res> {
  __$$HappyHarePrintStatsImplCopyWithImpl(_$HappyHarePrintStatsImpl _value,
      $Res Function(_$HappyHarePrintStatsImpl) _then)
      : super(_value, _then);
}

abstract class _HappyHarePrintStats extends HappyHarePrintStats {
  const factory _HappyHarePrintStats({
    int totalTool_changes,
    int toolChanges,
    int loadRetries,
    int failedLoadRetries,
  }) = _$HappyHarePrintStatsImpl;
  const _HappyHarePrintStats._() : super._();
  @override
  int get totalTool_changes;
  @override
  int get toolChanges;
  @override
  int get loadRetries;
  @override
  int get failedLoadRetries;
  @override
  @JsonKey(ignore: true)
  _$$HappyHarePrintStatsImplCopyWith<_$HappyHarePrintStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
