// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:hive_flutter/hive_flutter.dart';

import 'package:mmuraker/util/app_constants.dart';
import 'vpn_config.dart';

part 'machine.g.dart';

/// A configured Klipper/Moonraker printer machine entry, persisted in Hive.
///
/// Architecture note: mirrors the Machine model concept from mobileraker's
/// `common/lib/data/model/hive/machine.dart`.
@HiveType(typeId: AppConstants.machineAdapterId)
class Machine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Hostname or IP address of the Moonraker instance.
  @HiveField(2)
  String httpUrl;

  /// WebSocket URL derived from httpUrl at construction time.
  @HiveField(3)
  String wsUrl;

  /// Port number (default 7125).
  @HiveField(4)
  int port;

  /// Optional HTTP Basic Auth token / API key.
  @HiveField(5)
  String? apiKey;

  /// Saved WireGuard VPN configuration for this machine.
  /// When present, the [VpnService] can establish a tunnel to reach it remotely.
  @HiveField(6)
  VpnConfig? vpnConfig;

  /// Last known connection status label for display purposes.
  @HiveField(7)
  String lastKnownState;

  /// Optional webcam stream URL shown on the dashboard.
  @HiveField(8)
  String? webcamUrl;

  Machine({
    required this.id,
    required this.name,
    required this.httpUrl,
    required this.wsUrl,
    this.port = AppConstants.defaultMoonrakerPort,
    this.apiKey,
    this.vpnConfig,
    this.lastKnownState = 'disconnected',
    this.webcamUrl,
  });

  @override
  String toString() => 'Machine($name @ $httpUrl:$port)';
}
