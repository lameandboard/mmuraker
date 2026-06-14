// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmuraker/service/moonraker/printer_service.dart';
import 'package:mmuraker/ui/components/common_widgets.dart';

class BedMeshData {
  const BedMeshData({
    required this.profileName,
    required this.meshMatrix,
    required this.minValue,
    required this.maxValue,
  });

  final String profileName;
  final List<List<double>> meshMatrix;
  final double minValue;
  final double maxValue;

  factory BedMeshData.fromMoonraker(Map<String, dynamic> bedMesh) {
    final rawMatrix = bedMesh['mesh_matrix'] as List? ?? const [];
    final matrix = rawMatrix
        .map(
          (row) => (row as List)
              .map((value) => (value as num).toDouble())
              .toList(growable: false),
        )
        .where((row) => row.isNotEmpty)
        .toList(growable: false);

    final values = matrix.expand((row) => row).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    return BedMeshData(
      profileName: bedMesh['profile_name']?.toString() ?? 'default',
      meshMatrix: matrix,
      minValue: minValue,
      maxValue: maxValue,
    );
  }

  static BedMeshData? maybeFromMoonraker(Map<String, dynamic>? bedMesh) {
    if (bedMesh == null) return null;
    final rawMatrix = bedMesh['mesh_matrix'];
    if (rawMatrix is! List || rawMatrix.isEmpty) return null;
    final hasPoints = rawMatrix.any((row) => row is List && row.isNotEmpty);
    if (!hasPoints) return null;
    return BedMeshData.fromMoonraker(bedMesh);
  }

  double get meanValue {
    final values = meshMatrix.expand((row) => row).toList(growable: false);
    return values.reduce((sum, value) => sum + value) / values.length;
  }
}

class BedMeshCard extends HookConsumerWidget {
  const BedMeshCard({
    super.key,
    required this.printerService,
    required this.bedMesh,
  });

  final PrinterService printerService;
  final Map<String, dynamic>? bedMesh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meshData = BedMeshData.maybeFromMoonraker(bedMesh);
    final busyAction = useState<String?>(null);

    Future<void> sendCommand(String label, String command) async {
      if (busyAction.value != null) return;
      busyAction.value = label;
      try {
        await printerService.sendGcode(command);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to run $command: $error')),
          );
        }
      } finally {
        busyAction.value = null;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionHeader('Bed Mesh'),
                const Spacer(),
                TextButton.icon(
                  onPressed: busyAction.value == null
                      ? () => sendCommand('calibrate', 'BED_MESH_CALIBRATE')
                      : null,
                  icon: busyAction.value == 'calibrate'
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.tune),
                  label: const Text('Calibrate'),
                ),
                const Gap(8),
                TextButton.icon(
                  onPressed: busyAction.value == null
                      ? () => sendCommand('clear', 'BED_MESH_CLEAR')
                      : null,
                  icon: busyAction.value == 'clear'
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.layers_clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const Gap(8),
            if (meshData == null)
              const Text('No mesh loaded — tap Calibrate to generate one')
            else ...[
              Text(
                'Profile: ${meshData.profileName}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Gap(12),
              AspectRatio(
                aspectRatio: 1.3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                      painter: _BedMeshPainter(meshData),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              _BedMeshLegend(data: meshData),
            ],
          ],
        ),
      ),
    );
  }
}

class _BedMeshLegend extends StatelessWidget {
  const _BedMeshLegend({required this.data});

  final BedMeshData data;

  @override
  Widget build(BuildContext context) {
    final mean = data.meanValue;
    final minDelta = data.minValue - mean;
    final maxDelta = data.maxValue - mean;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Min Δ ${minDelta >= 0 ? '+' : ''}${minDelta.toStringAsFixed(3)} mm',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Text(
            'Max Δ ${maxDelta >= 0 ? '+' : ''}${maxDelta.toStringAsFixed(3)} mm',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _BedMeshPainter extends CustomPainter {
  const _BedMeshPainter(this.data);

  final BedMeshData data;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = data.meshMatrix.length;
    final cols = data.meshMatrix.first.length;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final mean = data.meanValue;
    final maxAbsDelta = data.meshMatrix
        .expand((row) => row)
        .map((value) => (value - mean).abs())
        .fold<double>(0, math.max);

    final cellPaint = Paint()..style = PaintingStyle.fill;
    final pointPaint = Paint()..color = Colors.black.withOpacity(0.8);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final value = data.meshMatrix[row][col];
        final normalized = maxAbsDelta == 0
            ? 0.5
            : ((value - mean) / (maxAbsDelta * 2)) + 0.5;
        cellPaint.color = _meshColor(normalized.clamp(0.0, 1.0));

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * cellWidth,
            row * cellHeight,
            cellWidth - 2,
            cellHeight - 2,
          ),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, cellPaint);

        final center = Offset(
          col * cellWidth + cellWidth / 2,
          row * cellHeight + cellHeight / 2,
        );
        canvas.drawCircle(center, math.min(cellWidth, cellHeight) * 0.08, pointPaint);
      }
    }
  }

  Color _meshColor(double value) {
    if (value < 0.5) {
      return Color.lerp(Colors.blue.shade700, Colors.white, value * 2)!;
    }
    return Color.lerp(Colors.white, Colors.red.shade700, (value - 0.5) * 2)!;
  }

  @override
  bool shouldRepaint(covariant _BedMeshPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
