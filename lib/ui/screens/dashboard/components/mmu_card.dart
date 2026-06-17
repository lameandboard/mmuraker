// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../data/dto/machine/mmu/mmu_state.dart';
import '../../../../data/dto/machine/printer.dart';
import '../../../../service/moonraker/printer_service.dart';
import '../../../../util/app_constants.dart';
import '../../../components/common_widgets.dart';

/// MMU tool selector and status card.
///
/// Shown on the dashboard only when [Printer.hasMmu] is true.
/// All MMU controls are always free — no paywall.  See [FeatureFlags.mmuDashboardCard].
///
/// Architecture note: extends the extruder card concept from mobileraker with
/// explicit MMU tool selection.  Tool changes are sent as T0/T1/… G-code which
/// is compatible with Happy Hare, ERCF, Trad Rack, and most other MMU firmwares.
class MmuCard extends StatelessWidget {
  const MmuCard({
    super.key,
    required this.printer,
    required this.printerService,
  });

  final Printer printer;
  final PrinterService printerService;

  @override
  Widget build(BuildContext context) {
    final mmu = printer.mmuState;
    if (mmu == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MmuHeader(mmu: mmu),
            const Gap(12),
            if (mmu.error != null && mmu.error!.isNotEmpty)
              _MmuErrorBanner(error: mmu.error!),
            const Gap(4),
            _ToolGrid(
              tools: mmu.tools,
              onToolSelected: (tool) =>
                  printerService.selectMmuTool(tool.index),
              busy: mmu.busy,
            ),
            const Gap(12),
            _MmuActions(mmu: mmu, printerService: printerService),
          ],
        ),
      ),
    );
  }
}

class _MmuHeader extends StatelessWidget {
  const _MmuHeader({required this.mmu});
  final MmuState mmu;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        const SectionHeader('MMU'),
        const Spacer(),
        if (mmu.busy)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: mmu.error != null ? cs.error : Colors.green,
          ),
        const Gap(6),
        Text(
          mmu.printState,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Gap(12),
        Text(
          '${mmu.toolCount} tools',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MmuErrorBanner extends StatelessWidget {
  const _MmuErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: cs.onErrorContainer),
          const Gap(8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of tool selector buttons — one per MMU gate/tool.
class _ToolGrid extends StatelessWidget {
  const _ToolGrid({
    required this.tools,
    required this.onToolSelected,
    required this.busy,
  });

  final List<MmuTool> tools;
  final void Function(MmuTool) onToolSelected;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) {
      return const Text('No tools detected.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tools.map((tool) => _ToolChip(
            tool: tool,
            onTap: busy ? null : () => onToolSelected(tool),
          )).toList(),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.tool, this.onTap});
  final MmuTool tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filamentColor = _parseColor(tool.color);
    final effectiveColor = filamentColor ?? _gateStateColor(tool.gateState, cs);
    final isActive = tool.isActive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : cs.surfaceVariant,
          border: Border.all(
            color: isActive ? cs.primary : cs.outline,
            width: isActive ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor,
                border: Border.all(
                  color: cs.outline.withOpacity(0.4),
                ),
              ),
            ),
            const Gap(4),
            Text(
              'T${tool.index}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? cs.primary : cs.onSurfaceVariant,
                  ),
            ),
            Icon(
              _gateStateIcon(tool.gateState),
              size: 12,
              color: cs.onSurfaceVariant.withOpacity(0.75),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  Color _gateStateColor(MmuGateState state, ColorScheme cs) {
    return switch (state) {
      MmuGateState.loaded => AppConstants.defaultFilamentColor,
      MmuGateState.available => cs.tertiaryContainer,
      MmuGateState.empty => cs.surfaceContainerHighest,
      MmuGateState.unknown => cs.surfaceContainerHighest,
    };
  }

  IconData _gateStateIcon(MmuGateState state) {
    return switch (state) {
      MmuGateState.loaded => Icons.check_circle_outline,
      MmuGateState.available => Icons.radio_button_checked,
      MmuGateState.empty => Icons.remove_circle_outline,
      MmuGateState.unknown => Icons.help_outline,
    };
  }
}

/// Load / unload / reset buttons for the active MMU tool.
class _MmuActions extends StatelessWidget {
  const _MmuActions({required this.mmu, required this.printerService});
  final MmuState mmu;
  final PrinterService printerService;

  @override
  Widget build(BuildContext context) {
    final hasActive = mmu.activeTool >= 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: hasActive && !mmu.busy
              ? () => printerService.runMacro('MMU_LOAD')
              : null,
          icon: const Icon(Icons.arrow_downward, size: 16),
          label: const Text('Load'),
        ),
        OutlinedButton.icon(
          onPressed: hasActive && !mmu.busy
              ? () => printerService.runMacro('MMU_EJECT')
              : null,
          icon: const Icon(Icons.arrow_upward, size: 16),
          label: const Text('Eject'),
        ),
        OutlinedButton.icon(
          onPressed: !mmu.busy
              ? () => printerService.runMacro('MMU_RESET')
              : null,
          icon: const Icon(Icons.restart_alt, size: 16),
          label: const Text('Reset'),
        ),
        if (mmu.error != null && mmu.error!.isNotEmpty)
          FilledButton.icon(
            onPressed: () => printerService.runMacro('MMU_CLEAR_ERRORS'),
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear Error'),
          ),
      ],
    );
  }
}
