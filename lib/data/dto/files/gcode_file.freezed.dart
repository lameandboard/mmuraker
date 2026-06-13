// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'gcode_file.dart';

// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your copy of a freezed class using the '
    'constructor syntax. Please use the factory constructor instead.');

mixin _$GCodeFile {
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  double get printTime => throw _privateConstructorUsedError;
  String? get thumbnailSmall => throw _privateConstructorUsedError;
  String? get thumbnailLarge => throw _privateConstructorUsedError;
  String? get slicerVersion => throw _privateConstructorUsedError;
  String? get layerHeight => throw _privateConstructorUsedError;
  String? get objectHeight => throw _privateConstructorUsedError;
  String? get firstLayerHeight => throw _privateConstructorUsedError;
  String? get firstLayerBedTemp => throw _privateConstructorUsedError;
  String? get firstLayerExtruderTemp => throw _privateConstructorUsedError;
  bool get mmuPrint => throw _privateConstructorUsedError;
  int get filamentChangeCount => throw _privateConstructorUsedError;
  List<int> get referencedTools => throw _privateConstructorUsedError;
  List<String> get filamentColors => throw _privateConstructorUsedError;
  List<String> get extruderColors => throw _privateConstructorUsedError;
  List<double> get filamentUsedMm => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GCodeFileCopyWith<GCodeFile> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $GCodeFileCopyWith<$Res> {
  factory $GCodeFileCopyWith(GCodeFile value, $Res Function(GCodeFile) then) =
      _$GCodeFileCopyWithImpl<$Res, GCodeFile>;
  @useResult
  $Res call({
    String name,
    String path,
    int size,
    double printTime,
    String? thumbnailSmall,
    String? thumbnailLarge,
    String? slicerVersion,
    String? layerHeight,
    String? objectHeight,
    String? firstLayerHeight,
    String? firstLayerBedTemp,
    String? firstLayerExtruderTemp,
    bool mmuPrint,
    int filamentChangeCount,
    List<int> referencedTools,
    List<String> filamentColors,
    List<String> extruderColors,
    List<double> filamentUsedMm,
  });
}

class _$GCodeFileCopyWithImpl<$Res, $Val extends GCodeFile>
    implements $GCodeFileCopyWith<$Res> {
  _$GCodeFileCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? size = null,
    Object? printTime = null,
    Object? thumbnailSmall = freezed,
    Object? thumbnailLarge = freezed,
    Object? slicerVersion = freezed,
    Object? layerHeight = freezed,
    Object? objectHeight = freezed,
    Object? firstLayerHeight = freezed,
    Object? firstLayerBedTemp = freezed,
    Object? firstLayerExtruderTemp = freezed,
    Object? mmuPrint = null,
    Object? filamentChangeCount = null,
    Object? referencedTools = null,
    Object? filamentColors = null,
    Object? extruderColors = null,
    Object? filamentUsedMm = null,
  }) {
    return _then(_value.copyWith(
      name: null == name ? _value.name : name as String,
      path: null == path ? _value.path : path as String,
      size: null == size ? _value.size : size as int,
      printTime: null == printTime ? _value.printTime : printTime as double,
      thumbnailSmall: freezed == thumbnailSmall ? _value.thumbnailSmall : thumbnailSmall as String?,
      thumbnailLarge: freezed == thumbnailLarge ? _value.thumbnailLarge : thumbnailLarge as String?,
      slicerVersion: freezed == slicerVersion ? _value.slicerVersion : slicerVersion as String?,
      layerHeight: freezed == layerHeight ? _value.layerHeight : layerHeight as String?,
      objectHeight: freezed == objectHeight ? _value.objectHeight : objectHeight as String?,
      firstLayerHeight: freezed == firstLayerHeight ? _value.firstLayerHeight : firstLayerHeight as String?,
      firstLayerBedTemp: freezed == firstLayerBedTemp ? _value.firstLayerBedTemp : firstLayerBedTemp as String?,
      firstLayerExtruderTemp: freezed == firstLayerExtruderTemp ? _value.firstLayerExtruderTemp : firstLayerExtruderTemp as String?,
      mmuPrint: null == mmuPrint ? _value.mmuPrint : mmuPrint as bool,
      filamentChangeCount: null == filamentChangeCount ? _value.filamentChangeCount : filamentChangeCount as int,
      referencedTools: null == referencedTools ? _value.referencedTools : referencedTools as List<int>,
      filamentColors: null == filamentColors ? _value.filamentColors : filamentColors as List<String>,
      extruderColors: null == extruderColors ? _value.extruderColors : extruderColors as List<String>,
      filamentUsedMm: null == filamentUsedMm ? _value.filamentUsedMm : filamentUsedMm as List<double>,
    ) as $Val);
  }
}

class _$GCodeFileImpl extends _GCodeFile {
  const _$GCodeFileImpl({
    required this.name,
    required this.path,
    this.size = 0,
    this.printTime = 0,
    this.thumbnailSmall,
    this.thumbnailLarge,
    this.slicerVersion,
    this.layerHeight,
    this.objectHeight,
    this.firstLayerHeight,
    this.firstLayerBedTemp,
    this.firstLayerExtruderTemp,
    this.mmuPrint = false,
    this.filamentChangeCount = 0,
    this.referencedTools = const [],
    this.filamentColors = const [],
    this.extruderColors = const [],
    this.filamentUsedMm = const [],
  }) : super._();

  @override final String name;
  @override final String path;
  @override final int size;
  @override final double printTime;
  @override final String? thumbnailSmall;
  @override final String? thumbnailLarge;
  @override final String? slicerVersion;
  @override final String? layerHeight;
  @override final String? objectHeight;
  @override final String? firstLayerHeight;
  @override final String? firstLayerBedTemp;
  @override final String? firstLayerExtruderTemp;
  @override final bool mmuPrint;
  @override final int filamentChangeCount;
  @override final List<int> referencedTools;
  @override final List<String> filamentColors;
  @override final List<String> extruderColors;
  @override final List<double> filamentUsedMm;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is _$GCodeFileImpl &&
          other.name == name &&
          other.path == path);

  @override
  int get hashCode => Object.hash(runtimeType, name, path);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GCodeFileImplCopyWith<_$GCodeFileImpl> get copyWith =>
      __$$GCodeFileImplCopyWithImpl<_$GCodeFileImpl>(this, _$identity);
}

abstract class _$$GCodeFileImplCopyWith<$Res>
    implements $GCodeFileCopyWith<$Res> {
  factory _$$GCodeFileImplCopyWith(
          _$GCodeFileImpl value, $Res Function(_$GCodeFileImpl) then) =
      __$$GCodeFileImplCopyWithImpl<$Res>;
}

class __$$GCodeFileImplCopyWithImpl<$Res>
    extends _$GCodeFileCopyWithImpl<$Res, _$GCodeFileImpl>
    implements _$$GCodeFileImplCopyWith<$Res> {
  __$$GCodeFileImplCopyWithImpl(
      _$GCodeFileImpl _value, $Res Function(_$GCodeFileImpl) _then)
      : super(_value, _then);
}

abstract class _GCodeFile extends GCodeFile {
  const factory _GCodeFile({
    required String name,
    required String path,
    int size,
    double printTime,
    String? thumbnailSmall,
    String? thumbnailLarge,
    String? slicerVersion,
    String? layerHeight,
    String? objectHeight,
    String? firstLayerHeight,
    String? firstLayerBedTemp,
    String? firstLayerExtruderTemp,
    bool mmuPrint,
    int filamentChangeCount,
    List<int> referencedTools,
    List<String> filamentColors,
    List<String> extruderColors,
    List<double> filamentUsedMm,
  }) = _$GCodeFileImpl;
  const _GCodeFile._() : super._();

  @override String get name;
  @override String get path;
  @override int get size;
  @override double get printTime;
  @override String? get thumbnailSmall;
  @override String? get thumbnailLarge;
  @override String? get slicerVersion;
  @override String? get layerHeight;
  @override String? get objectHeight;
  @override String? get firstLayerHeight;
  @override String? get firstLayerBedTemp;
  @override String? get firstLayerExtruderTemp;
  @override bool get mmuPrint;
  @override int get filamentChangeCount;
  @override List<int> get referencedTools;
  @override List<String> get filamentColors;
  @override List<String> get extruderColors;
  @override List<double> get filamentUsedMm;
  @override @JsonKey(ignore: true)
  _$$GCodeFileImplCopyWith<_$GCodeFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
