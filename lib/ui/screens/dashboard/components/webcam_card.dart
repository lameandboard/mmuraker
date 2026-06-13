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
  const WebcamCard({super.key, required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webcamUrl = machine.safeWebcamUrl;
    final refreshTick = useState(DateTime.now().millisecondsSinceEpoch);

    useEffect(() {
      if (webcamUrl == null || webcamUrl.isEmpty) return null;
      final timer = Timer.periodic(const Duration(seconds: 2), (_) {
        refreshTick.value = DateTime.now().millisecondsSinceEpoch;
      });
      return timer.cancel;
    }, [webcamUrl]);

    final resolvedUrl = webcamUrl == null || webcamUrl.isEmpty
        ? null
        : _withCacheBust(webcamUrl, refreshTick.value);
    final fallbackUrl = webcamUrl == null || webcamUrl.isEmpty
        ? null
        : _snapshotFallbackUrl(webcamUrl);

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
                        if (fallbackUrl != null)
                          CachedNetworkImage(
                            imageUrl: fallbackUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: Color(0xFF111318),
                              child: Center(child: Icon(Icons.videocam_off)),
                            ),
                          ),
                        Image.network(
                          resolvedUrl,
                          key: ValueKey(resolvedUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallbackUrl == null
                              ? const ColoredBox(
                                  color: Color(0xFF111318),
                                  child: Center(child: Icon(Icons.videocam_off)),
                                )
                              : CachedNetworkImage(
                                  imageUrl: fallbackUrl,
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

  String _withCacheBust(String url, int timestamp) {
    final uri = Uri.parse(url);
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        '_ts': '$timestamp',
      },
    ).toString();
  }

  String _snapshotFallbackUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.endsWith('.m3u8')
        ? uri.path.replaceFirst(RegExp(r'\.m3u8$'), '.jpg')
        : uri.path;
    return uri.replace(path: path).toString();
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
  });

  final String imageUrl;
  final String? fallbackUrl;

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
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => fallbackUrl == null
                  ? const Icon(Icons.videocam_off, color: Colors.white70, size: 48)
                  : CachedNetworkImage(
                      imageUrl: fallbackUrl!,
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
