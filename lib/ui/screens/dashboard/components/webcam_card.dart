// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmuraker/data/model/machine.dart';
import 'package:mmuraker/ui/components/common_widgets.dart';

class WebcamCard extends HookConsumerWidget {
  const WebcamCard({
    super.key,
    required this.machine,
    this.webcamUrl,
    this.isAutodetected = false,
  });

  final Machine machine;
  final String? webcamUrl;
  final bool isAutodetected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webcamUrl = this.webcamUrl ?? machine.safeWebcamUrl;
    final primaryUrl = webcamUrl == null || webcamUrl.isEmpty
        ? null
        : _preferredDisplayUrl(webcamUrl);
    final alternateUrl = webcamUrl == null || webcamUrl.isEmpty
        ? null
        : _alternateDisplayUrl(webcamUrl, primaryUrl);
    final useAutoRefresh = primaryUrl != null && _isSnapshotLikeUrl(primaryUrl);
    final imageHeaders = machine.apiKey?.isNotEmpty == true
        ? <String, String>{'X-Api-Key': machine.apiKey!}
        : const <String, String>{};
    final refreshTick = useState(DateTime.now().millisecondsSinceEpoch);

    useEffect(() {
      if (!useAutoRefresh) return null;
      final timer = Timer.periodic(const Duration(seconds: 2), (_) {
        refreshTick.value = DateTime.now().millisecondsSinceEpoch;
      });
      return timer.cancel;
    }, [primaryUrl, useAutoRefresh]);

    final resolvedUrl = primaryUrl == null
        ? null
        : _withCacheBust(primaryUrl, refreshTick.value, enabled: useAutoRefresh);
    final fallbackUrl = alternateUrl == null
        ? null
        : _withCacheBust(alternateUrl, refreshTick.value, enabled: useAutoRefresh);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SectionHeader('Webcam'),
                const Spacer(),
                if (resolvedUrl != null && isAutodetected)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Chip(label: Text('Auto-detected')),
                  ),
                if (resolvedUrl != null)
                  IconButton(
                    tooltip: 'Refresh webcam',
                    onPressed: () => refreshTick.value =
                        DateTime.now().millisecondsSinceEpoch,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const Gap(8),
            if (resolvedUrl == null)
              _WebcamPlaceholder(
                colorScheme: Theme.of(context).colorScheme,
                message: 'No webcam configured',
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _FullscreenWebcamPage(
                      imageUrl: resolvedUrl,
                      fallbackUrl: fallbackUrl,
                      headers: imageHeaders,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          resolvedUrl,
                          key: ValueKey(resolvedUrl),
                          headers: imageHeaders,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallbackUrl == null
                              ? const ColoredBox(
                                  color: Color(0xFF111318),
                                  child: Center(child: Icon(Icons.videocam_off)),
                                )
                              : CachedNetworkImage(
                                  imageUrl: fallbackUrl,
                                  httpHeaders: imageHeaders,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const ColoredBox(
                                    color: Color(0xFF111318),
                                    child: Center(child: Icon(Icons.videocam_off)),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _withCacheBust(String url, int timestamp, {required bool enabled}) {
    if (!enabled) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        '_ts': '$timestamp',
      },
    ).toString();
  }

  String _preferredDisplayUrl(String url) {
    final snapshot = _snapshotFallbackUrl(url);
    if (snapshot != null && _isStreamLikeUrl(url)) {
      return snapshot;
    }
    return url;
  }

  String? _alternateDisplayUrl(String url, String? preferred) {
    final snapshot = _snapshotFallbackUrl(url);
    if (preferred != null && snapshot != null && preferred != snapshot) {
      return snapshot;
    }
    if (preferred != null && preferred != url) return url;
    return null;
  }

  bool _isStreamLikeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('action=stream') ||
        lower.endsWith('/stream') ||
        lower.endsWith('.m3u8');
  }

  bool _isSnapshotLikeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('action=snapshot') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  String? _snapshotFallbackUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final path = uri.path;
    final query = uri.queryParameters;
    if ((query['action'] ?? '').toLowerCase() == 'stream') {
      return uri
          .replace(
            queryParameters: {
              ...query,
              'action': 'snapshot',
            },
          )
          .toString();
    }
    if (path.toLowerCase().endsWith('/stream')) {
      return uri.replace(path: path.replaceFirst(RegExp(r'/stream$'), '/snapshot')).toString();
    }
    if (path.toLowerCase().endsWith('.m3u8')) {
      return uri.replace(path: path.replaceFirst(RegExp(r'\.m3u8$'), '.jpg')).toString();
    }
    return null;
  }
}

class _WebcamPlaceholder extends StatelessWidget {
  const _WebcamPlaceholder({required this.colorScheme, required this.message});

  final ColorScheme colorScheme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.videocam_off_outlined,
              size: 40, color: colorScheme.onSurfaceVariant),
          const Gap(12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FullscreenWebcamPage extends StatelessWidget {
  const _FullscreenWebcamPage({
    required this.imageUrl,
    required this.fallbackUrl,
    required this.headers,
  });

  final String imageUrl;
  final String? fallbackUrl;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Webcam')),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUrl,
              headers: headers,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => fallbackUrl == null
                  ? const Icon(Icons.videocam_off, color: Colors.white70, size: 48)
                  : CachedNetworkImage(
                      imageUrl: fallbackUrl!,
                      httpHeaders: headers,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.videocam_off,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _MachineWebcamUrlX on Machine {
  String? get safeWebcamUrl {
    try {
      final dynamic dynamicMachine = this;
      final value = dynamicMachine.webcamUrl;
      return value is String && value.isNotEmpty ? value : null;
    } catch (_) {
      return null;
    }
  }
}
