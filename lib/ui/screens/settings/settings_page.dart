// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/model/machine.dart';
import '../../../routing/app_router.dart';
import '../../../service/machine_service.dart';
import '../../../util/app_constants.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _connectToPrinter(String machineId) async {
    await context.push('${Routes.dashboard}/$machineId');
  }

  Future<void> _openPrinterEditor({String? machineId}) async {
    if (machineId == null) {
      await context.push(Routes.addPrinter);
    } else {
      await context.push('${Routes.editPrinter}/$machineId');
    }
  }

  Future<void> _openNotificationSettings(List<Machine> machines) async {
    if (machines.isEmpty) return;

    Machine? selectedMachine;
    if (machines.length == 1) {
      selectedMachine = machines.first;
    } else {
      selectedMachine = await showDialog<Machine>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Choose a printer'),
          content: SizedBox(
            width: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: machines.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final machine = machines[index];
                return ListTile(
                  leading: _PrinterLeading(hasVpn: machine.vpnConfig != null),
                  title: Text(machine.name),
                  subtitle: Text(machine.httpUrl),
                  onTap: () => Navigator.of(dialogContext).pop(machine),
                );
              },
            ),
          ),
        ),
      );
    }

    if (selectedMachine == null || !mounted) return;
    await context.push('${Routes.notificationSettings}/${selectedMachine.id}');
  }

  Future<void> _launchGitHub() async {
    final uri = Uri.parse(AppConstants.repoUrl);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open GitHub.')),
      );
    }
  }

  Future<void> _showLicenseDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => const AlertDialog(
        title: Text('License'),
        content: Text(
          'MMURaker is a non-commercial derivative of mobileraker by Patrick '
          'Schmidt. Licensed under the Mobileraker License v2. See the NOTICE '
          'file for full attribution.',
        ),
      ),
    );
  }

  Future<void> _showCreditsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Credits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• Patrick Schmidt (mobileraker)'),
            const Gap(8),
            const Text('• WireGuard® / Jason A. Donenfeld'),
            const Gap(8),
            const Text('• Flutter / Dart teams'),
            const Gap(8),
            const Text('• All open-source contributors'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final machinesAsync = ref.watch(machineListProvider);

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? AppConstants.appVersion;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openPrinterEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Add Printer'),
          ),
          body: machinesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load settings.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (machines) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const _SectionHeader('Printers'),
                if (machines.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.print_disabled_outlined),
                      title: Text('No printers configured'),
                      subtitle: Text('Use Add Printer to create your first machine.'),
                    ),
                  )
                else
                  ...machines.map(
                    (machine) => Card(
                      child: ListTile(
                        leading: _PrinterLeading(hasVpn: machine.vpnConfig != null),
                        title: Text(machine.name),
                        subtitle: Text(machine.httpUrl),
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => _connectToPrinter(machine.id),
                              child: const Text('Connect'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit printer',
                              onPressed: () => _openPrinterEditor(machineId: machine.id),
                            ),
                          ],
                        ),
                        onTap: () => _connectToPrinter(machine.id),
                      ),
                    ),
                  ),
                const Gap(12),
                const _SectionHeader('Notifications'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notification Settings'),
                    subtitle: Text(
                      machines.isEmpty
                          ? 'Add a printer to configure notifications.'
                          : machines.length == 1
                              ? 'Manage alerts for ${machines.first.name}'
                              : 'Choose a printer to manage alerts.',
                    ),
                    enabled: machines.isNotEmpty,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: machines.isEmpty
                        ? null
                        : () => _openNotificationSettings(machines),
                  ),
                ),
                const Gap(12),
                const _SectionHeader('Developer / Debug'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Debug & Diagnostics'),
                    subtitle: const Text(
                        'View logs, generate reports, upload to GitHub Gist.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.debug),
                  ),
                ),
                const Gap(12),
                const _SectionHeader('About'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('MMURaker'),
                        subtitle: Text('Version $version'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code_outlined),
                        title: const Text('View on GitHub'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: _launchGitHub,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.gavel_outlined),
                        title: const Text('License'),
                        onTap: _showLicenseDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.favorite_outline),
                        title: const Text('Credits'),
                        onTap: _showCreditsDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _PrinterLeading extends StatelessWidget {
  const _PrinterLeading({required this.hasVpn});

  final bool hasVpn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const CircleAvatar(child: Icon(Icons.print_outlined)),
        if (hasVpn)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vpn_lock,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
