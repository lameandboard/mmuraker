// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/dto/spoolman/spoolman_dtos.dart';
import '../../data/model/machine.dart';
import '../machine_service.dart';
import '../../util/url_utils.dart';

part 'spoolman_service.g.dart';

/// Service for the Spoolman filament manager REST API.
///
/// Spoolman runs alongside Moonraker; its URL is derived from the machine's
/// HTTP URL (default port 7912, or path /spoolman if proxied through Moonraker).
///
/// All features are free — no tier check, no paywall. See FeatureFlags.spoolman.
class SpoolmanService {
  SpoolmanService(this._ref, this._machine);

  final Ref _ref;
  final Machine _machine;
  String? _resolvedApiBaseUrl;

  String get _moonrakerBaseUrl => _machine.httpUrl.replaceAll(RegExp(r'/$'), '');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_machine.apiKey?.isNotEmpty == true)
          'X-Api-Key': _machine.apiKey!,
      };

  // ── Spools ─────────────────────────────────────────────────────────────────

  /// Fetch all spools. Optionally filter by [allowArchived].
  Future<List<SpoolmanSpool>> getSpools({bool allowArchived = false}) async {
    final resp = await _requestSpoolman(
      'GET',
      '/spool',
      queryParameters: {
        if (!allowArchived) 'allow_archived': 'false',
      },
    );
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => SpoolmanSpool.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpoolmanSpool> getSpool(int id) async {
    final resp = await _requestSpoolman('GET', '/spool/$id');
    return SpoolmanSpool.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Update spool usage — called after a print completes.
  /// [usedWeight] in grams.
  Future<SpoolmanSpool> updateSpoolUsage(
    int spoolId, {
    required double usedWeight,
  }) async {
    final resp = await _requestSpoolman(
      'PUT',
      '/spool/$spoolId/use',
      body: jsonEncode({'use_weight': usedWeight}),
    );
    return SpoolmanSpool.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Set the active spool in Moonraker.
  ///
  /// This calls the Moonraker spoolman endpoint, not Spoolman directly.
  Future<void> setActiveSpool(int spoolId) async {
    final httpUrl = _machine.httpUrl.replaceAll(RegExp(r'/$'), '');
    final resp = await http.post(
      Uri.parse('$httpUrl/server/spoolman/spool_id'),
      headers: _headers,
      body: jsonEncode({'spool_id': spoolId}),
    );
    _checkStatus(resp);
  }

  /// Clear the active spool assignment.
  Future<void> clearActiveSpool() async {
    final httpUrl = _machine.httpUrl.replaceAll(RegExp(r'/$'), '');
    final resp = await http.delete(
      Uri.parse('$httpUrl/server/spoolman/spool_id'),
      headers: _headers,
    );
    _checkStatus(resp);
  }

  // ── Filaments ──────────────────────────────────────────────────────────────

  Future<List<SpoolmanFilament>> getFilaments() async {
    final resp = await _requestSpoolman('GET', '/filament');
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => SpoolmanFilament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Vendors ────────────────────────────────────────────────────────────────

  Future<List<SpoolmanVendor>> getVendors() async {
    final resp = await _requestSpoolman('GET', '/vendor');
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => SpoolmanVendor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Stats helper ───────────────────────────────────────────────────────────

  Future<SpoolmanStats> getStats() async {
    final spools = await getSpools(allowArchived: false);
    final active = spools.where((s) => s.archived != true).toList();
    return SpoolmanStats(
      totalSpools: spools.length,
      activeSpools: active.length,
      totalUsedWeight:
          active.fold(0.0, (sum, s) => sum + (s.usedWeight ?? 0.0)),
      totalRemainingWeight:
          active.fold(0.0, (sum, s) => sum + (s.remainingWeight ?? 0.0)),
    );
  }

  void _checkStatus(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
          'Spoolman API error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<http.Response> _requestSpoolman(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    String? body,
  }) async {
    final candidates = await _candidateApiBaseUrls();
    Object? lastError;

    for (final baseUrl in candidates) {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters,
      );
      try {
        final response = switch (method.toUpperCase()) {
          'GET' => await http.get(uri, headers: _headers),
          'PUT' => await http.put(uri, headers: _headers, body: body),
          'POST' => await http.post(uri, headers: _headers, body: body),
          'DELETE' => await http.delete(uri, headers: _headers),
          _ => throw UnsupportedError('Unsupported method: $method'),
        };
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _resolvedApiBaseUrl = baseUrl;
          return response;
        }
        lastError =
            'Spoolman API error ${response.statusCode} from $baseUrl: ${response.body}';
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(lastError ?? 'Unable to connect to Spoolman API');
  }

  Future<List<String>> _candidateApiBaseUrls() async {
    final out = <String>[];
    if (_resolvedApiBaseUrl != null) {
      out.add(_resolvedApiBaseUrl!);
    }

    final discovered = await _discoverSpoolmanApiBaseUrl();
    if (discovered != null) {
      out.add(discovered);
    }

    out.add('$_moonrakerBaseUrl/spoolman/api/v1');

    final moonrakerUri = Uri.tryParse(_moonrakerBaseUrl);
    final host = moonrakerUri?.host;
    if (host != null && host.isNotEmpty) {
      final direct = Uri(
        scheme: (moonrakerUri?.scheme?.isNotEmpty == true)
            ? moonrakerUri!.scheme
            : 'http',
        host: host,
        port: 7912,
        path: '/api/v1',
      ).toString();
      out.add(direct);
    }

    return out.toSet().toList(growable: false);
  }

  Future<String?> _discoverSpoolmanApiBaseUrl() async {
    for (final endpoint in const ['/server/spoolman/status', '/server/config']) {
      try {
        final response = await http.get(
          Uri.parse('$_moonrakerBaseUrl$endpoint'),
          headers: _headers,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final payload = jsonDecode(response.body);
        final raw = _extractSpoolmanServerUrl(payload);
        if (raw == null || raw.isEmpty) continue;
        return _normaliseSpoolmanApiBase(raw);
      } catch (_) {
        // Best-effort discovery only.
      }
    }
    return null;
  }

  String? _extractSpoolmanServerUrl(Object? payload) {
    final root = _asMap(payload);
    if (root.isEmpty) return null;

    final direct = _firstString(root, const [
      'spoolman_url',
      'spoolmanUrl',
      'spoolman_server',
      'spoolmanServer',
    ]);
    if (direct != null) return _resolveAgainstMoonraker(direct);

    final spoolmanMap = _findNestedMapByKey(root, 'spoolman');
    if (spoolmanMap.isEmpty) return null;

    final value = _firstString(spoolmanMap, const [
      'server',
      'url',
      'api_url',
      'apiUrl',
      'endpoint',
      'address',
      'spoolman_url',
      'spoolmanUrl',
    ]);
    if (value == null || value.isEmpty) return null;
    return _resolveAgainstMoonraker(value);
  }

  String _resolveAgainstMoonraker(String url) {
    final resolved = absolutizeHttpUrl(_moonrakerBaseUrl, url);
    if (resolved != null) return resolved;
    return coerceHttpUrl(url);
  }

  String _normaliseSpoolmanApiBase(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl.replaceAll(RegExp(r'/$'), '');

    var path = uri.path.replaceAll(RegExp(r'/$'), '');
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('/api/v1')) {
      return uri.replace(path: path).toString();
    }
    if (lowerPath.endsWith('/api')) {
      path = '$path/v1';
      return uri.replace(path: path).toString();
    }
    if (lowerPath.endsWith('/v1')) {
      return uri.replace(path: path).toString();
    }
    if (path.isEmpty) {
      path = '/api/v1';
    } else {
      path = '$path/api/v1';
    }
    return uri.replace(path: path).toString();
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Map<String, dynamic> _findNestedMapByKey(Map<String, dynamic> root, String key) {
    if (root.containsKey(key)) {
      return _asMap(root[key]);
    }
    for (final value in root.values) {
      final nested = _asMap(value);
      if (nested.isEmpty) continue;
      final found = _findNestedMapByKey(nested, key);
      if (found.isNotEmpty) return found;
    }
    return const <String, dynamic>{};
  }
}
