// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../data/dto/machine/printer.dart';

/// Top dashboard card: Klipper state, print progress, ETA.
class PrinterStatusCard extends StatelessWidget {
  const PrinterStatusCard({super.key, required this.printer});
  final Printer printer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPrinting = printer.printState == 'printing';
    final isPaused = printer.printState == 'paused';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _KlippyStatusDot(ready: printer.klippyReady),
                const Gap(8),
                Text(
                  printer.klippyState.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: printer.klippyReady
                            ? cs.primary
                            : cs.error,
                      ),
                ),
                const Spacer(),
                _PrintStateBadge(state: printer.printState),
              ],
            ),
            if (printer.klippyStateMessage != null) ...[
              const Gap(6),
              Text(
                printer.klippyStateMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
            if (isPrinting || isPaused) ...[
              const Gap(16),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: printer.printProgress.clamp(0.0, 1.0),
                progressColor: isPaused ? cs.secondary : cs.primary,
                backgroundColor: cs.surfaceVariant,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
                animation: true,
                animateFromLastPercent: true,
              ),
              const Gap(6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(printer.printProgress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (printer.eta != null)
                    Text(
                      'ETA ${_formatEta(printer.eta!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatEta(int seconds) {
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _KlippyStatusDot extends StatelessWidget {
  const _KlippyStatusDot({required this.ready});
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ready ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _PrintStateBadge extends StatelessWidget {
  const _PrintStateBadge({required this.state});
  final String state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    IconData icon;

    switch (state) {
      case 'printing':
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        icon = Icons.print;
      case 'paused':
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        icon = Icons.pause_circle_outline;
      case 'complete':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_outline;
      case 'error':
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        icon = Icons.error_outline;
      default:
        bg = cs.surfaceVariant;
        fg = cs.onSurfaceVariant;
        icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const Gap(4),
          Text(
            state.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
