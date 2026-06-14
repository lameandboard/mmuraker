// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../components/common_widgets.dart';

class SensorOverviewCard extends StatelessWidget {
  const SensorOverviewCard({
    super.key,
    required this.thermalSensors,
    required this.binarySensors,
  });

  final List<MapEntry<String, Map<String, dynamic>>> thermalSensors;
  final List<MapEntry<String, Object?>> binarySensors;

  @override
  Widget build(BuildContext context) {
    if (thermalSensors.isEmpty && binarySensors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Sensors'),
            const Gap(8),
            if (thermalSensors.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sensor in thermalSensors)
                    TemperatureChip(
                      label: _prettifyLabel(sensor.key),
                      current: _readDouble(sensor.value['temperature']),
                      target: _readDouble(sensor.value['target']),
                      isHeating: _readDouble(sensor.value['target']) > 0,
                    ),
                ],
              ),
            ],
            if (binarySensors.isNotEmpty) ...[
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sensor in binarySensors)
                    Chip(
                      avatar: Icon(
                        _readBinaryState(sensor.value)
                            ? Icons.sensors
                            : Icons.sensors_off_outlined,
                        size: 18,
                      ),
                      label: Text(
                        '${_prettifyLabel(sensor.key)}: '
                        '${_readBinaryState(sensor.value) ? 'Detected' : 'Clear'}',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static bool _readBinaryState(Object? value) {
    if (value is bool) return value;
    if (value is Map<String, dynamic>) {
      for (final key in const [
        'filament_detected',
        'detected',
        'triggered',
        'state',
      ]) {
        final sensorValue = value[key];
        if (sensorValue is bool) return sensorValue;
        if (sensorValue is num) return sensorValue != 0;
        if (sensorValue is String) {
          final lowered = sensorValue.toLowerCase();
          if (lowered == 'true' || lowered == 'triggered' || lowered == 'detected') {
            return true;
          }
          if (lowered == 'false' || lowered == 'open' || lowered == 'clear') {
            return false;
          }
        }
      }
    }
    return false;
  }

  static String _prettifyLabel(String raw) {
    final label = raw.contains(' ')
        ? raw.substring(raw.indexOf(' ') + 1)
        : raw;
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
