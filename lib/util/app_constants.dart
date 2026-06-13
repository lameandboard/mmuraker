// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:ui';

/// Shared application-wide constants.
abstract class AppConstants {
  static const String appName = 'mmuraker';
  static const String appVersion = '0.1.0';
  static const String upstreamProject = 'https://github.com/Clon1998/mobileraker';
  static const String repoUrl = 'https://github.com/lameandboard/mmuraker';

  /// Default Moonraker WebSocket path.
  static const String moonrakerWsPath = '/websocket';

  /// Default Moonraker HTTP port.
  static const int defaultMoonrakerPort = 7125;

  /// How long to wait for a Moonraker HTTP ping before declaring the printer
  /// unreachable (triggers auto-VPN if configured).
  static const Duration localReachabilityTimeout = Duration(seconds: 4);

  /// How often the [NetworkService] checks local reachability while connected.
  static const Duration reachabilityPollInterval = Duration(seconds: 15);

  /// How long to wait for the VPN tunnel to come up before retrying.
  static const Duration vpnConnectTimeout = Duration(seconds: 12);

  /// Standard Hive box names.
  static const String machineBoxName = 'machines';
  static const String settingsBoxName = 'settings';

  /// Hive type-adapter IDs – keep these stable across releases.
  static const int machineAdapterId = 0;
  static const int vpnConfigAdapterId = 1;

  /// Default filament colour used when no colour metadata is available.
  static const Color defaultFilamentColor = Color(0xFFB0B0B0);
}
