// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mmuraker/service/moonraker/printer_service.dart';
import 'package:mmuraker/ui/components/common_widgets.dart';

const _defaultConsoleMacros = <String>[
  'G28',
  'G29',
  'PROBE_CALIBRATE',
  'BED_MESH_CALIBRATE',
  'PID_CALIBRATE HEATER=extruder TARGET=200',
  'SAVE_CONFIG',
];

final consoleHistoryProvider =
    StateNotifierProvider.family<ConsoleHistoryNotifier, List<String>, String>(
  (ref, machineId) => ConsoleHistoryNotifier(),
);

class ConsoleHistoryNotifier extends StateNotifier<List<String>> {
  ConsoleHistoryNotifier() : super(const []);

  static const _maxLines = 200;

  void addLine(String line) {
    final next = [...state, line];
    state = next.length <= _maxLines
        ? next
        : next.sublist(next.length - _maxLines);
  }

  void clear() => state = const [];
}

class ConsolePage extends HookConsumerWidget {
  const ConsolePage({super.key, required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerService = ref.watch(printerServiceProvider(machineId));
    final history = ref.watch(consoleHistoryProvider(machineId));
    final historyNotifier = ref.read(consoleHistoryProvider(machineId).notifier);
    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final isSending = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
      return null;
    }, [history.length]);

    Future<void> submitCommand(String rawCommand) async {
      final command = rawCommand.trim();
      if (command.isEmpty || isSending.value) return;

      historyNotifier.addLine(_formatConsoleLine(command, outgoing: true));
      isSending.value = true;

      try {
        await printerService.sendGcode(command);
        controller.clear();
      } catch (error) {
        historyNotifier.addLine(_formatConsoleLine('Error: $error'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send command: $error')),
          );
        }
      } finally {
        isSending.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('G-code Console'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: history.isEmpty ? null : historyNotifier.clear,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SectionHeader('Console'),
                      ),
                      const Gap(8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(color: Color(0xFF111318)),
                          child: history.isEmpty
                              ? Center(
                                  child: Text(
                                    'No console output yet.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: history.length,
                                  separatorBuilder: (_, __) => const Gap(4),
                                  itemBuilder: (context, index) => SelectableText(
                                    history[index],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontFamily: 'monospace',
                                          height: 1.35,
                                        ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Macros'),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final macro in _defaultConsoleMacros)
                            ActionChip(
                              label: Text(macro),
                              onPressed: isSending.value
                                  ? null
                                  : () => submitCommand(macro),
                            ),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              enabled: !isSending.value,
                              textInputAction: TextInputAction.send,
                              onSubmitted: submitCommand,
                              decoration: const InputDecoration(
                                labelText: 'Command',
                                hintText: 'Enter G-code or macro',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const Gap(12),
                          FilledButton.icon(
                            onPressed: isSending.value
                                ? null
                                : () => submitCommand(controller.text),
                            icon: isSending.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Send'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatConsoleLine(String line, {bool outgoing = false}) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    final prefix = outgoing ? '> ' : '';
    return '[$timestamp] $prefix$line';
  }
}
