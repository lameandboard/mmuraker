// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../service/debug/debug_service.dart';
import '../../../service/debug/github_report_service.dart';
import '../../../util/logger.dart';

/// Full-screen debug panel.
///
/// Accessible from Settings → Debug (shown in both debug and release builds
/// so real-device issues can always be diagnosed and reported).
///
/// Features:
///   • Live Talker log viewer (colour-coded by level, filterable, searchable)
///   • One-tap diagnostic report generation
///   • Upload report to GitHub Gist → shareable URL
///   • Pre-fill a GitHub Issue with the report
///   • Copy report text to clipboard
class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key, this.machineId});

  /// Optional: include printer state in the report if a machine is selected.
  final String? machineId;

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _uploading = false;
  String? _gistUrl;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Diagnostics'),
        actions: [
          // Quick share / upload button
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_outlined),
              tooltip: 'Upload to GitHub Gist',
              onPressed: _uploadReport,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Live Logs'),
            Tab(icon: Icon(Icons.bug_report_outlined), text: 'Report'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status / Gist URL banner
          if (_statusMessage != null)
            _StatusBanner(
              message: _statusMessage!,
              gistUrl: _gistUrl,
              onDismiss: () => setState(() {
                _statusMessage = null;
                _gistUrl = null;
              }),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Tab 1: Live Talker log viewer ──────────────────────
                TalkerScreen(
                  talker: appLogger,
                  appBarTitle: 'Live Logs',
                  theme: TalkerScreenTheme(
                    backgroundColor: cs.surface,
                    textColor: cs.onSurface,
                    logColors: {
                      TalkerLogType.verbose.key: Colors.grey,
                      TalkerLogType.debug.key: Colors.blueGrey,
                      TalkerLogType.info.key: Colors.blue,
                      TalkerLogType.warning.key: Colors.orange,
                      TalkerLogType.error.key: Colors.red,
                      TalkerLogType.critical.key: Colors.deepPurple,
                    },
                  ),
                ),

                // ── Tab 2: Report actions ──────────────────────────────
                _ReportActionsTab(
                  machineId: widget.machineId,
                  onUpload: _uploadReport,
                  onGistUrl: _gistUrl,
                  uploading: _uploading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadReport() async {
    setState(() {
      _uploading = true;
      _statusMessage = null;
      _gistUrl = null;
    });

    try {
      final debugSvc = ref.read(debugServiceProvider);
      final reportSvc = ref.read(githubReportServiceProvider);

      final report = await debugSvc.collect(
        printerState: widget.machineId != null
            ? 'Machine ID: ${widget.machineId}'
            : null,
      );

      final result = await reportSvc.upload(report);

      if (result.success) {
        setState(() {
          _gistUrl = result.gistUrl;
          _statusMessage =
              '✅ Report uploaded! Tap the link to view or share.';
        });
      } else {
        setState(() {
          _statusMessage = '❌ Upload failed: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() => _uploading = false);
    }
  }
}

// ── Status banner ──────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.gistUrl,
    required this.onDismiss,
  });
  final String message;
  final String? gistUrl;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isError = message.startsWith('❌');

    return Container(
      color: isError
          ? cs.errorContainer
          : cs.primaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isError
                            ? cs.onErrorContainer
                            : cs.onPrimaryContainer,
                      ),
                ),
                if (gistUrl != null) ...[
                  const Gap(4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(gistUrl!),
                        mode: LaunchMode.externalApplication),
                    child: Text(
                      gistUrl!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: cs.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (gistUrl != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy URL',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: gistUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gist URL copied')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ── Report actions tab ─────────────────────────────────────────────────────────

class _ReportActionsTab extends ConsumerWidget {
  const _ReportActionsTab({
    required this.machineId,
    required this.onUpload,
    required this.onGistUrl,
    required this.uploading,
  });

  final String? machineId;
  final VoidCallback onUpload;
  final String? onGistUrl;
  final bool uploading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Info card ────────────────────────────────────────────────────
        Card(
          color: cs.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: cs.onSecondaryContainer, size: 18),
                    const Gap(8),
                    Text(
                      'How debug reports work',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: cs.onSecondaryContainer),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  '1. Tap "Upload to GitHub Gist" — creates a public Gist '
                  'with your device info, app version, and full log history.\n\n'
                  '2. You get a shareable URL — paste it into a GitHub Issue '
                  'or share it directly.\n\n'
                  '3. Tap "Create GitHub Issue" to open a pre-filled bug report '
                  'in your browser — just add a description and submit.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),

        const Gap(16),

        // ── Upload to Gist ───────────────────────────────────────────────
        _ActionTile(
          icon: Icons.cloud_upload_outlined,
          title: 'Upload to GitHub Gist',
          subtitle: 'Creates a public Gist with all logs and device info. '
              'No account needed — returns a shareable URL.',
          onTap: uploading ? null : onUpload,
          trailing: uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : null,
        ),

        const Gap(8),

        // ── Create Issue ─────────────────────────────────────────────────
        _ActionTile(
          icon: Icons.bug_report_outlined,
          title: 'Create GitHub Issue',
          subtitle:
              'Opens the mmuraker issue tracker in your browser with the '
              'report pre-filled. Add a description and submit.',
          onTap: () async {
            final debugSvc = ref.read(debugServiceProvider);
            final reportSvc = ref.read(githubReportServiceProvider);
            final report = await debugSvc.collect(
              printerState:
                  machineId != null ? 'Machine ID: $machineId' : null,
            );
            final result = await reportSvc.upload(report);
            if (result.issueUrl != null) {
              await launchUrl(
                Uri.parse(result.issueUrl!),
                mode: LaunchMode.externalApplication,
              );
            }
          },
        ),

        const Gap(8),

        // ── Copy to clipboard ────────────────────────────────────────────
        _ActionTile(
          icon: Icons.copy_outlined,
          title: 'Copy Report to Clipboard',
          subtitle:
              'Copies the full Markdown report to clipboard — paste into '
              'Discord, email, or any other channel.',
          onTap: () async {
            final debugSvc = ref.read(debugServiceProvider);
            final report = await debugSvc.collect(
              printerState:
                  machineId != null ? 'Machine ID: $machineId' : null,
            );
            await Clipboard.setData(
                ClipboardData(text: report.toMarkdown()));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard')),
              );
            }
          },
        ),

        const Gap(16),

        // ── Clear logs ───────────────────────────────────────────────────
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Clear Log History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.error,
          ),
          onPressed: () {
            appLogger.cleanHistory();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log history cleared')),
            );
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle,
            style: Theme.of(context).textTheme.bodySmall),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
