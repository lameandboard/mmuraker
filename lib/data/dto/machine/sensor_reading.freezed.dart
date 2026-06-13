// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'sensor_reading.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your copy of a freezed class using the '
    'constructor syntax. Please use the factory constructor instead.');

mixin _$SensorReading {
  String get objectKey => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  SensorType get type => throw _privateConstructorUsedError;
  double? get temperature => throw _privateConstructorUsedError;
  double? get target => throw _privateConstructorUsedError;
  double? get power => throw _privateConstructorUsedError;
  bool? get canExtrude => throw _privateConstructorUsedError;
  bool? get filamentDetected => throw _privateConstructorUsedError;
  bool? get motionDetected => throw _privateConstructorUsedError;
  double? get fanSpeed => throw _privateConstructorUsedError;
  double? get lastZ => throw _privateConstructorUsedError;
  Map<String, dynamic> get rawValues => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SensorReadingCopyWith<SensorReading> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $SensorReadingCopyWith<$Res> {
  factory $SensorReadingCopyWith(
          SensorReading value, $Res Function(SensorReading) then) =
      _$SensorReadingCopyWithImpl<$Res, SensorReading>;
  @useResult
  $Res call({
    String objectKey,
    String displayName,
    SensorType type,
    double? temperature,
    double? target,
    double? power,
    bool? canExtrude,
    bool? filamentDetected,
    bool? motionDetected,
    double? fanSpeed,
    double? lastZ,
    Map<String, dynamic> rawValues,
  });
}

class _$SensorReadingCopyWithImpl<$Res, $Val extends SensorReading>
    implements $SensorReadingCopyWith<$Res> {
  _$SensorReadingCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? objectKey = null,
    Object? displayName = null,
    Object? type = null,
    Object? temperature = freezed,
    Object? target = freezed,
    Object? power = freezed,
    Object? canExtrude = freezed,
    Object? filamentDetected = freezed,
    Object? motionDetected = freezed,
    Object? fanSpeed = freezed,
    Object? lastZ = freezed,
    Object? rawValues = null,
  }) {
    return _then(_value.copyWith(
      objectKey: null == objectKey ? _value.objectKey : objectKey as String,
      displayName: null == displayName ? _value.displayName : displayName as String,
      type: null == type ? _value.type : type as SensorType,
      temperature: freezed == temperature ? _value.temperature : temperature as double?,
      target: freezed == target ? _value.target : target as double?,
      power: freezed == power ? _value.power : power as double?,
      canExtrude: freezed == canExtrude ? _value.canExtrude : canExtrude as bool?,
      filamentDetected: freezed == filamentDetected ? _value.filamentDetected : filamentDetected as bool?,
      motionDetected: freezed == motionDetected ? _value.motionDetected : motionDetected as bool?,
      fanSpeed: freezed == fanSpeed ? _value.fanSpeed : fanSpeed as double?,
      lastZ: freezed == lastZ ? _value.lastZ : lastZ as double?,
      rawValues: null == rawValues ? _value.rawValues : rawValues as Map<String, dynamic>,
    ) as $Val);
  }
}

class _$SensorReadingImpl extends _SensorReading {
  const _$SensorReadingImpl({
    required this.objectKey,
    required this.displayName,
    required this.type,
    this.temperature,
    this.target,
    this.power,
    this.canExtrude,
    this.filamentDetected,
    this.motionDetected,
    this.fanSpeed,
    this.lastZ,
    this.rawValues = const {},
  }) : super._();

  @override final String objectKey;
  @override final String displayName;
  @override final SensorType type;
  @override final double? temperature;
  @override final double? target;
  @override final double? power;
  @override final bool? canExtrude;
  @override final bool? filamentDetected;
  @override final bool? motionDetected;
  @override final double? fanSpeed;
  @override final double? lastZ;
  @override final Map<String, dynamic> rawValues;

  @override
  String toString() => 'SensorReading($objectKey, $type, $statusSummary)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$SensorReadingImpl &&
          other.objectKey == objectKey &&
          other.temperature == temperature &&
          other.target == target &&
          other.fanSpeed == fanSpeed &&
          other.filamentDetected == filamentDetected);

  @override
  int get hashCode =>
      Object.hash(runtimeType, objectKey, temperature, target, fanSpeed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SensorReadingImplCopyWith<_$SensorReadingImpl> get copyWith =>
      __$$SensorReadingImplCopyWithImpl<_$SensorReadingImpl>(this, _$identity);
}

abstract class _$$SensorReadingImplCopyWith<$Res>
    implements $SensorReadingCopyWith<$Res> {
  factory _$$SensorReadingImplCopyWith(
          _$SensorReadingImpl value, $Res Function(_$SensorReadingImpl) then) =
      __$$SensorReadingImplCopyWithImpl<$Res>;
}

class __$$SensorReadingImplCopyWithImpl<$Res>
    extends _$SensorReadingCopyWithImpl<$Res, _$SensorReadingImpl>
    implements _$$SensorReadingImplCopyWith<$Res> {
  __$$SensorReadingImplCopyWithImpl(
      _$SensorReadingImpl _value, $Res Function(_$SensorReadingImpl) _then)
      : super(_value, _then);
}

abstract class _SensorReading extends SensorReading {
  const factory _SensorReading({
    required String objectKey,
    required String displayName,
    required SensorType type,
    double? temperature,
    double? target,
    double? power,
    bool? canExtrude,
    bool? filamentDetected,
    bool? motionDetected,
    double? fanSpeed,
    double? lastZ,
    Map<String, dynamic> rawValues,
  }) = _$SensorReadingImpl;
  const _SensorReading._() : super._();
  @override String get objectKey;
  @override String get displayName;
  @override SensorType get type;
  @override double? get temperature;
  @override double? get target;
  @override double? get power;
  @override bool? get canExtrude;
  @override bool? get filamentDetected;
  @override bool? get motionDetected;
  @override double? get fanSpeed;
  @override double? get lastZ;
  @override Map<String, dynamic> get rawValues;
  @override @JsonKey(ignore: true)
  _$$SensorReadingImplCopyWith<_$SensorReadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
