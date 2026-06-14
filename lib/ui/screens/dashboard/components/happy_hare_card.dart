// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/dto/machine/mmu/happy_hare_state.dart';
import '../../../../service/moonraker/printer_service.dart';
import '../../../components/common_widgets.dart';

/// Full Happy Hare MMU control panel.
///
/// Displayed on the dashboard when Happy Hare is detected. Provides:
///  - State banner (idle / busy / paused / error)
///  - Gate map (all tools with material, colour, status)
///  - Tool selection (Tx buttons)
///  - Load / Unload / Eject / Recover / Pause / Resume actions
///  - Endless spool group visualisation
///  - Filament position indicator
///  - Print statistics
class HappyHareCard extends ConsumerWidget {
  const HappyHareCard({
    super.key,
    required this.machineId,
    required this.state,
  });

  final String machineId;
  final HappyHareState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(printerServiceProvider(machineId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Status header ────────────────────────────────────────────────
        const SectionHeader('Happy Hare MMU'),
        _MmuStateBanner(state: state, onClearError: () => svc.sendGcode('MMU_CLEAR_GATE_MAP')),

        // ── Filament position strip ──────────────────────────────────────
        if (!state.isIdle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _FilamentPositionStrip(position: state.filamentPosition),
          ),

        // ── Gate map ────────────────────────────────────────────────────
        if (state.numGates > 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: _GateMap(
              state: state,
              onSelectTool: (t) => svc.changeTool(t),
            ),
          ),

        // ── Action buttons ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _ActionBar(state: state, svc: svc),
        ),

        // ── Endless spool groups ─────────────────────────────────────────
        if (state.endlessSpoolEnabled && state.endlessSpoolGroups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: _EndlessSpoolRow(state: state),
          ),

        // ── Print stats ──────────────────────────────────────────────────
        if (state.printStats != null && state.isPrinting)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _PrintStats(stats: state.printStats!),
          ),
      ],
    );
  }
}

// ── State banner ──────────────────────────────────────────────────────────────

class _MmuStateBanner extends StatelessWidget {
  const _MmuStateBanner({required this.state, required this.onClearError});
  final HappyHareState state;
  final VoidCallback onClearError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (state.hasError) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
      icon = Icons.error_outline;
      label = 'Error: ${state.lastError}';
    } else if (state.isPaused) {
      bg = cs.tertiaryContainer;
      fg = cs.onTertiaryContainer;
      icon = Icons.pause_circle_outline;
      label = state.stateDisplay;
    } else if (state.isBusy) {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
      icon = Icons.sync;
      label = state.stateDisplay;
    } else {
      bg = cs.surfaceVariant;
      fg = cs.onSurfaceVariant;
      icon = Icons.check_circle_outline;
      label = state.stateDisplay;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          state.isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fg))
              : Icon(icon, size: 16, color: fg),
          const Gap(8),
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: fg)),
          ),
          if (state.hasError)
            TextButton(
              onPressed: onClearError,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}

// ── Gate map grid ─────────────────────────────────────────────────────────────

class _GateMap extends StatelessWidget {
  const _GateMap({required this.state, required this.onSelectTool});
  final HappyHareState state;
  final void Function(int tool) onSelectTool;

  @override
  Widget build(BuildContext context) {
    final gates = state.gates;
    final selected = state.toolSelected;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(
        gates.isEmpty ? state.numGates : gates.length,
        (i) {
          final gate = gates.length > i ? gates[i] : null;
          final isSelected = selected == i;
          final isEmpty = (gate?.status ?? '').trim().toLowerCase() == 'empty';
          final color = _parseColor(gate?.color);

          return GestureDetector(
            onTap: isEmpty ? null : () => onSelectTool(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Colour dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color ??
                          (isEmpty
                              ? Colors.grey.withOpacity(0.3)
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.5)),
                      border: Border.all(
                        color:
                            Theme.of(context).colorScheme.outline.withOpacity(0.4),
                      ),
                    ),
                    child: isEmpty
                        ? Icon(Icons.close,
                            size: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3))
                        : null,
                  ),
                  const Gap(4),
                  // Tool label
                  Text(
                    'T$i',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isEmpty
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.35)
                              : null,
                        ),
                  ),
                  // Material label
                  if (gate?.material.isNotEmpty == true)
                    Text(
                      gate!.material,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFFCCCCCC);
    }
    return null;
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state, required this.svc});
  final HappyHareState state;
  final dynamic svc; // PrinterService

  @override
  Widget build(BuildContext context) {
    final disabled = state.isBusy;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (state.isPaused) ...[
          _MmuButton(
            label: 'Resume',
            icon: Icons.play_arrow,
            color: Colors.green,
            disabled: false,
            onTap: () => svc.sendGcode('MMU_RESUME'),
          ),
          _MmuButton(
            label: 'Recover',
            icon: Icons.build,
            disabled: false,
            onTap: () => svc.sendGcode('MMU_RECOVER'),
          ),
        ] else ...[
          _MmuButton(
            label: 'Load',
            icon: Icons.arrow_downward,
            disabled: disabled,
            onTap: () => svc.sendGcode('MMU_LOAD'),
          ),
          _MmuButton(
            label: 'Unload',
            icon: Icons.arrow_upward,
            disabled: disabled,
            onTap: () => svc.sendGcode('MMU_UNLOAD'),
          ),
          _MmuButton(
            label: 'Eject',
            icon: Icons.eject,
            disabled: disabled,
            onTap: () => svc.sendGcode('MMU_EJECT'),
          ),
          _MmuButton(
            label: 'Home',
            icon: Icons.home,
            disabled: disabled,
            onTap: () => svc.sendGcode('MMU_HOME'),
          ),
        ],
        if (!state.isPaused && !state.isIdle)
          _MmuButton(
            label: 'Pause',
            icon: Icons.pause,
            disabled: false,
            onTap: () => svc.sendGcode('MMU_PAUSE'),
          ),
        _MmuButton(
          label: 'Servo Up',
          icon: Icons.expand_less,
          disabled: disabled,
          onTap: () => svc.sendGcode('MMU_SERVO POS=up'),
        ),
        _MmuButton(
          label: 'Servo Down',
          icon: Icons.expand_more,
          disabled: disabled,
          onTap: () => svc.sendGcode('MMU_SERVO POS=down'),
        ),
        if (state.isBypass)
          _MmuButton(
            label: 'Exit Bypass',
            icon: Icons.alt_route,
            disabled: disabled,
            onTap: () => svc.sendGcode('MMU_SELECT_BYPASS'),
          )
        else
          _MmuButton(
            label: 'Bypass',
            icon: Icons.alt_route,
            disabled: disabled,
            onTap: () => svc.sendGcode('MMU_SELECT_BYPASS'),
          ),
      ],
    );
  }
}

class _MmuButton extends StatelessWidget {
  const _MmuButton({
    required this.label,
    required this.icon,
    required this.disabled,
    required this.onTap,
    this.color,
  });
  final String label;
  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: disabled ? null : onTap,
    );
  }
}

// ── Filament position strip ───────────────────────────────────────────────────

class _FilamentPositionStrip extends StatelessWidget {
  const _FilamentPositionStrip({required this.position});
  final String position;

  static const _steps = [
    'unloaded',
    'homed_hub',
    'homed_extruder',
    'extruder_entry',
    'loaded',
    'at_toolhead',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentIdx = _steps.indexOf(position);

    return Row(
      children: _steps.asMap().entries.map((e) {
        final active = e.key <= currentIdx && currentIdx >= 0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Endless spool row ─────────────────────────────────────────────────────────

class _EndlessSpoolRow extends StatelessWidget {
  const _EndlessSpoolRow({required this.state});
  final HappyHareState state;

  @override
  Widget build(BuildContext context) {
    final groups = <int, List<int>>{};
    state.endlessSpoolGroups.forEach((tool, group) {
      groups.putIfAbsent(group, () => []).add(tool);
    });

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          'Endless Spool Groups:',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        ...groups.entries.map((e) => Chip(
              label: Text(
                'Group ${e.key}: ${e.value.map((t) => 'T$t').join(', ')}',
                style: const TextStyle(fontSize: 10),
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
      ],
    );
  }
}

// ── Print statistics ──────────────────────────────────────────────────────────

class _PrintStats extends StatelessWidget {
  const _PrintStats({required this.stats});
  final HappyHarePrintStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        _Stat('Tool changes', '${stats.toolChanges}'),
        _Stat('Total changes', '${stats.totalTool_changes}'),
        _Stat('Load retries', '${stats.loadRetries}'),
        if (stats.failedLoadRetries > 0)
          _Stat('Failed retries', '${stats.failedLoadRetries}',
              color: Theme.of(context).colorScheme.error),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
