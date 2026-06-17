// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/dto/files/gcode_file.dart';
import '../../../../service/moonraker/printer_service.dart';
import '../../../components/common_widgets.dart';

class FilesPane extends HookConsumerWidget {
  const FilesPane({
    super.key,
    required this.printerService,
    this.activeFile,
  });

  final PrinterService printerService;
  final String? activeFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadTick = useState(0);
    final filesFuture = useMemoized(
      () => _loadFiles(printerService),
      [printerService, reloadTick.value],
    );

    Future<void> refresh() async {
      reloadTick.value++;
    }

    Future<void> startPrint(GCodeFile file) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start Print?'),
          content: Text('Start printing "${file.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      try {
        await printerService.sendJsonRpc(
          'printer.print.start',
          {'filename': _normalizeFilenameForPrint(file.path)},
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Started print: ${file.name}')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start print: $error')),
          );
        }
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<List<GCodeFile>>(
        future: filesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SectionHeader('Files'),
                const Gap(12),
                Text(
                  'Could not load files.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                FilledButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            );
          }

          final files = snapshot.data ?? const <GCodeFile>[];
          if (files.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SectionHeader('Files'),
                Gap(12),
                Center(child: Text('No printable G-code files found.')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: files.length + 1,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    const Expanded(child: SectionHeader('Files')),
                    IconButton(
                      tooltip: 'Refresh files',
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                );
              }

              final file = files[index - 1];
              final normalizedPath = _normalizeFilenameForPrint(file.path);
              final isActive = activeFile == file.path ||
                  activeFile == file.name ||
                  activeFile == normalizedPath;
              return Card(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                child: ListTile(
                  leading: Icon(
                    isActive ? Icons.play_circle_fill : Icons.description_outlined,
                  ),
                  title: Text(file.name),
                  subtitle: Text(
                    [
                      file.path,
                      if (file.size > 0) _formatBytes(file.size),
                    ].join(' • '),
                  ),
                  trailing: FilledButton.tonalIcon(
                    onPressed: () => startPrint(file),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(isActive ? 'Reprint' : 'Print'),
                  ),
                  onTap: () => startPrint(file),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<GCodeFile>> _loadFiles(PrinterService printerService) async {
    final result = await printerService.sendJsonRpc(
      'server.files.list',
      {'root': 'gcodes'},
    );
    final rawFiles = _extractFileEntries(result);

    final files = rawFiles
        .whereType<Map>()
        .map((entry) => _parseFile(Map<String, dynamic>.from(entry)))
        .where((file) => _isPrintableFile(file.path))
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return files;
  }

  List<dynamic> _extractFileEntries(Object? payload) {
    final queue = <Object?>[payload];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current is List && current.every((e) => e is Map)) {
        return current;
      }
      if (current is Map) {
        final map = current.map((key, value) => MapEntry(key.toString(), value));
        final files = map['files'];
        if (files is List && files.every((e) => e is Map)) {
          return files;
        }
        queue.add(map['result']);
        queue.add(map['value']);
        queue.add(map['gcodes']);
      }
    }
    return const [];
  }

  GCodeFile _parseFile(Map<String, dynamic> json) {
    final path = json['path']?.toString() ??
        json['filename']?.toString() ??
        json['name']?.toString() ??
        '';
    final name = path.split('/').last;
    return GCodeFile(
      name: name,
      path: path,
      size: (json['size'] as num?)?.toInt() ?? 0,
      printTime: (json['print_time'] as num?)?.toDouble() ?? 0,
    );
  }

  bool _isPrintableFile(String path) {
    final lowered = path.toLowerCase();
    return lowered.endsWith('.gcode') ||
        lowered.endsWith('.gco') ||
        lowered.endsWith('.gc');
  }

  String _normalizeFilenameForPrint(String path) {
    var normalized = path.replaceAll('\\', '/').trim();
    if (normalized.startsWith('/')) normalized = normalized.substring(1);
    if (normalized.toLowerCase().startsWith('gcodes/')) {
      normalized = normalized.substring('gcodes/'.length);
    }
    return normalized;
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}
