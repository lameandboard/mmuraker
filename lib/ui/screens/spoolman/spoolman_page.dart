// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/dto/spoolman/spoolman_dtos.dart';
import '../../../service/spoolman/spoolman_service.dart';
import '../../../util/feature_flags.dart';
import '../../components/common_widgets.dart';
import '../../components/spool_widget.dart';

/// Full Spoolman filament manager screen.
///
/// Lists all active spools with remaining filament, colour, material, vendor.
/// Lets the user set the active spool for the printer and update usage.
/// 100% free — FeatureFlags.spoolman is always true.
class SpoolmanPage extends ConsumerWidget {
  const SpoolmanPage({super.key, required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(FeatureFlags.spoolman, 'Spoolman must always be free');

    final spoolsAsync =
        ref.watch(spoolmanSpoolsProvider(machineId));
    final svc = ref.read(spoolmanServiceProvider(machineId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spoolman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(spoolmanSpoolsProvider(machineId)),
          ),
        ],
      ),
      body: spoolsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _SpoolmanError(
          error: e.toString(),
          onRetry: () =>
              ref.invalidate(spoolmanSpoolsProvider(machineId)),
        ),
        data: (spools) => spools.isEmpty
            ? const _EmptySpools()
            : _SpoolList(
                spools: spools,
                machineId: machineId,
                onSetActive: (spool) async {
                  try {
                    await svc.setActiveSpool(spool.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Active spool set to: ${spool.filament.name}'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to set spool: $e'),
                          backgroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSpoolDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Spool'),
      ),
    );
  }

  void _showAddSpoolDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Spool'),
        content: const Text(
          'To add spools, open the Spoolman web interface on your printer '
          'host (typically http://<printer-ip>:7912).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Spool list ─────────────────────────────────────────────────────────────────

class _SpoolList extends StatelessWidget {
  const _SpoolList({
    required this.spools,
    required this.machineId,
    required this.onSetActive,
  });

  final List<SpoolmanSpool> spools;
  final String machineId;
  final void Function(SpoolmanSpool spool) onSetActive;

  @override
  Widget build(BuildContext context) {
    // Sort: low filament first, then alphabetical.
    final sorted = [...spools]
      ..sort((a, b) {
        if (a.isLow != b.isLow) return a.isLow ? -1 : 1;
        return a.filament.name.compareTo(b.filament.name);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (_, i) => _SpoolCard(
        spool: sorted[i],
        onSetActive: () => onSetActive(sorted[i]),
      ),
    );
  }
}

// ── Spool card ─────────────────────────────────────────────────────────────────

class _SpoolCard extends StatelessWidget {
  const _SpoolCard({required this.spool, required this.onSetActive});

  final SpoolmanSpool spool;
  final VoidCallback onSetActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = spool.filament;
    final color =
        f.colorValue != null ? Color(f.colorValue!) : cs.primary;
    final pct = spool.remainingPercent ?? 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Coloured accent strip ───────────────────────────────────
          Container(
            height: 4,
            color: color,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Spool graphic ───────────────────────────────────
                SpoolWidget(
                  filamentColor: color,
                  remainingPercent: pct,
                  remainingGrams: spool.remainingWeight,
                  size: 88,
                ),
                const Gap(14),

                // ── Info column ─────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Use button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.name,
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(4),
                          FilledButton.tonal(
                            onPressed: onSetActive,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              minimumSize: const Size(0, 30),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Use',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const Gap(2),

                      // Vendor · material
                      Text(
                        [
                          if (f.vendor?.name.isNotEmpty == true)
                            f.vendor!.name,
                          if (f.material?.isNotEmpty == true) f.material!,
                        ].join(' · '),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color:
                                      cs.onSurface.withOpacity(0.6),
                                ),
                      ),
                      const Gap(8),

                      // Remaining fill bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 7,
                          backgroundColor: cs.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            spool.isLow ? cs.error : color,
                          ),
                        ),
                      ),
                      const Gap(4),

                      // Weight + low warning
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              spool.remainingWeight != null
                                  ? '${spool.remainingWeight!.toStringAsFixed(0)} g '
                                      '/ ${f.weight?.toStringAsFixed(0) ?? '?'} g'
                                  : 'Unknown weight',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: spool.isLow
                                        ? cs.error
                                        : cs.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ),
                          if (spool.isLow)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 11,
                                      color: cs.onErrorContainer),
                                  const Gap(2),
                                  Text(
                                    'Low',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: cs.onErrorContainer,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Optional: location
                      if (spool.location?.isNotEmpty == true) ...[
                        const Gap(4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 11,
                                color: cs.onSurface.withOpacity(0.45)),
                            const Gap(3),
                            Text(
                              spool.location!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        cs.onSurface.withOpacity(0.5),
                                  ),
                            ),
                          ],
                        ),
                      ],

                      // Recommended temps
                      if (f.settingsExtruderTemp != null ||
                          f.settingsBedTemp != null) ...[
                        const Gap(6),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (f.settingsExtruderTemp != null)
                              TemperatureChip(
                                label: 'Nozzle',
                                temp:
                                    f.settingsExtruderTemp!.toDouble(),
                              ),
                            if (f.settingsBedTemp != null)
                              TemperatureChip(
                                label: 'Bed',
                                temp: f.settingsBedTemp!.toDouble(),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty + error states ───────────────────────────────────────────────────────

class _EmptySpools extends StatelessWidget {
  const _EmptySpools();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const Gap(12),
          Text('No spools found',
              style: Theme.of(context).textTheme.titleMedium),
          const Gap(6),
          Text(
            'Add spools in the Spoolman web interface\n'
            '(http://<printer-ip>:7912)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SpoolmanError extends StatelessWidget {
  const _SpoolmanError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 48,
                color: Theme.of(context).colorScheme.error.withOpacity(0.7)),
            const Gap(12),
            Text('Could not connect to Spoolman',
                style: Theme.of(context).textTheme.titleMedium),
            const Gap(6),
            Text(
              'Make sure Spoolman is running on your printer host.\n\n$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
