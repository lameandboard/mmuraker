// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'notification_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorThresholdConfigAdapter extends TypeAdapter<SensorThresholdConfig> {
  @override
  final int typeId = 4;

  @override
  SensorThresholdConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorThresholdConfig(
      enabled: fields[0] as bool? ?? true,
      targetReachedToleranceDeg: fields[1] as double? ?? 3.0,
      dropAlertEnabled: fields[2] as bool? ?? false,
      dropAlertDeg: fields[3] as double? ?? 10.0,
    );
  }

  @override
  void write(BinaryWriter writer, SensorThresholdConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.targetReachedToleranceDeg)
      ..writeByte(2)
      ..write(obj.dropAlertEnabled)
      ..writeByte(3)
      ..write(obj.dropAlertDeg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorThresholdConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 3;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      printStart: fields[0] as bool? ?? true,
      printComplete: fields[1] as bool? ?? true,
      printPaused: fields[2] as bool? ?? true,
      printCancelled: fields[3] as bool? ?? true,
      printError: fields[4] as bool? ?? true,
      printProgress: fields[5] as bool? ?? false,
      progressIntervalPct: fields[6] as int? ?? 25,
      klippyDisconnected: fields[7] as bool? ?? true,
      klippyError: fields[8] as bool? ?? true,
      mmuError: fields[9] as bool? ?? true,
      mmuFilamentChange: fields[10] as bool? ?? true,
      sensorConfigs: (fields[11] as Map?)
              ?.cast<String, SensorThresholdConfig>() ??
          {},
      disabledSensors:
          (fields[12] as List?)?.cast<String>().toSet() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.printStart)
      ..writeByte(1)
      ..write(obj.printComplete)
      ..writeByte(2)
      ..write(obj.printPaused)
      ..writeByte(3)
      ..write(obj.printCancelled)
      ..writeByte(4)
      ..write(obj.printError)
      ..writeByte(5)
      ..write(obj.printProgress)
      ..writeByte(6)
      ..write(obj.progressIntervalPct)
      ..writeByte(7)
      ..write(obj.klippyDisconnected)
      ..writeByte(8)
      ..write(obj.klippyError)
      ..writeByte(9)
      ..write(obj.mmuError)
      ..writeByte(10)
      ..write(obj.mmuFilamentChange)
      ..writeByte(11)
      ..write(obj.sensorConfigs)
      ..writeByte(12)
      ..write(obj.disabledSensors.toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
