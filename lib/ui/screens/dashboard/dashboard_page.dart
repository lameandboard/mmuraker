// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dto/machine/printer.dart';
import '../../../data/model/machine.dart';
import '../../../service/machine_service.dart';
import '../../../service/moonraker/printer_service.dart';
import '../../../service/vpn_service.dart';
import '../../components/common_widgets.dart';
import '../../components/error_card.dart';
import 'components/printer_status_card.dart';
import 'components/temperature_card.dart';
import 'components/control_extruder_card.dart';
import 'components/mmu_card.dart';

/// Main dashboard for a single printer.
///
/// Shows real-time printer state, temperature, extruder controls, and — when
/// an MMU is detected — the full MMU tool selector card.
///
/// All cards are always accessible: no feature is gated behind a paywall.
class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key, required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineService = ref.watch(machineServiceProvider);
    final machines = machineService.machines;
    final machine = machineService.findById(machineId);

    // Connect on first build, disconnect on dispose.
    useEffect(() {
      if (machine == null) return null;
      final service = ref.read(printerServiceProvider(machineId));
      service.connect(machine.wsUrl, apiKey: machine.apiKey);

      // Attach VPN auto-connect.
      ref.read(vpnServiceProvider).attachToMachine(
            httpUrl: machine.httpUrl,
            vpnConfig: machine.vpnConfig,
          );

      return () {
        service.disconnect();
        ref.read(vpnServiceProvider).detach();
      };
    }, [machineId]);

    if (machine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Printer not found.')),
      );
    }

    final printerService = ref.watch(printerServiceProvider(machineId));
    final vpnState = ref.watch(vpnServiceProvider).state;

    return StreamBuilder<Printer>(
      stream: printerService.printerStream,
      initialData: printerService.current,
      builder: (context, snapshot) {
        final printer = snapshot.data ?? const Printer();
        return Scaffold(
          appBar: AppBar(
            title: Text(machine.name),
            actions: [
              if (machines.length > 1)
                _PrinterSwitcher(
                  machines: machines,
                  currentMachineId: machineId,
                ),
              VpnStatusBadge(isActive: vpnState == VpnTunnelState.connected),
              const Gap(8),
              IconButton(
                icon: const Icon(Icons.terminal_outlined),
                tooltip: 'G-code Console',
                onPressed: () =>
                    context.push('/dashboard/$machineId/console'),
              ),
              IconButton(
                icon: const Icon(Icons.emergency_outlined),
                tooltip: 'Emergency Stop',
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmEmergencyStop(
                  context,
                  printerService,
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => printerService.connect(
              machine.wsUrl,
              apiKey: machine.apiKey,
            ),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                PrinterStatusCard(printer: printer),
                const Gap(8),
                TemperatureCard(
                  printer: printer,
                  onSetExtruderTemp: (idx, temp) =>
                      printerService.setExtruderTemp(idx, temp),
                  onSetBedTemp: (temp) => printerService.setBedTemp(temp),
                ),
                const Gap(8),
                ControlExtruderCard(
                  printer: printer,
                  printerService: printerService,
                ),
                if (printer.hasMmu) ...[
                  const Gap(8),
                  MmuCard(
                    printer: printer,
                    printerService: printerService,
                  ),
                ],
                const Gap(80), // Space above FAB.
              ],
            ),
          ),
          floatingActionButton: _PrintFab(
            printer: printer,
            printerService: printerService,
          ),
        );
      },
    );
  }

  Future<void> _confirmEmergencyStop(
    BuildContext context,
    PrinterService service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Stop?'),
        content: const Text(
          'This will immediately halt all motion and disable heaters.\n'
          'The printer will need to be restarted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('STOP'),
          ),
        ],
      ),
    );
    if (confirmed == true) await service.emergencyStop();
  }
}

class _PrinterSwitcher extends StatelessWidget {
  const _PrinterSwitcher({
    required this.machines,
    required this.currentMachineId,
  });

  final List<Machine> machines;
  final String currentMachineId;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Switch printer',
      icon: const Icon(Icons.sync_alt_outlined),
      onSelected: (nextMachineId) {
        if (nextMachineId == currentMachineId) return;
        context.pushReplacement('/dashboard/$nextMachineId');
      },
      itemBuilder: (context) => [
        for (final machine in machines)
          PopupMenuItem<String>(
            value: machine.id,
            child: Row(
              children: [
                Expanded(child: Text(machine.name)),
                if (machine.id == currentMachineId) ...[
                  const Gap(8),
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PrintFab extends StatelessWidget {
  const _PrintFab({required this.printer, required this.printerService});
  final Printer printer;
  final PrinterService printerService;

  @override
  Widget build(BuildContext context) {
    return switch (printer.printState) {
      'printing' => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'fab_pause',
              onPressed: printerService.pausePrint,
              tooltip: 'Pause',
              child: const Icon(Icons.pause),
            ),
            const Gap(12),
            FloatingActionButton(
              heroTag: 'fab_cancel',
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              onPressed: printerService.cancelPrint,
              tooltip: 'Cancel',
              child: const Icon(Icons.stop),
            ),
          ],
        ),
      'paused' => FloatingActionButton.extended(
          heroTag: 'fab_resume',
          onPressed: printerService.resumePrint,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Resume'),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
