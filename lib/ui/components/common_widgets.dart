// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Consistent section heading used across settings and dashboard pages.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

/// A temperature reading chip (e.g. "210°C / 215°C").
class TemperatureChip extends StatelessWidget {
  const TemperatureChip({
    super.key,
    required this.current,
    required this.target,
    this.label,
    this.isHeating = false,
  });

  final double current;
  final double target;
  final String? label;
  final bool isHeating;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isHeating ? cs.errorContainer : cs.secondaryContainer;
    final onColor = isHeating ? cs.onErrorContainer : cs.onSecondaryContainer;
    return Chip(
      backgroundColor: color,
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label!,
              style: TextStyle(fontSize: 10, color: onColor),
            ),
          Text(
            '${current.toStringAsFixed(0)}° / ${target.toStringAsFixed(0)}°',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onColor,
            ),
          ),
        ],
      ),
      avatar: Icon(
        isHeating ? Icons.local_fire_department : Icons.thermostat,
        size: 16,
        color: onColor,
      ),
    );
  }
}

/// A simple VPN status badge used in app bars.
class VpnStatusBadge extends StatelessWidget {
  const VpnStatusBadge({super.key, required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vpn_lock, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'VPN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
