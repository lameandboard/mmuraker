// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../../data/dto/machine/printer.dart';
import '../../../components/common_widgets.dart';

/// Temperature card — shows extruder(s) and bed temps with target-set controls.
class TemperatureCard extends StatelessWidget {
  const TemperatureCard({
    super.key,
    required this.printer,
    required this.onSetExtruderTemp,
    required this.onSetBedTemp,
  });

  final Printer printer;
  final void Function(int index, double temp) onSetExtruderTemp;
  final void Function(double temp) onSetBedTemp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Temperatures'),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ext in printer.extruders)
                  GestureDetector(
                    onTap: () => _showTempDialog(
                      context,
                      label: ext.index == 0
                          ? 'Extruder'
                          : 'Extruder ${ext.index}',
                      current: ext.target,
                      onSet: (t) => onSetExtruderTemp(ext.index, t),
                    ),
                    child: TemperatureChip(
                      label: ext.index == 0
                          ? 'Extruder'
                          : 'T${ext.index}',
                      current: ext.temperature,
                      target: ext.target,
                      isHeating: ext.temperature < ext.target && ext.target > 0,
                    ),
                  ),
                if (printer.heatedBed != null)
                  GestureDetector(
                    onTap: () => _showTempDialog(
                      context,
                      label: 'Bed',
                      current: printer.heatedBed!.target,
                      onSet: onSetBedTemp,
                    ),
                    child: TemperatureChip(
                      label: 'Bed',
                      current: printer.heatedBed!.temperature,
                      target: printer.heatedBed!.target,
                      isHeating: printer.heatedBed!.temperature <
                              printer.heatedBed!.target &&
                          printer.heatedBed!.target > 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTempDialog(
    BuildContext context, {
    required String label,
    required double current,
    required void Function(double) onSet,
  }) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $label Temperature'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            suffixText: '°C',
            hintText: 'Enter temperature',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSet(0);
              Navigator.pop(ctx, true);
            },
            child: const Text('Off'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (confirmed == true && controller.text.isNotEmpty) {
      onSet(double.tryParse(controller.text) ?? 0);
    }
    controller.dispose();
  }
}
