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

class ZOffsetCard extends HookConsumerWidget {
  const ZOffsetCard({
    super.key,
    required this.printerService,
    required this.zOffset,
    required this.printState,
    this.hasProbe = true,
  });

  final PrinterService printerService;
  final double? zOffset;
  final String printState;
  final bool hasProbe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStep = useState(0.05);
    final busy = useState(false);
    final enabled = zOffset != null && printState == 'printing';

    Future<void> sendAdjustment(double delta) async {
      if (!enabled || busy.value) return;
      busy.value = true;
      try {
        await printerService.sendGcode(
          'SET_GCODE_OFFSET Z_ADJUST=${delta.toStringAsFixed(2)} MOVE=1',
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to adjust Z offset: $error')),
          );
        }
      } finally {
        busy.value = false;
      }
    }

    Future<void> saveOffset() async {
      if (!enabled || busy.value) return;
      busy.value = true;
      try {
        await printerService.sendGcode(
          hasProbe ? 'Z_OFFSET_APPLY_PROBE' : 'Z_OFFSET_APPLY_ENDSTOP',
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save Z offset: $error')),
          );
        }
      } finally {
        busy.value = false;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Z Offset'),
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    zOffset == null ? '—' : zOffset!.toStringAsFixed(3),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Gap(4),
                  Text(
                    'Current Z offset (mm)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Gap(16),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0.01, label: Text('0.01 mm')),
                ButtonSegment(value: 0.05, label: Text('0.05 mm')),
                ButtonSegment(value: 0.10, label: Text('0.10 mm')),
              ],
              selected: {selectedStep.value},
              onSelectionChanged: enabled
                  ? (selection) => selectedStep.value = selection.first
                  : null,
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: enabled ? () => sendAdjustment(-selectedStep.value) : null,
                    icon: const Icon(Icons.remove),
                    label: const Text('Lower nozzle'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: enabled ? () => sendAdjustment(selectedStep.value) : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Raise nozzle'),
                  ),
                ),
              ],
            ),
            const Gap(12),
            FilledButton.icon(
              onPressed: enabled ? saveOffset : null,
              icon: busy.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save to config'),
            ),
            if (!enabled) ...[
              const Gap(12),
              Text(
                'Babystepping is available only while printing and when homing origin data is available.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
