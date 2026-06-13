// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../util/app_constants.dart';
import '../util/logger.dart';

part 'network_scanner_service.g.dart';

@riverpod
NetworkScannerService networkScannerService(Ref ref) =>
    NetworkScannerService();

/// A Moonraker instance found during a local-network scan.
class DiscoveredPrinter {
  const DiscoveredPrinter({
    required this.httpUrl,
    required this.displayName,
  });

  /// Base HTTP URL, e.g. `http://192.168.1.42:7125`.
  final String httpUrl;

  /// Human-readable label — the hostname reported by `/server/info`, or the
  /// raw IP address when the hostname is unavailable.
  final String displayName;

  @override
  String toString() => '$displayName ($httpUrl)';
}

/// Scans the local Wi-Fi subnet for active Moonraker instances.
///
/// Uses [NetworkInfo.getWifiIP] to discover the device's Wi-Fi address, then
/// probes every host in the /24 subnet on [AppConstants.defaultMoonrakerPort]
/// with a short HTTP `GET /server/info` request.  Probes are issued in
/// parallel batches of [_batchSize] to keep the scan fast (typically < 15 s
/// on a home network).
///
/// ### Android permissions
/// Reading the Wi-Fi IP requires `ACCESS_WIFI_STATE`.  On Android 10+ the OS
/// also requires `ACCESS_FINE_LOCATION` to be granted at runtime.  If the
/// permission is not granted, [NetworkInfo.getWifiIP] returns `null` and
/// [scanLocalNetwork] returns an empty list immediately.
class NetworkScannerService {
  static const int _batchSize = 25;
  static const Duration _probeTimeout = Duration(seconds: 2);

  /// Scans the current Wi-Fi /24 subnet for Moonraker instances.
  ///
  /// [onProgress] is called after each batch completes with
  /// `(found, probed, total)` counts (total = 254).
  ///
  /// [isCancelled] is polled before each batch — return `true` to abort early.
  ///
  /// Returns an empty list when the Wi-Fi IP cannot be determined (e.g.
  /// running on cellular only, or location permission not granted).
  Future<List<DiscoveredPrinter>> scanLocalNetwork({
    void Function(int found, int probed, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final wifiIp = await NetworkInfo().getWifiIP();
    if (wifiIp == null) {
      appLogger.warning(
        'NetworkScannerService: Wi-Fi IP unavailable – '
        'check location permission / Wi-Fi connection',
      );
      return [];
    }

    final subnet = _extractSubnet(wifiIp);
    if (subnet == null) {
      appLogger.warning(
        'NetworkScannerService: cannot parse /24 subnet from "$wifiIp"',
      );
      return [];
    }

    appLogger.info(
      'NetworkScannerService: scanning $subnet.1–254 '
      'on port ${AppConstants.defaultMoonrakerPort}',
    );

    final results = <DiscoveredPrinter>[];
    const total = 254;

    for (int batch = 0; batch < total; batch += _batchSize) {
      if (isCancelled?.call() == true) break;

      final futures = <Future<DiscoveredPrinter?>>[];
      for (int host = batch + 1;
          host <= batch + _batchSize && host <= total;
          host++) {
        futures.add(_probe('$subnet.$host'));
      }

      final batchResults = await Future.wait(futures);
      for (final r in batchResults) {
        if (r != null) results.add(r);
      }

      final probed = (batch + _batchSize).clamp(0, total);
      onProgress?.call(results.length, probed, total);
    }

    appLogger.info(
      'NetworkScannerService: scan complete — '
      '${results.length} Moonraker instance(s) found',
    );
    return results;
  }

  Future<DiscoveredPrinter?> _probe(String host) async {
    final base = 'http://$host:${AppConstants.defaultMoonrakerPort}';
    try {
      final response = await http
          .get(Uri.parse('$base/server/info'))
          .timeout(_probeTimeout);
      if (response.statusCode >= 500) return null;
      final name = _extractHostname(response.body) ?? host;
      return DiscoveredPrinter(httpUrl: base, displayName: name);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _extractSubnet(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  static String? _extractHostname(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      return result?['hostname'] as String?;
    } catch (_) {
      return null;
    }
  }
}
