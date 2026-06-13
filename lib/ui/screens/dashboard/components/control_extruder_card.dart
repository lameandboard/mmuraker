// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../../data/dto/machine/printer.dart';
import '../../../../service/moonraker/printer_service.dart';
import '../../../components/common_widgets.dart';

/// Extruder control card — move filament, set feed rate, retract.
///
/// Shown for every printer regardless of MMU state.  No feature is paywalled.
class ControlExtruderCard extends StatelessWidget {
  const ControlExtruderCard({
    super.key,
    required this.printer,
    required this.printerService,
  });

  final Printer printer;
  final PrinterService printerService;

  static const _feedAmounts = [1.0, 5.0, 10.0, 25.0];

  @override
  Widget build(BuildContext context) {
    final ext = printer.activeExtruder;
    final canExtrude = ext.canExtrude;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Extruder'),
            const Gap(8),
            Row(
              children: [
                Text(
                  'Active: ${printer.toolhead.activeExtruder}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (!canExtrude)
                  const Tooltip(
                    message: 'Below minimum extrusion temperature',
                    child: Icon(Icons.thermostat, size: 16, color: Colors.orange),
                  ),
              ],
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedAmounts
                  .map(
                    (amount) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: canExtrude
                              ? () => _extrude(amount)
                              : null,
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: Text('${amount.toStringAsFixed(0)}mm'),
                        ),
                        const Gap(4),
                        OutlinedButton.icon(
                          onPressed: canExtrude
                              ? () => _extrude(-amount)
                              : null,
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          label: Text('${amount.toStringAsFixed(0)}mm'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const Gap(8),
            _SpeedFactorSlider(
              value: printer.toolhead.speedFactor,
              onChanged: (v) => printerService.sendGcode(
                'M220 S${(v * 100).round()}',
              ),
            ),
            _ExtrudeFactorSlider(
              value: printer.toolhead.extrudeFactor,
              onChanged: (v) => printerService.sendGcode(
                'M221 S${(v * 100).round()}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _extrude(double amount) {
    final dir = amount > 0 ? amount : amount.abs();
    final cmd = amount > 0
        ? 'M83\nG1 E$dir F300'
        : 'M83\nG1 E-$dir F300';
    printerService.sendGcode(cmd);
  }
}

class _SpeedFactorSlider extends StatelessWidget {
  const _SpeedFactorSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.speed, size: 18),
        const Gap(8),
        Text(
          'Speed ${(value * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0.1, 2.0),
            min: 0.1,
            max: 2.0,
            divisions: 19,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ExtrudeFactorSlider extends StatelessWidget {
  const _ExtrudeFactorSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.linear_scale, size: 18),
        const Gap(8),
        Text(
          'Flow ${(value * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0.5, 1.5),
            min: 0.5,
            max: 1.5,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
