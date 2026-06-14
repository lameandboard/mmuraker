// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/dto/machine/mmu/afc_state.dart';
import '../../../../data/dto/spoolman/spoolman_dtos.dart';
import '../../../../service/moonraker/printer_service.dart';
import '../../../../service/spoolman/spoolman_service.dart';
import '../../../components/common_widgets.dart';
import '../../../components/spool_widget.dart';

/// AFC (Automatic Filament Changer) dashboard card.
///
/// Shows all AFC lanes with filament presence indicators, active lane,
/// hub + buffer status, and per-lane load/unload actions.
class AfcCard extends ConsumerWidget {
  const AfcCard({
    super.key,
    required this.machineId,
    required this.state,
  });

  final String machineId;
  final AfcState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(printerServiceProvider(machineId));

    // Watch Spoolman spools — shows spool graphic per lane if IDs are linked.
    final spoolsAsync = ref.watch(spoolmanSpoolsProvider(machineId));
    final spools = spoolsAsync.valueOrNull ?? [];
    // Build a quick lookup by spool ID.
    final spoolById = {for (final s in spools) s.id: s};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('AFC Filament Changer'),

        // ── Error banner ─────────────────────────────────────────────────
        if (state.hasError)
          _AfcErrorBanner(error: state.lastError),

        // ── Status row: hub + buffer ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _AfcStatusChip(
                label: 'AFC',
                value: state.status,
                isOk: state.status == 'ready',
              ),
              const Gap(8),
              if (state.hub != null)
                _AfcStatusChip(
                  label: 'Hub',
                  value: state.hub!.filamentPresent ? 'loaded' : 'clear',
                  isOk: !state.hub!.filamentPresent,
                ),
              const Gap(8),
              if (state.buffer != null)
                _AfcStatusChip(
                  label: 'Buffer',
                  value: state.buffer!.state,
                  isOk: state.buffer!.state == 'trailing',
                ),
            ],
          ),
        ),

        // ── Lane list ────────────────────────────────────────────────────
        if (state.lanes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: _LaneGrid(
              state: state,
              spoolById: spoolById,
              onLoad: (lane) => svc.sendGcode('AFC_LOAD LANE=$lane'),
              onUnload: (lane) => svc.sendGcode('AFC_UNLOAD LANE=$lane'),
              onEject: (lane) => svc.sendGcode('AFC_EJECT LANE=$lane'),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No AFC lanes detected.')),
          ),
      ],
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────────

class _AfcErrorBanner extends StatelessWidget {
  const _AfcErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: cs.onErrorContainer),
          const Gap(8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _AfcStatusChip extends StatelessWidget {
  const _AfcStatusChip({
    required this.label,
    required this.value,
    required this.isOk,
  });
  final String label;
  final String value;
  final bool isOk;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOk
            ? Colors.green.withOpacity(0.15)
            : cs.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOk
              ? Colors.green.withOpacity(0.4)
              : cs.error.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOk ? Colors.green : cs.error,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Lane grid ─────────────────────────────────────────────────────────────────

class _LaneGrid extends StatelessWidget {
  const _LaneGrid({
    required this.state,
    required this.spoolById,
    required this.onLoad,
    required this.onUnload,
    required this.onEject,
  });
  final AfcState state;
  final Map<int, SpoolmanSpool> spoolById;
  final void Function(String lane) onLoad;
  final void Function(String lane) onUnload;
  final void Function(String lane) onEject;

  @override
  Widget build(BuildContext context) {
    final lanes = state.lanes.entries.toList();

    return Column(
      children: lanes.map((entry) {
        final name = entry.key;
        final lane = entry.value;
        final isActive = state.activeLane == name;
        // Look up the linked Spoolman spool if the lane has a spoolId.
        final spool = lane.spoolId >= 0 ? spoolById[lane.spoolId] : null;

        return _LaneTile(
          name: name,
          lane: lane,
          isActive: isActive,
          spool: spool,
          onLoad: () => onLoad(name),
          onUnload: () => onUnload(name),
          onEject: () => onEject(name),
        );
      }).toList(),
    );
  }
}

class _LaneTile extends StatelessWidget {
  const _LaneTile({
    required this.name,
    required this.lane,
    required this.isActive,
    required this.onLoad,
    required this.onUnload,
    required this.onEject,
    this.spool,
  });
  final String name;
  final AfcLaneStatus lane;
  final bool isActive;
  final VoidCallback onLoad;
  final VoidCallback onUnload;
  final VoidCallback onEject;
  /// Spoolman spool linked to this lane, if available.
  final SpoolmanSpool? spool;

  static Color? _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFFCCCCCC);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Colour: prefer AFC lane colour, fall back to Spoolman filament colour.
    final Color? color = lane.color.isNotEmpty
        ? _parseColor(lane.color)
        : (spool?.filament.colorValue != null
            ? Color(spool!.filament.colorValue!)
            : null);

    final isBusy =
        lane.state == 'loading' || lane.state == 'unloading' || lane.state == 'ejecting';

    // Material: prefer lane, fall back to Spoolman filament material.
    final material = lane.material.isNotEmpty
        ? lane.material
        : (spool?.filament.material ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isActive ? cs.primaryContainer.withOpacity(0.4) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Spool graphic (if Spoolman data available) ──────────────
            if (spool != null)
              SpoolWidget(
                filamentColor: color ?? cs.primary,
                remainingPercent: spool!.remainingPercent ?? 0,
                remainingGrams: spool!.remainingWeight,
                size: 52,
              )
            else
              // Fallback: coloured presence dot
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lane.filamentPresent
                      ? (color ?? cs.primary)
                      : cs.surfaceVariant,
                  border: Border.all(color: cs.outline.withOpacity(0.4)),
                ),
              ),

            const Gap(10),

            // ── Lane info ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lane name + Active badge
                  Row(
                    children: [
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                      if (isActive) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Active',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: cs.onPrimary, fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Material · state · extruder
                  Text(
                    [
                      if (material.isNotEmpty) material,
                      _formatState(lane.state),
                      if (lane.extruderPresent) 'at extruder',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: lane.state == 'error'
                              ? cs.error
                              : cs.onSurface.withOpacity(0.6),
                        ),
                  ),

                  // Spoolman extra info: vendor · filament name · low warning
                  if (spool != null) ...[
                    const Gap(2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              if (spool!.filament.vendor?.name.isNotEmpty == true)
                                spool!.filament.vendor!.name,
                              spool!.filament.name,
                            ].join(' '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (spool!.isLow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 10,
                                    color: cs.onErrorContainer),
                                const Gap(2),
                                Text(
                                  'Low',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: cs.onErrorContainer,
                                        fontSize: 9,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Load / Unload actions ───────────────────────────────────
            if (isBusy)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              if (!lane.filamentPresent)
                _SmallButton(
                  icon: Icons.arrow_downward,
                  tooltip: 'Load',
                  onTap: onLoad,
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SmallButton(
                      icon: Icons.arrow_upward,
                      tooltip: 'Unload',
                      onTap: onUnload,
                    ),
                    _SmallButton(
                      icon: Icons.eject_outlined,
                      tooltip: 'Eject',
                      onTap: onEject,
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatState(String state) {
    return switch (state) {
      'loaded' => 'Loaded',
      'unloaded' => 'Unloaded',
      'loading' => 'Loading…',
      'unloading' => 'Unloading…',
      'ejecting' => 'Ejecting…',
      'error' => 'Error',
      _ => state,
    };
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}
