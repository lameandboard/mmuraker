// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:hive_flutter/hive_flutter.dart';

import '../../../util/app_constants.dart';

part 'vpn_config.g.dart';

// ── Protocol enum ─────────────────────────────────────────────────────────────

@HiveType(typeId: AppConstants.vpnProtocolAdapterId)
enum VpnProtocol {
  /// WireGuard — modern, fast, open-source.  Paste full .conf block.
  @HiveField(0)
  wireguard,

  /// OpenVPN — battle-tested, widely supported.  Paste .ovpn config block.
  @HiveField(1)
  openVpn,

  /// IKEv2/IPSec with EAP (username + password).  Uses strongSwan on Android.
  @HiveField(2)
  ikev2Eap,

  /// IKEv2/IPSec with a Pre-Shared Key.  Uses strongSwan on Android.
  @HiveField(3)
  ikev2Psk,

  /// L2TP/IPSec with a Pre-Shared Key.
  @HiveField(4)
  l2tpIpsecPsk,

  /// PPTP — ⚠️ INSECURE and removed from Android 10+.  Provided for legacy
  /// routers only.  Do NOT use for anything sensitive.
  @HiveField(5)
  pptp,
}

// ── Config model ──────────────────────────────────────────────────────────────

/// Protocol-aware VPN configuration stored per-machine in Hive.
///
/// Each protocol uses different fields — only the fields relevant to the
/// selected [protocol] are non-null.  The settings UI shows/hides fields
/// accordingly.
@HiveType(typeId: AppConstants.vpnConfigAdapterId)
class VpnConfig extends HiveObject {
  // ── Common ────────────────────────────────────────────────────────────────

  /// Which VPN protocol to use.
  @HiveField(0)
  VpnProtocol protocol;

  /// Human-readable label shown in the UI.
  @HiveField(1)
  String label;

  /// Auto-connect when the printer is not reachable on the local network.
  @HiveField(2)
  bool autoConnect;

  // ── WireGuard ─────────────────────────────────────────────────────────────

  /// Full WireGuard `.conf` block (all sections: [Interface], [Peer]).
  /// Required when [protocol] == [VpnProtocol.wireguard].
  @HiveField(3)
  String? wgConfigBlock;

  // ── OpenVPN ───────────────────────────────────────────────────────────────

  /// Full `.ovpn` config block.
  /// Required when [protocol] == [VpnProtocol.openVpn].
  @HiveField(4)
  String? ovpnConfigBlock;

  /// Optional OpenVPN username (inline auth).
  @HiveField(5)
  String? ovpnUsername;

  /// Optional OpenVPN password (inline auth).
  @HiveField(6)
  String? ovpnPassword;

  // ── IKEv2 / L2TP / PPTP — common server fields ───────────────────────────

  /// VPN server address (hostname or IP).
  /// Used by: ikev2Eap, ikev2Psk, l2tpIpsecPsk, pptp.
  @HiveField(7)
  String? serverAddress;

  /// Login username.
  /// Used by: ikev2Eap, l2tpIpsecPsk, pptp.
  @HiveField(8)
  String? username;

  /// Login password.
  /// Used by: ikev2Eap, l2tpIpsecPsk, pptp.
  @HiveField(9)
  String? password;

  // ── IPSec-specific key material ───────────────────────────────────────────

  /// Pre-Shared Key (PSK) for IPSec.
  /// Used by: ikev2Psk, l2tpIpsecPsk.
  @HiveField(10)
  String? ipsecPsk;

  /// PEM-encoded CA certificate for IKEv2 certificate-based auth.
  /// Optional — leave null to accept the system's trusted CAs.
  @HiveField(11)
  String? ipsecCaCert;

  /// PEM-encoded client certificate (for mutual TLS / cert auth).
  @HiveField(12)
  String? ipsecClientCert;

  /// PEM-encoded client private key.
  @HiveField(13)
  String? ipsecClientKey;

  /// IKEv2 identity string (e.g. an email, FQDN, or IP).
  /// Leave null to use the username as identity.
  @HiveField(14)
  String? ikev2Identity;

  // ── Constructor ───────────────────────────────────────────────────────────

  VpnConfig({
    required this.protocol,
    this.label = 'VPN',
    this.autoConnect = true,
    // WireGuard
    this.wgConfigBlock,
    // OpenVPN
    this.ovpnConfigBlock,
    this.ovpnUsername,
    this.ovpnPassword,
    // Shared
    this.serverAddress,
    this.username,
    this.password,
    // IPSec key material
    this.ipsecPsk,
    this.ipsecCaCert,
    this.ipsecClientCert,
    this.ipsecClientKey,
    this.ikev2Identity,
  });

  // ── Convenience factories ─────────────────────────────────────────────────

  factory VpnConfig.wireguard({
    required String configBlock,
    String label = 'WireGuard VPN',
    bool autoConnect = true,
  }) =>
      VpnConfig(
        protocol: VpnProtocol.wireguard,
        label: label,
        autoConnect: autoConnect,
        wgConfigBlock: configBlock,
      );

  factory VpnConfig.openVpn({
    required String configBlock,
    String? username,
    String? password,
    String label = 'OpenVPN',
    bool autoConnect = true,
  }) =>
      VpnConfig(
        protocol: VpnProtocol.openVpn,
        label: label,
        autoConnect: autoConnect,
        ovpnConfigBlock: configBlock,
        ovpnUsername: username,
        ovpnPassword: password,
      );

  factory VpnConfig.ikev2Eap({
    required String serverAddress,
    required String username,
    required String password,
    String? caCert,
    String? identity,
    String label = 'IKEv2/IPSec EAP',
    bool autoConnect = true,
  }) =>
      VpnConfig(
        protocol: VpnProtocol.ikev2Eap,
        label: label,
        autoConnect: autoConnect,
        serverAddress: serverAddress,
        username: username,
        password: password,
        ipsecCaCert: caCert,
        ikev2Identity: identity,
      );

  factory VpnConfig.ikev2Psk({
    required String serverAddress,
    required String psk,
    String? username,
    String? password,
    String? identity,
    String label = 'IKEv2/IPSec PSK',
    bool autoConnect = true,
  }) =>
      VpnConfig(
        protocol: VpnProtocol.ikev2Psk,
        label: label,
        autoConnect: autoConnect,
        serverAddress: serverAddress,
        username: username,
        password: password,
        ipsecPsk: psk,
        ikev2Identity: identity,
      );

  factory VpnConfig.l2tpIpsecPsk({
    required String serverAddress,
    required String username,
    required String password,
    required String psk,
    String label = 'L2TP/IPSec PSK',
    bool autoConnect = true,
  }) =>
      VpnConfig(
        protocol: VpnProtocol.l2tpIpsecPsk,
        label: label,
        autoConnect: autoConnect,
        serverAddress: serverAddress,
        username: username,
        password: password,
        ipsecPsk: psk,
      );

  /// ⚠️ PPTP is cryptographically broken and not available on Android 10+.
  factory VpnConfig.pptp({
    required String serverAddress,
    required String username,
    required String password,
    String label = 'PPTP (legacy)',
    bool autoConnect = true,
  }) =>
      VpnConfig(
        protocol: VpnProtocol.pptp,
        label: label,
        autoConnect: autoConnect,
        serverAddress: serverAddress,
        username: username,
        password: password,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Whether this config has enough fields to attempt a connection.
  bool get isComplete {
    return switch (protocol) {
      VpnProtocol.wireguard =>
        wgConfigBlock != null && wgConfigBlock!.trim().isNotEmpty,
      VpnProtocol.openVpn =>
        ovpnConfigBlock != null && ovpnConfigBlock!.trim().isNotEmpty,
      VpnProtocol.ikev2Eap =>
        serverAddress != null && username != null && password != null,
      VpnProtocol.ikev2Psk =>
        serverAddress != null && ipsecPsk != null,
      VpnProtocol.l2tpIpsecPsk =>
        serverAddress != null &&
            username != null &&
            password != null &&
            ipsecPsk != null,
      VpnProtocol.pptp =>
        serverAddress != null && username != null && password != null,
    };
  }

  /// User-facing protocol name.
  String get protocolDisplayName => switch (protocol) {
        VpnProtocol.wireguard => 'WireGuard',
        VpnProtocol.openVpn => 'OpenVPN',
        VpnProtocol.ikev2Eap => 'IKEv2/IPSec (EAP)',
        VpnProtocol.ikev2Psk => 'IKEv2/IPSec (PSK)',
        VpnProtocol.l2tpIpsecPsk => 'L2TP/IPSec (PSK)',
        VpnProtocol.pptp => 'PPTP ⚠️',
      };

  @override
  String toString() => 'VpnConfig($label · $protocolDisplayName)';
}

