// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_reading.freezed.dart';

/// Categories of sensors that Moonraker / Klipper can expose.
enum SensorType {
  /// Heated extruder (has temperature + target + can_extrude).
  extruder,

  /// Heated bed.
  heaterBed,

  /// Generic `temperature_sensor` (ambient, chamber, etc.).
  temperatureSensor,

  /// `temperature_fan` — fan controlled by temperature.
  temperatureFan,

  /// `filament_switch_sensor` — switch-based filament presence sensor.
  filamentSwitch,

  /// `filament_motion_sensor` — encoder-based filament movement sensor.
  filamentMotion,

  /// `probe` — Z-offset probe (BLTouch, Klicky, CR Touch, etc.).
  probe,

  /// `fan` — basic part-cooling fan.
  fan,

  /// `heater_fan` — fan tied to a heater.
  heaterFan,

  /// `controller_fan` — electronics cooling fan.
  controllerFan,

  /// Anything else Moonraker reports that doesn't fit above.
  generic,
}

/// A single live sensor reading, normalised across all Klipper sensor types.
///
/// Not every field applies to every [SensorType]; unused fields are null.
@freezed
class SensorReading with _$SensorReading {
  const factory SensorReading({
    /// Moonraker object key, e.g. "temperature_sensor chamber".
    required String objectKey,

    /// Human-readable display name derived from [objectKey].
    required String displayName,

    /// What kind of sensor this is.
    required SensorType type,

    // ── Temperature ────────────────────────────────────────────────────────

    /// Current temperature in °C (null if not a thermal sensor).
    double? temperature,

    /// Target / set-point temperature (null if unheated).
    double? target,

    /// Heater power output 0–1 (null if not a heater).
    double? power,

    /// Whether the heater can extrude at current temp (extruder only).
    bool? canExtrude,

    // ── Filament sensors ───────────────────────────────────────────────────

    /// Filament detected (true) / not detected (false). null if N/A.
    bool? filamentDetected,

    /// Filament motion detected (true = moving). null if N/A.
    bool? motionDetected,

    // ── Fans ───────────────────────────────────────────────────────────────

    /// Fan speed 0–1. null if not a fan.
    double? fanSpeed,

    // ── Probe ─────────────────────────────────────────────────────────────

    /// Probe last triggered z-offset in mm. null if not a probe.
    double? lastZ,

    // ── Generic ───────────────────────────────────────────────────────────

    /// Raw key/value pairs for sensor types that don't fit above.
    @Default({}) Map<String, dynamic> rawValues,
  }) = _SensorReading;

  const SensorReading._();

  /// A single-line status summary suitable for list tiles.
  String get statusSummary {
    return switch (type) {
      SensorType.extruder ||
      SensorType.heaterBed ||
      SensorType.temperatureSensor ||
      SensorType.temperatureFan =>
        temperature != null
            ? target != null && target! > 0
                ? '${temperature!.toStringAsFixed(1)}°C / ${target!.toStringAsFixed(0)}°C'
                : '${temperature!.toStringAsFixed(1)}°C'
            : '—',
      SensorType.filamentSwitch =>
        filamentDetected == true ? 'Filament present' : 'No filament',
      SensorType.filamentMotion =>
        motionDetected == true ? 'Moving' : 'Stopped',
      SensorType.fan ||
      SensorType.heaterFan ||
      SensorType.controllerFan =>
        fanSpeed != null
            ? '${(fanSpeed! * 100).round()}%'
            : '—',
      SensorType.probe =>
        lastZ != null ? 'Last z: ${lastZ!.toStringAsFixed(3)} mm' : '—',
      SensorType.generic => rawValues.isEmpty ? '—' : rawValues.toString(),
    };
  }

  /// Icon data name to use for this sensor type.
  bool get isAlert {
    // Filament runout
    if ((type == SensorType.filamentSwitch ||
            type == SensorType.filamentMotion) &&
        filamentDetected == false) return true;
    return false;
  }

  /// Whether this sensor is heating toward a target.
  bool get isHeating =>
      temperature != null &&
      target != null &&
      target! > 0 &&
      temperature! < (target! - 2);
}
