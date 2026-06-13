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

  /// Base URL for the Spoolman API, auto-derived from the machine HTTP URL.
  ///
  /// Uses the Moonraker proxy path (`/spoolman/api/v1`).
  String get _baseUrl {
    final httpUrl = _machine.httpUrl.replaceAll(RegExp(r'/$'), '');
    // Moonraker proxies Spoolman at /spoolman
    return '$httpUrl/spoolman/api/v1';
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_machine.apiKey?.isNotEmpty == true)
          'X-Api-Key': _machine.apiKey!,
      };

  // ── Spools ─────────────────────────────────────────────────────────────────

  /// Fetch all spools. Optionally filter by [allowArchived].
  Future<List<SpoolmanSpool>> getSpools({bool allowArchived = false}) async {
    final uri = Uri.parse('$_baseUrl/spool').replace(queryParameters: {
      if (!allowArchived) 'allow_archived': 'false',
    });
    final resp = await http.get(uri, headers: _headers);
    _checkStatus(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => SpoolmanSpool.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpoolmanSpool> getSpool(int id) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/spool/$id'),
      headers: _headers,
    );
    _checkStatus(resp);
    return SpoolmanSpool.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Update spool usage — called after a print completes.
  /// [usedWeight] in grams.
  Future<SpoolmanSpool> updateSpoolUsage(
    int spoolId, {
    required double usedWeight,
  }) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/spool/$spoolId/use'),
      headers: _headers,
      body: jsonEncode({'use_weight': usedWeight}),
    );
    _checkStatus(resp);
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
    final resp =
        await http.get(Uri.parse('$_baseUrl/filament'), headers: _headers);
    _checkStatus(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => SpoolmanFilament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Vendors ────────────────────────────────────────────────────────────────

  Future<List<SpoolmanVendor>> getVendors() async {
    final resp =
        await http.get(Uri.parse('$_baseUrl/vendor'), headers: _headers);
    _checkStatus(resp);
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
}
