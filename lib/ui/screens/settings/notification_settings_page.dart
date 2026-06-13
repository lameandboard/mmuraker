// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/model/machine.dart';
import '../../../data/model/notification_settings.dart';
import '../../../service/machine_service.dart';
import '../../../service/notification_service.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key, required this.machineId});

  final String machineId;

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  static const _temperatureDefaultsKey = '__temperature_defaults__';

  final _dropThresholdController = TextEditingController();
  NotificationSettings? _settings;

  @override
  void dispose() {
    _dropThresholdController.dispose();
    super.dispose();
  }

  bool _ensureLoaded(NotificationService service) {
    if (_settings != null) return true;
    final settings = service.settingsFor(widget.machineId);
    _settings = settings;
    _dropThresholdController.text =
        _temperatureDefaults(settings).dropAlertDeg.toStringAsFixed(0);
    return true;
  }

  SensorThresholdConfig _temperatureDefaults(NotificationSettings settings) {
    return settings.sensorConfigs.putIfAbsent(
      _temperatureDefaultsKey,
      () => SensorThresholdConfig(dropAlertDeg: 5.0),
    );
  }

  Future<void> _persist() async {
    final settings = _settings;
    if (settings == null) return;
    await ref
        .read(notificationServiceProvider)
        .saveSettings(widget.machineId, settings);
  }

  void _setTemperatureEnabled(bool enabled) {
    final settings = _settings!;
    final defaults = _temperatureDefaults(settings)..enabled = enabled;
    for (final entry in settings.sensorConfigs.entries) {
      if (entry.key == _temperatureDefaultsKey) continue;
      entry.value.enabled = defaults.enabled;
    }
  }

  void _setDropAlertEnabled(bool enabled) {
    final settings = _settings!;
    final defaults = _temperatureDefaults(settings)..dropAlertEnabled = enabled;
    for (final entry in settings.sensorConfigs.entries) {
      if (entry.key == _temperatureDefaultsKey) continue;
      entry.value.dropAlertEnabled = defaults.dropAlertEnabled;
    }
  }

  void _setDropThreshold(double value) {
    final settings = _settings!;
    final defaults = _temperatureDefaults(settings)..dropAlertDeg = value;
    for (final entry in settings.sensorConfigs.entries) {
      if (entry.key == _temperatureDefaultsKey) continue;
      entry.value.dropAlertDeg = value;
    }
  }

  String _displayNameForSensor(String objectKey) {
    final label = objectKey
        .replaceFirst('filament_switch_sensor ', '')
        .replaceFirst('filament_motion_sensor ', '')
        .replaceFirst('temperature_sensor ', '')
        .replaceAll('_', ' ')
        .trim();
    return label
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = ref.watch(notificationServiceProvider);

    try {
      _ensureLoaded(notificationService);
    } catch (_) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Machine? machine;
    try {
      machine = ref.watch(machineServiceProvider).findById(widget.machineId);
    } catch (_) {
      machine = null;
    }
    final settings = _settings!;
    final temperatureDefaults = _temperatureDefaults(settings);
    final sensorKeys = {
      ...settings.sensorConfigs.keys.where((key) => key != _temperatureDefaultsKey),
      ...settings.disabledSensors,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(machine == null
            ? 'Notification Settings'
            : '${machine.name} Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, 'Print Events'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Print started'),
                  value: settings.printStart,
                  onChanged: (value) async {
                    setState(() => settings.printStart = value);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('Print completed'),
                  value: settings.printComplete,
                  onChanged: (value) async {
                    setState(() => settings.printComplete = value);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('Print failed / cancelled'),
                  value: settings.printCancelled || settings.printError,
                  onChanged: (value) async {
                    setState(() {
                      settings.printCancelled = value;
                      settings.printError = value;
                    });
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('Print progress'),
                  subtitle: const Text('Notify every N%'),
                  value: settings.printProgress,
                  onChanged: (value) async {
                    setState(() => settings.printProgress = value);
                    await _persist();
                  },
                ),
                if (settings.printProgress)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DropdownButtonFormField<int>(
                      value: settings.progressIntervalPct,
                      decoration: const InputDecoration(
                        labelText: 'Interval',
                        border: OutlineInputBorder(),
                      ),
                      items: const [10, 25, 50]
                          .map(
                            (value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value%'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => settings.progressIntervalPct = value);
                        await _persist();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
          _sectionHeader(context, 'Klippy'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Klippy disconnected'),
                  value: settings.klippyDisconnected,
                  onChanged: (value) async {
                    setState(() => settings.klippyDisconnected = value);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('Klippy error / shutdown'),
                  value: settings.klippyError,
                  onChanged: (value) async {
                    setState(() => settings.klippyError = value);
                    await _persist();
                  },
                ),
              ],
            ),
          ),
          const Gap(12),
          _sectionHeader(context, 'MMU Events'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('MMU error'),
                  value: settings.mmuError,
                  onChanged: (value) async {
                    setState(() => settings.mmuError = value);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('MMU filament change complete'),
                  value: settings.mmuFilamentChange,
                  onChanged: (value) async {
                    setState(() => settings.mmuFilamentChange = value);
                    await _persist();
                  },
                ),
              ],
            ),
          ),
          const Gap(12),
          _sectionHeader(context, 'Filament Sensors'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Individual sensors appear here once the printer is connected.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          if (sensorKeys.isNotEmpty)
            Card(
              child: Column(
                children: sensorKeys
                    .map(
                      (objectKey) => SwitchListTile(
                        title: Text(_displayNameForSensor(objectKey)),
                        subtitle: const Text('Alert when filament runs out'),
                        value: settings.isSensorEnabled(objectKey),
                        onChanged: (value) async {
                          setState(() {
                            settings.setSensorEnabled(objectKey, enabled: value);
                          });
                          await _persist();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          const Gap(12),
          _sectionHeader(context, 'Temperature Alerts'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Temperature target reached'),
                  value: temperatureDefaults.enabled,
                  onChanged: (value) async {
                    setState(() => _setTemperatureEnabled(value));
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('Temperature drop alert'),
                  value: temperatureDefaults.dropAlertEnabled,
                  onChanged: (value) async {
                    setState(() => _setDropAlertEnabled(value));
                    await _persist();
                  },
                ),
                if (temperatureDefaults.dropAlertEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextFormField(
                      controller: _dropThresholdController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Drop threshold (°C)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) async {
                        final parsed = double.tryParse(value);
                        if (parsed == null) return;
                        setState(() => _setDropThreshold(parsed));
                        await _persist();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
