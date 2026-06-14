// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/dto/machine/printer.dart';
import '../../../data/model/machine.dart';
import '../../../service/machine_service.dart';
import '../../../service/moonraker/printer_service.dart';
import '../../../service/vpn_service.dart';
import '../../components/common_widgets.dart';
import '../console/console_page.dart';
import 'components/afc_card.dart';
import 'components/bed_mesh_card.dart';
import 'components/files_pane.dart';
import 'components/happy_hare_card.dart';
import 'components/motion_systems_card.dart';
import 'components/printer_status_card.dart';
import 'components/control_extruder_card.dart';
import 'components/mmu_card.dart';
import 'components/sensor_overview_card.dart';
import 'components/speed_flow_card.dart';
import 'components/temperature_card.dart';
import 'components/webcam_card.dart';
import 'components/zoffset_card.dart';

/// Main dashboard for a single printer.
///
/// Shows real-time printer state, temperature, extruder controls, and — when
/// an MMU is detected — the full MMU tool selector card.
///
/// All cards are always accessible: no feature is gated behind a paywall.
enum PrinterSection { dashboard, files, console }

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({
    super.key,
    required this.machineId,
    this.initialSection = PrinterSection.dashboard,
  });

  final String machineId;
  final PrinterSection initialSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineService = ref.watch(machineServiceProvider);
    final machines = ref.watch(machineListProvider).valueOrNull ?? machineService.machines;
    final machine = _findMachine(machines, machineId) ?? machineService.findById(machineId);

    // Connect on first build, disconnect on dispose.
    // IMPORTANT: capture every service reference *before* returning the
    // cleanup closure.  Calling `ref.read(...)` inside the closure is
    // unsafe because `ref` may have been disposed by the time the cleanup
    // runs, which would throw "Cannot use ref after the widget was disposed."
    useEffect(() {
      if (machine == null) return null;
      final service = ref.read(printerServiceProvider(machineId));
      service.connect(machine.wsUrl, apiKey: machine.apiKey);

      // Attach VPN auto-connect – capture vpnService now, not in the closure.
      final vpnService = ref.read(vpnServiceProvider);
      vpnService.attachToMachine(
        httpUrl: machine.httpUrl,
        vpnConfig: machine.vpnConfig,
      );

      return () {
        service.disconnect();
        vpnService.detach();
      };
    }, [machineId]);

    if (machine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Text(
            machines.isEmpty ? 'Loading printer…' : 'Printer not found.',
          ),
        ),
      );
    }

    final printerService = ref.watch(printerServiceProvider(machineId));
    final vpnState = ref.watch(vpnServiceProvider).state;

    return StreamBuilder<Printer>(
      stream: printerService.printerStream,
      initialData: printerService.current,
      builder: (context, snapshot) {
        final printer = snapshot.data ?? const Printer();
        final availableObjects = printer.availableObjects;
        final gcodeMove = printerService.objectData('gcode_move');
        final bedMesh = printerService.objectData('bed_mesh');
        final probe = printerService.objectData('probe') ??
            printerService.objectData('bltouch');
        final zTilt = printerService.objectData('z_tilt');
        final quadGantry = printerService.objectData('quad_gantry_level');
        final thermalSensors = printerService.thermalSensors;
        final binarySensors = printerService.binarySensors;
        final afcState = printerService.afcState;
        final happyHareState = printerService.happyHareState;
        final effectiveWebcamUrl =
            machine.webcamUrl ?? printerService.detectedWebcamUrl;
        double? zOffset;
        final homingOrigin = gcodeMove?['homing_origin'];
        if (homingOrigin is List && homingOrigin.length > 2) {
          final rawZ = homingOrigin[2];
          if (rawZ is num) {
            zOffset = rawZ.toDouble();
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${machine.name} • ${_sectionLabel(initialSection)}'),
            actions: [
              if (machines.length > 1)
                _PrinterSwitcher(
                  machines: machines,
                  currentMachineId: machineId,
                ),
              VpnStatusBadge(isActive: vpnState == VpnTunnelState.connected),
              const Gap(8),
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          drawer: _PrinterDrawer(
            machine: machine,
            currentSection: initialSection,
            onSelectSection: (section) {
              Navigator.of(context).pop();
              if (section == initialSection) return;
              context.pushReplacement(_sectionRoute(machineId, section));
            },
            onOpenSpoolman: () {
              Navigator.of(context).pop();
              context.push('/dashboard/$machineId/spoolman');
            },
            onOpenOverview: () {
              Navigator.of(context).pop();
              context.pushReplacement('/');
            },
            onOpenSettings: () {
              Navigator.of(context).pop();
              context.push('/settings');
            },
          ),
          body: switch (initialSection) {
            PrinterSection.dashboard => _DashboardHome(
                machine: machine,
                printer: printer,
                printerService: printerService,
                availableObjects: availableObjects,
                bedMesh: bedMesh,
                probe: probe,
                zTilt: zTilt,
                quadGantry: quadGantry,
                thermalSensors: thermalSensors,
                binarySensors: binarySensors,
                afcState: afcState,
                happyHareState: happyHareState,
                effectiveWebcamUrl: effectiveWebcamUrl,
                zOffset: zOffset,
              ),
            PrinterSection.files => FilesPane(
                printerService: printerService,
                activeFile:
                    printerService.objectData('print_stats')?['filename']?.toString(),
              ),
            PrinterSection.console => ConsolePane(machineId: machineId),
          },
          floatingActionButton: initialSection == PrinterSection.dashboard
              ? _PrintFab(
                  printer: printer,
                  printerService: printerService,
                )
              : null,
        );
      },
    );
  }

  String _sectionLabel(PrinterSection section) {
    return switch (section) {
      PrinterSection.dashboard => 'Dashboard',
      PrinterSection.files => 'Files',
      PrinterSection.console => 'Console',
    };
  }

  String _sectionRoute(String machineId, PrinterSection section) {
    return switch (section) {
      PrinterSection.dashboard => '/dashboard/$machineId',
      PrinterSection.files => '/dashboard/$machineId/files',
      PrinterSection.console => '/dashboard/$machineId/console',
    };
  }

  Machine? _findMachine(List<Machine> machines, String id) {
    for (final machine in machines) {
      if (machine.id == id) return machine;
    }
    return null;
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

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    required this.machine,
    required this.printer,
    required this.printerService,
    required this.availableObjects,
    required this.bedMesh,
    required this.probe,
    required this.zTilt,
    required this.quadGantry,
    required this.thermalSensors,
    required this.binarySensors,
    required this.afcState,
    required this.happyHareState,
    required this.effectiveWebcamUrl,
    required this.zOffset,
  });

  final Machine machine;
  final Printer printer;
  final PrinterService printerService;
  final List<String> availableObjects;
  final Map<String, dynamic>? bedMesh;
  final Map<String, dynamic>? probe;
  final Map<String, dynamic>? zTilt;
  final Map<String, dynamic>? quadGantry;
  final List<MapEntry<String, Map<String, dynamic>>> thermalSensors;
  final List<MapEntry<String, Object?>> binarySensors;
  final dynamic afcState;
  final dynamic happyHareState;
  final String? effectiveWebcamUrl;
  final double? zOffset;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => printerService.connect(
        machine.wsUrl,
        apiKey: machine.apiKey,
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          PrinterStatusCard(printer: printer),
          const Gap(8),
          WebcamCard(
            machine: machine,
            webcamUrl: effectiveWebcamUrl,
            isAutodetected:
                machine.webcamUrl == null &&
                printerService.detectedWebcamUrl != null,
          ),
          const Gap(8),
          TemperatureCard(
            printer: printer,
            onSetExtruderTemp: (idx, temp) =>
                printerService.setExtruderTemp(idx, temp),
            onSetBedTemp: (temp) => printerService.setBedTemp(temp),
          ),
          const Gap(8),
          MotionSystemsCard(
            printer: printer,
            printerService: printerService,
            availableObjects: availableObjects,
            bedMesh: bedMesh,
            probe: probe,
            quadGantryLevel: quadGantry,
            zTilt: zTilt,
          ),
          if (bedMesh != null || availableObjects.contains('bed_mesh')) ...[
            const Gap(8),
            BedMeshCard(
              printerService: printerService,
              bedMesh: bedMesh,
            ),
          ],
          if (zOffset != null || probe != null) ...[
            const Gap(8),
            ZOffsetCard(
              printerService: printerService,
              zOffset: zOffset,
              printState: printer.printState,
              hasProbe: probe != null,
            ),
          ],
          if (thermalSensors.isNotEmpty || binarySensors.isNotEmpty) ...[
            const Gap(8),
            SensorOverviewCard(
              thermalSensors: thermalSensors,
              binarySensors: binarySensors,
            ),
          ],
          ControlExtruderCard(
            printer: printer,
            printerService: printerService,
          ),
          const Gap(8),
          SpeedFlowCard(
            printerService: printerService,
            printState: printer.printState,
            speedFactor: printer.toolhead.speedFactor,
            extrudeFactor: printer.toolhead.extrudeFactor,
          ),
          if (afcState != null) ...[
            const Gap(8),
            AfcCard(machineId: machine.id, state: afcState),
          ] else if (happyHareState != null) ...[
            const Gap(8),
            HappyHareCard(machineId: machine.id, state: happyHareState),
          ] else if (printer.hasMmu) ...[
            const Gap(8),
            MmuCard(
              printer: printer,
              printerService: printerService,
            ),
          ],
          const Gap(80),
        ],
      ),
    );
  }
}

class _PrinterDrawer extends StatelessWidget {
  const _PrinterDrawer({
    required this.machine,
    required this.currentSection,
    required this.onSelectSection,
    required this.onOpenSpoolman,
    required this.onOpenOverview,
    required this.onOpenSettings,
  });

  final Machine machine;
  final PrinterSection currentSection;
  final ValueChanged<PrinterSection> onSelectSection;
  final VoidCallback onOpenSpoolman;
  final VoidCallback onOpenOverview;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'mmuraker',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Gap(12),
                  Text(
                    machine.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Gap(4),
                  Text(
                    machine.httpUrl,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('PRINTER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: currentSection == PrinterSection.dashboard,
              onTap: () => onSelectSection(PrinterSection.dashboard),
            ),
            _DrawerTile(
              icon: Icons.folder_outlined,
              label: 'Files',
              selected: currentSection == PrinterSection.files,
              onTap: () => onSelectSection(PrinterSection.files),
            ),
            _DrawerTile(
              icon: Icons.terminal_outlined,
              label: 'Console',
              selected: currentSection == PrinterSection.console,
              onTap: () => onSelectSection(PrinterSection.console),
            ),
            _DrawerTile(
              icon: Icons.inventory_2_outlined,
              label: 'Spoolman',
              selected: false,
              onTap: onOpenSpoolman,
            ),
            const Divider(height: 24),
            _DrawerTile(
              icon: Icons.print_outlined,
              label: 'Printers',
              selected: false,
              onTap: onOpenOverview,
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: false,
              onTap: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      selected: selected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
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
