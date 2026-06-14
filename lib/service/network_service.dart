// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../util/app_constants.dart';
import '../util/logger.dart';
import '../util/url_utils.dart';

part 'network_service.g.dart';

/// Represents the current reachability state of a printer's local address.
enum PrinterReachability {
  /// Reachable on the local network — no VPN needed.
  localReachable,

  /// Not reachable locally.  VPN may be required.
  localUnreachable,

  /// Currently checking.
  checking,
}

@riverpod
NetworkService networkService(Ref ref) {
  final service = NetworkService(ref);
  ref.onDispose(service.dispose);
  return service;
}

/// Continuously monitors whether a Moonraker instance is reachable on the
/// local network.  When it is not reachable the [VpnService] is notified so
/// it can auto-connect.
///
/// The check is a lightweight HTTP GET to `/server/info`.  No credentials are
/// sent during the probe — it just needs an HTTP 200 or 401 to confirm the
/// host is up.
class NetworkService {
  NetworkService(this._ref);

  final Ref _ref;
  Timer? _pollTimer;

  final _reachabilityController =
      StreamController<PrinterReachability>.broadcast();

  Stream<PrinterReachability> get reachabilityStream =>
      _reachabilityController.stream;

  PrinterReachability _last = PrinterReachability.checking;
  PrinterReachability get lastKnown => _last;

  /// Start polling [httpUrl] for reachability.
  void startPolling(String httpUrl) {
    _pollTimer?.cancel();
    _check(httpUrl);
    _pollTimer = Timer.periodic(
      AppConstants.reachabilityPollInterval,
      (_) => _check(httpUrl),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> isReachable(String httpUrl) async {
    try {
      final uri = Uri.parse('$httpUrl/server/info');
      final response = await http
          .get(uri)
          .timeout(AppConstants.localReachabilityTimeout);
      // 200 = ok, 401 = auth required (still reachable), anything else = up.
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<String?> discoverWebcamUrl(String httpUrl, {String? apiKey}) async {
    final baseUrl = httpUrl.replaceAll(RegExp(r'/$'), '');
    final headers = <String, String>{
      if (apiKey != null && apiKey.isNotEmpty) 'X-Api-Key': apiKey,
    };

    for (final endpoint in const [
      '/server/webcams/list',
      '/server/database/item?namespace=webcams',
    ]) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
            .timeout(AppConstants.localReachabilityTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final payload = jsonDecode(response.body);
        final webcamUrl = extractMoonrakerWebcamUrl(baseUrl, payload);
        if (webcamUrl != null) return webcamUrl;
      } catch (_) {
        // Best-effort discovery only.
      }
    }

    for (final relativePath in const [
      '/webcam/?action=stream',
      '/webcam?action=stream',
      '/webcam/stream',
      '/camera/?action=stream',
    ]) {
      final candidate = '$baseUrl$relativePath';
      try {
        final response = await http
            .head(Uri.parse(candidate), headers: headers)
            .timeout(AppConstants.localReachabilityTimeout);
        if (response.statusCode < 400) return candidate;
      } catch (_) {
        // Ignore fallback probe failures.
      }
    }

    return null;
  }

  Future<void> _check(String httpUrl) async {
    _emit(PrinterReachability.checking);
    final reachable = await isReachable(httpUrl);
    final next = reachable
        ? PrinterReachability.localReachable
        : PrinterReachability.localUnreachable;
    if (next != _last) {
      appLogger.info('NetworkService: reachability → $next ($httpUrl)');
    }
    _emit(next);
  }

  void _emit(PrinterReachability state) {
    _last = state;
    _reachabilityController.add(state);
  }

  void dispose() {
    _pollTimer?.cancel();
    _reachabilityController.close();
  }
}
