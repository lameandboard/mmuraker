// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/model/notification_settings.dart';
import '../util/app_constants.dart';
import '../util/logger.dart';

part 'notification_service.g.dart';

@riverpod
NotificationService notificationService(Ref ref) => NotificationService(ref);

/// Fires local notifications for printer and sensor events.
///
/// Every notification type is gated by the per-machine [NotificationSettings]
/// stored in Hive.  Users can disable individual sensors one-by-one from the
/// Notification Settings screen — nothing is forced on them.
///
/// No ads, no Firebase, no remote push: local notifications only.
class NotificationService {
  NotificationService(this._ref) {
    _init();
  }

  final Ref _ref;

  final _plugin = FlutterLocalNotificationsPlugin();
  final _settingsBoxName = 'notification_settings';
  late Box<NotificationSettings> _box;

  // Notification channel IDs
  static const _channelPrint = 'mmuraker_print';
  static const _channelSensor = 'mmuraker_sensor';
  static const _channelMmu = 'mmuraker_mmu';
  static const _channelSystem = 'mmuraker_system';

  Future<void> _init() async {
    // Register Hive adapters if not already done.
    if (!Hive.isAdapterRegistered(AppConstants.notificationSettingsAdapterId)) {
      Hive.registerAdapter(NotificationSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.sensorThresholdAdapterId)) {
      Hive.registerAdapter(SensorThresholdConfigAdapter());
    }
    _box = await Hive.openBox<NotificationSettings>(_settingsBoxName);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    logger.info('NotificationService: initialised');
  }

  // ── Settings access ────────────────────────────────────────────────────────

  /// Get (or create default) [NotificationSettings] for [machineId].
  NotificationSettings settingsFor(String machineId) =>
      _box.get(machineId) ?? NotificationSettings.defaults();

  /// Persist updated settings for [machineId].
  Future<void> saveSettings(
    String machineId,
    NotificationSettings settings,
  ) async {
    await _box.put(machineId, settings);
    logger.info('NotificationService: saved settings for $machineId');
  }

  // ── Notification dispatch ──────────────────────────────────────────────────

  /// Call when a print job starts.
  Future<void> notifyPrintStart(String machineId, String filename) async {
    final s = settingsFor(machineId);
    if (!s.printStart) return;
    await _show(
      id: _id('print_start', machineId),
      channelId: _channelPrint,
      channelName: 'Print Events',
      title: 'Print started',
      body: filename,
      importance: Importance.defaultImportance,
    );
  }

  /// Call when a print job completes.
  Future<void> notifyPrintComplete(String machineId, String filename) async {
    final s = settingsFor(machineId);
    if (!s.printComplete) return;
    await _show(
      id: _id('print_done', machineId),
      channelId: _channelPrint,
      channelName: 'Print Events',
      title: '✅ Print complete!',
      body: filename,
      importance: Importance.high,
    );
  }

  /// Call when a print is paused.
  Future<void> notifyPrintPaused(
    String machineId,
    String filename, {
    String? reason,
  }) async {
    final s = settingsFor(machineId);
    if (!s.printPaused) return;
    await _show(
      id: _id('print_paused', machineId),
      channelId: _channelPrint,
      channelName: 'Print Events',
      title: '⏸ Print paused',
      body: reason != null ? '$filename — $reason' : filename,
      importance: Importance.high,
    );
  }

  /// Call when a print is cancelled.
  Future<void> notifyPrintCancelled(String machineId, String filename) async {
    final s = settingsFor(machineId);
    if (!s.printCancelled) return;
    await _show(
      id: _id('print_cancelled', machineId),
      channelId: _channelPrint,
      channelName: 'Print Events',
      title: 'Print cancelled',
      body: filename,
      importance: Importance.defaultImportance,
    );
  }

  /// Call when a print errors.
  Future<void> notifyPrintError(
    String machineId,
    String filename,
    String error,
  ) async {
    final s = settingsFor(machineId);
    if (!s.printError) return;
    await _show(
      id: _id('print_error', machineId),
      channelId: _channelPrint,
      channelName: 'Print Events',
      title: '🔴 Print error',
      body: '$filename — $error',
      importance: Importance.max,
    );
  }

  /// Call at print progress milestones (checks interval setting).
  Future<void> notifyPrintProgress(
    String machineId,
    String filename,
    double progress,
  ) async {
    final s = settingsFor(machineId);
    if (!s.printProgress) return;
    final pct = (progress * 100).round();
    final interval = s.progressIntervalPct.clamp(5, 100);
    if (pct % interval != 0) return;
    await _show(
      id: _id('print_progress', machineId),
      channelId: _channelPrint,
      channelName: 'Print Events',
      title: 'Print $pct% complete',
      body: filename,
      importance: Importance.low,
    );
  }

  /// Call when a specific sensor reaches its target temperature.
  ///
  /// Checks [NotificationSettings.isSensorEnabled] AND the sensor's individual
  /// [SensorThresholdConfig.enabled] before firing.
  Future<void> notifySensorTargetReached(
    String machineId,
    String sensorName,
    double temperature,
  ) async {
    final s = settingsFor(machineId);
    if (!s.isSensorEnabled(sensorName)) return;
    final cfg = s.sensorConfig(sensorName);
    if (!cfg.enabled) return;

    await _show(
      id: _id('sensor_$sensorName', machineId),
      channelId: _channelSensor,
      channelName: 'Sensor Alerts',
      title: '🌡 $sensorName ready',
      body: '${temperature.toStringAsFixed(0)}°C reached',
      importance: Importance.defaultImportance,
    );
  }

  /// Call when a sensor drops unexpectedly far below its target (heater fault).
  Future<void> notifySensorDrop(
    String machineId,
    String sensorName,
    double temperature,
    double target,
  ) async {
    final s = settingsFor(machineId);
    if (!s.isSensorEnabled(sensorName)) return;
    final cfg = s.sensorConfig(sensorName);
    if (!cfg.dropAlertEnabled) return;
    final drop = target - temperature;
    if (drop < cfg.dropAlertDeg) return;

    await _show(
      id: _id('sensor_drop_$sensorName', machineId),
      channelId: _channelSensor,
      channelName: 'Sensor Alerts',
      title: '⚠️ $sensorName temperature drop',
      body:
          '${temperature.toStringAsFixed(0)}°C — ${drop.toStringAsFixed(0)}°C below target',
      importance: Importance.high,
    );
  }

  // ── MMU notifications ──────────────────────────────────────────────────────

  /// Call when the MMU reports an error.
  Future<void> notifyMmuError(String machineId, String error) async {
    final s = settingsFor(machineId);
    if (!s.mmuError) return;
    await _show(
      id: _id('mmu_error', machineId),
      channelId: _channelMmu,
      channelName: 'MMU Alerts',
      title: '🔴 MMU error',
      body: error,
      importance: Importance.max,
    );
  }

  /// Call when the MMU requests a filament change.
  Future<void> notifyMmuFilamentChange(String machineId, int tool) async {
    final s = settingsFor(machineId);
    if (!s.mmuFilamentChange) return;
    await _show(
      id: _id('mmu_change', machineId),
      channelId: _channelMmu,
      channelName: 'MMU Alerts',
      title: '🔄 MMU filament change',
      body: 'Tool T$tool requested',
      importance: Importance.high,
    );
  }

  // ── System / connection notifications ─────────────────────────────────────

  /// Call when Klipper disconnects unexpectedly.
  Future<void> notifyKlippyDisconnected(String machineId) async {
    final s = settingsFor(machineId);
    if (!s.klippyDisconnected) return;
    await _show(
      id: _id('klippy_dc', machineId),
      channelId: _channelSystem,
      channelName: 'System Alerts',
      title: 'Printer disconnected',
      body: 'Klipper is no longer reachable',
      importance: Importance.high,
    );
  }

  /// Call when Klipper enters an error or shutdown state.
  Future<void> notifyKlippyError(String machineId, String message) async {
    final s = settingsFor(machineId);
    if (!s.klippyError) return;
    await _show(
      id: _id('klippy_err', machineId),
      channelId: _channelSystem,
      channelName: 'System Alerts',
      title: '🔴 Klipper error',
      body: message,
      importance: Importance.max,
    );
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required Importance importance,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.max ? Priority.max : Priority.defaultPriority,
    );
    final details = NotificationDetails(android: androidDetails);
    try {
      await _plugin.show(id, title, body, details);
    } catch (e, st) {
      logger.error('NotificationService: failed to show notification', e, st);
    }
  }

  /// Stable int ID derived from a string key + machine ID to avoid collisions.
  static int _id(String key, String machineId) =>
      (key + machineId).hashCode.abs() % 100000;
}
