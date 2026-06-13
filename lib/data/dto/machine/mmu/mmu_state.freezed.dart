// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'mmu_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your copy of a freezed class using the '
    'constructor syntax. Please use the factory constructor instead.');

// ── MmuState ──────────────────────────────────────────────────────────────────

mixin _$MmuState {
  int get activeTool => throw _privateConstructorUsedError;
  int get toolCount => throw _privateConstructorUsedError;
  bool get busy => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String get printState => throw _privateConstructorUsedError;
  List<String> get filamentColors => throw _privateConstructorUsedError;
  List<MmuGateState> get gateStates => throw _privateConstructorUsedError;
  String get objectKey => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MmuStateCopyWith<MmuState> get copyWith => throw _privateConstructorUsedError;
}

abstract class $MmuStateCopyWith<$Res> {
  factory $MmuStateCopyWith(MmuState value, $Res Function(MmuState) then) =
      _$MmuStateCopyWithImpl<$Res, MmuState>;
  @useResult
  $Res call({
    int activeTool,
    int toolCount,
    bool busy,
    String? error,
    String printState,
    List<String> filamentColors,
    List<MmuGateState> gateStates,
    String objectKey,
  });
}

class _$MmuStateCopyWithImpl<$Res, $Val extends MmuState>
    implements $MmuStateCopyWith<$Res> {
  _$MmuStateCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeTool = null,
    Object? toolCount = null,
    Object? busy = null,
    Object? error = freezed,
    Object? printState = null,
    Object? filamentColors = null,
    Object? gateStates = null,
    Object? objectKey = null,
  }) {
    return _then(_value.copyWith(
      activeTool: null == activeTool ? _value.activeTool : activeTool as int,
      toolCount: null == toolCount ? _value.toolCount : toolCount as int,
      busy: null == busy ? _value.busy : busy as bool,
      error: freezed == error ? _value.error : error as String?,
      printState: null == printState ? _value.printState : printState as String,
      filamentColors: null == filamentColors ? _value.filamentColors : filamentColors as List<String>,
      gateStates: null == gateStates ? _value.gateStates : gateStates as List<MmuGateState>,
      objectKey: null == objectKey ? _value.objectKey : objectKey as String,
    ) as $Val);
  }
}

class _$MmuStateImpl extends _MmuState {
  const _$MmuStateImpl({
    this.activeTool = -1,
    this.toolCount = 0,
    this.busy = false,
    this.error,
    this.printState = 'unknown',
    this.filamentColors = const [],
    this.gateStates = const [],
    this.objectKey = 'mmu',
  }) : super._();

  @override final int activeTool;
  @override final int toolCount;
  @override final bool busy;
  @override final String? error;
  @override final String printState;
  @override final List<String> filamentColors;
  @override final List<MmuGateState> gateStates;
  @override final String objectKey;

  @override
  String toString() => 'MmuState(activeTool: $activeTool, toolCount: $toolCount, busy: $busy, state: $printState)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$MmuStateImpl &&
          other.activeTool == activeTool &&
          other.toolCount == toolCount &&
          other.busy == busy &&
          other.printState == printState);

  @override
  int get hashCode => Object.hash(runtimeType, activeTool, toolCount, busy, printState);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MmuStateImplCopyWith<_$MmuStateImpl> get copyWith =>
      __$$MmuStateImplCopyWithImpl<_$MmuStateImpl>(this, _$identity);
}

abstract class _$$MmuStateImplCopyWith<$Res> implements $MmuStateCopyWith<$Res> {
  factory _$$MmuStateImplCopyWith(_$MmuStateImpl value, $Res Function(_$MmuStateImpl) then) =
      __$$MmuStateImplCopyWithImpl<$Res>;
}

class __$$MmuStateImplCopyWithImpl<$Res>
    extends _$MmuStateCopyWithImpl<$Res, _$MmuStateImpl>
    implements _$$MmuStateImplCopyWith<$Res> {
  __$$MmuStateImplCopyWithImpl(_$MmuStateImpl _value, $Res Function(_$MmuStateImpl) _then)
      : super(_value, _then);
}

abstract class _MmuState extends MmuState {
  const factory _MmuState({
    int activeTool,
    int toolCount,
    bool busy,
    String? error,
    String printState,
    List<String> filamentColors,
    List<MmuGateState> gateStates,
    String objectKey,
  }) = _$MmuStateImpl;
  const _MmuState._() : super._();
  @override int get activeTool;
  @override int get toolCount;
  @override bool get busy;
  @override String? get error;
  @override String get printState;
  @override List<String> get filamentColors;
  @override List<MmuGateState> get gateStates;
  @override String get objectKey;
  @override @JsonKey(ignore: true) _$$MmuStateImplCopyWith<_$MmuStateImpl> get copyWith => throw _privateConstructorUsedError;
}

// ── MmuTool ───────────────────────────────────────────────────────────────────

mixin _$MmuTool {
  int get index => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  MmuGateState get gateState => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MmuToolCopyWith<MmuTool> get copyWith => throw _privateConstructorUsedError;
}

abstract class $MmuToolCopyWith<$Res> {
  factory $MmuToolCopyWith(MmuTool value, $Res Function(MmuTool) then) = _$MmuToolCopyWithImpl<$Res, MmuTool>;
  @useResult
  $Res call({int index, bool isActive, String? color, MmuGateState gateState});
}

class _$MmuToolCopyWithImpl<$Res, $Val extends MmuTool> implements $MmuToolCopyWith<$Res> {
  _$MmuToolCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? index = null, Object? isActive = null, Object? color = freezed, Object? gateState = null}) {
    return _then(_value.copyWith(
      index: null == index ? _value.index : index as int,
      isActive: null == isActive ? _value.isActive : isActive as bool,
      color: freezed == color ? _value.color : color as String?,
      gateState: null == gateState ? _value.gateState : gateState as MmuGateState,
    ) as $Val);
  }
}

class _$MmuToolImpl extends _MmuTool {
  const _$MmuToolImpl({required this.index, this.isActive = false, this.color, this.gateState = MmuGateState.unknown}) : super._();
  @override final int index;
  @override final bool isActive;
  @override final String? color;
  @override final MmuGateState gateState;
  @override bool operator ==(Object other) => identical(this, other) || (other.runtimeType == runtimeType && other is _$MmuToolImpl && other.index == index && other.isActive == isActive);
  @override int get hashCode => Object.hash(runtimeType, index, isActive);
  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MmuToolImplCopyWith<_$MmuToolImpl> get copyWith => __$$MmuToolImplCopyWithImpl<_$MmuToolImpl>(this, _$identity);
}

abstract class _$$MmuToolImplCopyWith<$Res> implements $MmuToolCopyWith<$Res> {
  factory _$$MmuToolImplCopyWith(_$MmuToolImpl value, $Res Function(_$MmuToolImpl) then) = __$$MmuToolImplCopyWithImpl<$Res>;
}
class __$$MmuToolImplCopyWithImpl<$Res> extends _$MmuToolCopyWithImpl<$Res, _$MmuToolImpl> implements _$$MmuToolImplCopyWith<$Res> {
  __$$MmuToolImplCopyWithImpl(_$MmuToolImpl _value, $Res Function(_$MmuToolImpl) _then) : super(_value, _then);
}
abstract class _MmuTool extends MmuTool {
  const factory _MmuTool({required int index, bool isActive, String? color, MmuGateState gateState}) = _$MmuToolImpl;
  const _MmuTool._() : super._();
  @override int get index;
  @override bool get isActive;
  @override String? get color;
  @override MmuGateState get gateState;
  @override @JsonKey(ignore: true) _$$MmuToolImplCopyWith<_$MmuToolImpl> get copyWith => throw _privateConstructorUsedError;
}
