// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmuraker/service/moonraker/printer_service.dart';
import 'package:mmuraker/ui/components/common_widgets.dart';

final _powerDevicesProvider =
    StateNotifierProvider.autoDispose.family<PowerDevicesNotifier, List<PowerDevice>, String>(
  (ref, machineId) => PowerDevicesNotifier(
    ref,
    machineId,
    ref.read(printerServiceProvider(machineId)),
  ),
);

final _powerDevicesLoadingProvider =
    StateProvider.autoDispose.family<bool, String>((ref, machineId) => true);

final _powerDevicesTogglingProvider =
    StateProvider.autoDispose.family<Set<String>, String>(
  (ref, machineId) => <String>{},
);

class PowerDevice {
  const PowerDevice({
    required this.name,
    required this.status,
    required this.type,
  });

  factory PowerDevice.fromJson(Map<String, dynamic> json) {
    return PowerDevice(
      name: json['device']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      status: (json['status']?.toString() ?? 'unknown').toLowerCase(),
      type: json['type']?.toString() ?? 'switch',
    );
  }

  final String name;
  final String status;
  final String type;

  bool get isOn => status == 'on';
}

class PowerDevicesNotifier extends StateNotifier<List<PowerDevice>> {
  PowerDevicesNotifier(this._ref, this.machineId, this._printerService)
      : super(const []) {
    load();
  }

  final Ref _ref;
  final String machineId;
  final PrinterService _printerService;

  Future<void> load() async {
    _ref.read(_powerDevicesLoadingProvider(machineId).notifier).state = true;
    try {
      final result = await _printerService.sendJsonRpc(
        'machine.device_power.devices',
      );
      final rawDevices = result is List
          ? result
          : result is Map
              ? (result['devices'] as List? ?? const [])
              : const [];
      state = rawDevices
          .whereType<Map>()
          .map((device) => PowerDevice.fromJson(Map<String, dynamic>.from(device)))
          .toList(growable: false);
    } finally {
      _ref.read(_powerDevicesLoadingProvider(machineId).notifier).state = false;
    }
  }

  Future<void> toggle(PowerDevice device) async {
    final togglingNotifier =
        _ref.read(_powerDevicesTogglingProvider(machineId).notifier);
    togglingNotifier.state = {...togglingNotifier.state, device.name};
    try {
      await _printerService.sendJsonRpc('machine.device_power.post_device', {
        'device': device.name,
        'action': device.isOn ? 'off' : 'on',
      });
      await load();
    } finally {
      final next = {...togglingNotifier.state}..remove(device.name);
      togglingNotifier.state = next;
    }
  }
}

class PowerDevicesCard extends HookConsumerWidget {
  const PowerDevicesCard({super.key, required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(_powerDevicesProvider(machineId));
    final loading = ref.watch(_powerDevicesLoadingProvider(machineId));
    final toggling = ref.watch(_powerDevicesTogglingProvider(machineId));
    final notifier = ref.read(_powerDevicesProvider(machineId).notifier);

    Future<void> handleToggle(PowerDevice device) async {
      try {
        await notifier.toggle(device);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to toggle ${device.name}: $error')),
          );
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SectionHeader('Power'),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh power devices',
                  onPressed: loading ? null : notifier.load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Gap(8),
            if (loading && devices.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (devices.isEmpty)
              const Text('No power devices found.')
            else
              Column(
                children: [
                  for (final device in devices) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(device.name),
                      subtitle: Text(device.type),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PowerStatusChip(status: device.status),
                          const Gap(12),
                          if (toggling.contains(device.name))
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Switch(
                              value: device.isOn,
                              onChanged: (_) => handleToggle(device),
                            ),
                        ],
                      ),
                    ),
                    if (device != devices.last) const Divider(height: 1),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PowerStatusChip extends StatelessWidget {
  const _PowerStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (background, foreground, label) = switch (status) {
      'on' => (Colors.green.shade100, Colors.green.shade900, 'On'),
      'off' => (cs.errorContainer, cs.onErrorContainer, 'Off'),
      'error' => (Colors.orange.shade100, Colors.orange.shade900, 'Error'),
      _ => (cs.surfaceVariant, cs.onSurfaceVariant, 'Unknown'),
    };

    return Chip(
      backgroundColor: background,
      label: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
