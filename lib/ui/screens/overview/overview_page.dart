// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/model/machine.dart';
import '../../../service/machine_service.dart';

/// Lists all configured printers and lets users navigate to their dashboard
/// or add a new machine.
///
/// Architecture note: mirrors mobileraker's overview screen in style.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesAsync = ref.watch(machineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('mmuraker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: machinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load printers.\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (machines) => machines.isEmpty
            ? _EmptyState(onAdd: () => context.push('/settings/add-printer'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: machines.length,
                itemBuilder: (ctx, i) => _MachineCard(machine: machines[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'overviewAddPrinter',
        onPressed: () => context.push('/settings/add-printer'),
        icon: const Icon(Icons.add),
        label: const Text('Add Printer'),
      ),
    );
  }
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine});
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(child: Icon(Icons.print)),
        title: Text(machine.name),
        subtitle: Text(
          machine.httpUrl,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (machine.vpnConfig != null)
              const Tooltip(
                message: 'Auto-VPN configured',
                child: Icon(Icons.vpn_lock, size: 18, color: Colors.green),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/dashboard/${machine.id}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.print_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No printers added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Printer" to configure your\nKlipper/Moonraker instance.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Printer'),
          ),
        ],
      ),
    );
  }
}
