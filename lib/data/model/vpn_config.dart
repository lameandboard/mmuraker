// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:hive_flutter/hive_flutter.dart';

import '../../../util/app_constants.dart';

part 'vpn_config.g.dart';

/// WireGuard VPN configuration stored per-machine.
///
/// The user pastes their WireGuard `.conf` block on the VPN settings screen.
/// The [VpnService] reads this when auto-connecting.
@HiveType(typeId: AppConstants.vpnConfigAdapterId)
class VpnConfig extends HiveObject {
  /// Full WireGuard config block as a string (the `.conf` file contents).
  @HiveField(0)
  String configBlock;

  /// Optional human-readable label (e.g. "Home WireGuard").
  @HiveField(1)
  String label;

  /// Whether auto-connect is enabled for this config.
  /// When true the VPN is brought up automatically whenever the printer is
  /// unreachable on the local network. Always defaults to enabled — nothing
  /// is locked behind a flag. See [FeatureFlags.autoVpn].
  @HiveField(2)
  bool autoConnect;

  VpnConfig({
    required this.configBlock,
    this.label = 'WireGuard VPN',
    this.autoConnect = true,
  });

  @override
  String toString() => 'VpnConfig($label, autoConnect=$autoConnect)';
}
