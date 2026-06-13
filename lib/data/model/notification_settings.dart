// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:hive_flutter/hive_flutter.dart';

import 'package:mmuraker/util/app_constants.dart';

part 'notification_settings.g.dart';

// ── Per-sensor threshold config ───────────────────────────────────────────────

/// Optional threshold alert config attached to a specific sensor.
///
/// When [enabled] is true, a notification fires whenever the sensor's
/// temperature crosses [targetReachedToleranceDeg] of its set target.
@HiveType(typeId: AppConstants.sensorThresholdAdapterId)
class SensorThresholdConfig extends HiveObject {
  /// Whether this sensor's "target reached" alert is active.
  @HiveField(0)
  bool enabled;

  /// How many °C within the target counts as "reached" (default ±3°C).
  @HiveField(1)
  double targetReachedToleranceDeg;

  /// Whether to alert when the sensor drops more than [dropAlertDeg] below
  /// its target mid-print (e.g. heater failure).
  @HiveField(2)
  bool dropAlertEnabled;

  /// Drop threshold in °C that triggers an alert.
  @HiveField(3)
  double dropAlertDeg;

  SensorThresholdConfig({
    this.enabled = true,
    this.targetReachedToleranceDeg = 3.0,
    this.dropAlertEnabled = false,
    this.dropAlertDeg = 10.0,
  });
}

// ── Top-level notification settings ──────────────────────────────────────────

/// Persisted per-machine notification preferences.
///
/// Every notification type can be disabled individually — no notification is
/// forced on the user.  The defaults mirror what most users would expect:
/// print events on, sensor spam off.
@HiveType(typeId: AppConstants.notificationSettingsAdapterId)
class NotificationSettings extends HiveObject {
  // ── Print life-cycle ────────────────────────────────────────────────────

  /// Notify when a print job starts.
  @HiveField(0)
  bool printStart;

  /// Notify when a print job completes successfully.
  @HiveField(1)
  bool printComplete;

  /// Notify when a print job is paused (manually or by MMU).
  @HiveField(2)
  bool printPaused;

  /// Notify when a print job is cancelled.
  @HiveField(3)
  bool printCancelled;

  /// Notify when a print job errors.
  @HiveField(4)
  bool printError;

  /// Notify at regular progress milestones (every [progressIntervalPct] %).
  @HiveField(5)
  bool printProgress;

  /// How often (in percent) to fire progress notifications (default 25 %).
  @HiveField(6)
  int progressIntervalPct;

  // ── Klippy / connection ─────────────────────────────────────────────────

  /// Notify when Klipper disconnects unexpectedly.
  @HiveField(7)
  bool klippyDisconnected;

  /// Notify when Klipper enters an error / shutdown state.
  @HiveField(8)
  bool klippyError;

  // ── MMU ─────────────────────────────────────────────────────────────────

  /// Notify when the MMU reports an error or pause.
  @HiveField(9)
  bool mmuError;

  /// Notify when the MMU requests a filament change (M600 / MMU_PAUSE).
  @HiveField(10)
  bool mmuFilamentChange;

  // ── Per-sensor map ───────────────────────────────────────────────────────
  //
  // Keys are the Moonraker object names exactly as they appear in
  // `printer.objects.list`, e.g.:
  //   "extruder", "extruder1", "heater_bed",
  //   "temperature_sensor chamber", "filament_switch_sensor runout", …
  //
  // A missing key is treated as enabled (default-on for new sensors).

  /// Per-sensor threshold notification preferences, keyed by sensor name.
  @HiveField(11)
  Map<String, SensorThresholdConfig> sensorConfigs;

  /// Sensors the user has explicitly disabled entirely (no notifications at
  /// all, regardless of [sensorConfigs]).
  @HiveField(12)
  Set<String> disabledSensors;

  NotificationSettings({
    this.printStart = true,
    this.printComplete = true,
    this.printPaused = true,
    this.printCancelled = true,
    this.printError = true,
    this.printProgress = false,
    this.progressIntervalPct = 25,
    this.klippyDisconnected = true,
    this.klippyError = true,
    this.mmuError = true,
    this.mmuFilamentChange = true,
    Map<String, SensorThresholdConfig>? sensorConfigs,
    Set<String>? disabledSensors,
  })  : sensorConfigs = sensorConfigs ?? {},
        disabledSensors = disabledSensors ?? {};

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Whether notifications for [sensorName] are enabled at all.
  bool isSensorEnabled(String sensorName) =>
      !disabledSensors.contains(sensorName);

  /// Toggle a sensor entirely on/off.
  void setSensorEnabled(String sensorName, {required bool enabled}) {
    if (enabled) {
      disabledSensors.remove(sensorName);
    } else {
      disabledSensors.add(sensorName);
    }
  }

  /// Get or create threshold config for [sensorName].
  SensorThresholdConfig sensorConfig(String sensorName) =>
      sensorConfigs.putIfAbsent(sensorName, SensorThresholdConfig.new);

  /// Returns a default [NotificationSettings] — all print events on, no
  /// sensor spam.
  factory NotificationSettings.defaults() => NotificationSettings();
}
