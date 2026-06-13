// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmuraker/service/moonraker/printer_service.dart';
import 'package:mmuraker/ui/components/common_widgets.dart';

class SpeedFlowCard extends HookConsumerWidget {
  const SpeedFlowCard({
    super.key,
    required this.printerService,
    required this.printState,
    required this.speedFactor,
    required this.extrudeFactor,
  });

  final PrinterService printerService;
  final String printState;
  final double speedFactor;
  final double extrudeFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speedPercent = useState((speedFactor * 100).clamp(0, 200).roundToDouble());
    final flowPercent = useState((extrudeFactor * 100).clamp(0, 200).roundToDouble());
    final enabled = printState == 'printing' || printState == 'paused';

    useEffect(() {
      speedPercent.value = (speedFactor * 100).clamp(0, 200).roundToDouble();
      flowPercent.value = (extrudeFactor * 100).clamp(0, 200).roundToDouble();
      return null;
    }, [speedFactor, extrudeFactor]);

    Future<void> sendPercent(String command, double value) async {
      try {
        await printerService.sendGcode('$command S${value.round()}');
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update override: $error')),
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
            const SectionHeader('Speed & Flow'),
            const Gap(8),
            _OverrideSliderRow(
              label: 'Print speed',
              value: speedPercent.value,
              enabled: enabled,
              onChanged: (value) => speedPercent.value = value,
              onChangeEnd: (value) => sendPercent('M220', value),
              onReset: enabled
                  ? () {
                      speedPercent.value = 100;
                      sendPercent('M220', 100);
                    }
                  : null,
            ),
            const Gap(16),
            _OverrideSliderRow(
              label: 'Flow rate',
              value: flowPercent.value,
              enabled: enabled,
              onChanged: (value) => flowPercent.value = value,
              onChangeEnd: (value) => sendPercent('M221', value),
              onReset: enabled
                  ? () {
                      flowPercent.value = 100;
                      sendPercent('M221', 100);
                    }
                  : null,
            ),
            if (!enabled) ...[
              const Gap(12),
              Text(
                'Overrides are available while the printer is printing or paused.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverrideSliderRow extends StatelessWidget {
  const _OverrideSliderRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onReset,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label ${value.round()}%',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(onPressed: onReset, child: const Text('Reset')),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 200,
          divisions: 40,
          label: '${value.round()}%',
          onChanged: enabled ? onChanged : null,
          onChangeEnd: enabled ? onChangeEnd : null,
        ),
      ],
    );
  }
}
