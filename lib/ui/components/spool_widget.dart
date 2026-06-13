// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A visually rich spool widget drawn with [CustomPainter].
///
/// Renders a spool side-on with:
///   • Grey flanges (the circular side plates)
///   • Coloured filament wound between the flanges, fill proportional to
///     [remainingPercent] (0–100)
///   • The spool hub/core in the centre
///   • Weight text centred inside the hub
///
/// Usage:
/// ```dart
/// SpoolWidget(
///   filamentColor: Colors.red,
///   remainingPercent: 72.0,
///   remainingGrams: 720,
///   size: 80,
/// )
/// ```
class SpoolWidget extends StatelessWidget {
  const SpoolWidget({
    super.key,
    required this.filamentColor,
    required this.remainingPercent,
    this.remainingGrams,
    this.size = 80,
    this.showWeight = true,
  });

  /// Filament colour shown as the wound filament.
  final Color filamentColor;

  /// 0–100: how full the spool is.
  final double remainingPercent;

  /// Optional grams remaining to display as centre text.
  final double? remainingGrams;

  /// Widget width & height in logical pixels.
  final double size;

  /// Whether to render the weight text in the hub.
  final bool showWeight;

  @override
  Widget build(BuildContext context) {
    final textColor = _contrastColor(filamentColor);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpoolPainter(
          filamentColor: filamentColor,
          remainingPercent: remainingPercent.clamp(0.0, 100.0),
          flangeColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
          hubColor: Theme.of(context).colorScheme.surface,
          strokeColor: Theme.of(context).colorScheme.outline.withOpacity(0.35),
        ),
        child: showWeight && remainingGrams != null
            ? Center(
                child: Text(
                  _formatGrams(remainingGrams!),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  static String _formatGrams(double g) {
    if (g >= 1000) return '${(g / 1000).toStringAsFixed(2)}\nkg';
    return '${g.toStringAsFixed(0)}\ng';
  }

  /// Returns black or white depending on which has better contrast.
  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.35 ? Colors.black87 : Colors.white;
  }
}

class _SpoolPainter extends CustomPainter {
  const _SpoolPainter({
    required this.filamentColor,
    required this.remainingPercent,
    required this.flangeColor,
    required this.hubColor,
    required this.strokeColor,
  });

  final Color filamentColor;
  final double remainingPercent; // 0–100
  final Color flangeColor;
  final Color hubColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    // Radii as fractions of total radius
    final flangeR = r;
    final filamentOuterR = r * 0.78;
    final filamentInnerR = r * 0.38;
    final hubR = r * 0.34;

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03;

    // ── 1. Flange (full circle background) ─────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      flangeR,
      Paint()..color = flangeColor,
    );
    canvas.drawCircle(Offset(cx, cy), flangeR, stroke);

    // ── 2. Empty filament zone (always full ring, slightly lighter) ─────────
    canvas.drawCircle(
      Offset(cx, cy),
      filamentOuterR,
      Paint()..color = Colors.grey.shade200.withOpacity(0.55),
    );

    // ── 3. Filament fill (arc, clockwise from top, proportional to remaining)
    if (remainingPercent > 0) {
      // We fill a ring, clipped to a sweep angle proportional to fill percent.
      final sweepAngle = 2 * math.pi * (remainingPercent / 100);
      final startAngle = -math.pi / 2; // 12 o'clock

      final filamentPaint = Paint()
        ..color = filamentColor
        ..style = PaintingStyle.fill;

      // Draw filled ring by combining two circles via canvas layer trick:
      // draw filled arc, then cut out hub-sized hole.
      final rect = Rect.fromCircle(
          center: Offset(cx, cy), radius: filamentOuterR);

      // Full pie arc
      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(rect, startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, filamentPaint);

      // Cut out the inner hole (filamentInnerR)
      canvas.drawCircle(
        Offset(cx, cy),
        filamentInnerR,
        Paint()
          ..color = Colors.grey.shade200.withOpacity(0.55)
          ..style = PaintingStyle.fill,
      );
    } else {
      // Empty spool — show darker ring
      canvas.drawCircle(
        Offset(cx, cy),
        filamentOuterR,
        Paint()..color = Colors.grey.shade400.withOpacity(0.3),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        filamentInnerR,
        Paint()..color = Colors.grey.shade200.withOpacity(0.55),
      );
    }

    // Thin ring outline around filament zone
    final ringOutline = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.025;
    canvas.drawCircle(Offset(cx, cy), filamentOuterR, ringOutline);
    canvas.drawCircle(Offset(cx, cy), filamentInnerR, ringOutline);

    // ── 4. Hub (centre axle circle) ─────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      hubR,
      Paint()..color = hubColor,
    );
    canvas.drawCircle(Offset(cx, cy), hubR, stroke);

    // ── 5. Spoke details (3 spokes for realism) ────────────────────────────
    final spokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = r * 0.04
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3);
      canvas.drawLine(
        Offset(cx + math.cos(angle) * hubR * 0.9,
               cy + math.sin(angle) * hubR * 0.9),
        Offset(cx + math.cos(angle) * filamentInnerR * 0.95,
               cy + math.sin(angle) * filamentInnerR * 0.95),
        spokePaint,
      );
    }

    // ── 6. Centre axle hole ─────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.09,
      Paint()..color = strokeColor.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(_SpoolPainter old) =>
      old.filamentColor != filamentColor ||
      old.remainingPercent != remainingPercent;
}

// ── Compact spool chip ─────────────────────────────────────────────────────────

/// A small inline spool indicator suitable for AFC lane tiles, gate map, etc.
///
/// Shows a mini spool icon + material name + weight or percentage.
class SpoolChip extends StatelessWidget {
  const SpoolChip({
    super.key,
    required this.filamentColor,
    required this.remainingPercent,
    this.remainingGrams,
    this.material,
    this.size = 28,
  });

  final Color filamentColor;
  final double remainingPercent;
  final double? remainingGrams;
  final String? material;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpoolWidget(
          filamentColor: filamentColor,
          remainingPercent: remainingPercent,
          remainingGrams: null,
          size: size,
          showWeight: false,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (material != null && material!.isNotEmpty)
              Text(
                material!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            Text(
              remainingGrams != null
                  ? '${remainingGrams!.toStringAsFixed(0)} g  '
                      '(${remainingPercent.toStringAsFixed(0)}%)'
                  : '${remainingPercent.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: remainingPercent < 10
                        ? cs.error
                        : cs.onSurface.withOpacity(0.65),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
