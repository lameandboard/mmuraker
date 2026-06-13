// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../data/model/machine.dart';
import '../data/model/vpn_config.dart';
import '../util/app_constants.dart';
import '../util/logger.dart';

part 'machine_service.g.dart';

@riverpod
MachineService machineService(Ref ref) => MachineService(ref);

/// Manages the list of configured Klipper/Moonraker printers.
///
/// Machines are persisted in a Hive box so they survive app restarts.
/// Architecture note: mirrors the MachineService concept from mobileraker's
/// `common/lib/service/machine_service.dart`, simplified and ad/paywall-free.
class MachineService {
  MachineService(this._ref) {
    _initFuture = _init();
  }

  final Ref _ref;
  late final Future<void> _initFuture;
  Box<Machine>? _box;

  static const _uuid = Uuid();

  Future<void> _init() async {
    if (!Hive.isAdapterRegistered(AppConstants.machineAdapterId)) {
      Hive.registerAdapter(MachineAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.vpnConfigAdapterId)) {
      Hive.registerAdapter(VpnConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.vpnProtocolAdapterId)) {
      Hive.registerAdapter(VpnProtocolAdapter());
    }
    _box = await Hive.openBox<Machine>(AppConstants.machineBoxName);
    logger.info('MachineService: loaded ${_box!.length} machine(s)');
  }

  /// All saved machines.
  List<Machine> get machines => _box?.values.toList() ?? const [];

  /// Find a machine by its [id].
  Machine? findById(String id) =>
      _box?.values.cast<Machine?>().firstWhere(
        (m) => m?.id == id,
        orElse: () => null,
      );

  /// Add a new machine.  Returns the saved [Machine].
  Future<Machine> addMachine({
    required String name,
    required String httpUrl,
    int port = AppConstants.defaultMoonrakerPort,
    String? apiKey,
    VpnConfig? vpnConfig,
    String? webcamUrl,
  }) async {
    await _initFuture;
    final box = _box;
    if (box == null) {
      throw StateError('MachineService is not initialized');
    }
    final wsUrl = _buildWsUrl(httpUrl, port);
    final machine = Machine(
      id: _uuid.v4(),
      name: name,
      httpUrl: _normaliseUrl(httpUrl, port),
      wsUrl: wsUrl,
      port: port,
      apiKey: apiKey,
      vpnConfig: vpnConfig,
      webcamUrl: webcamUrl?.trim().isEmpty == true ? null : webcamUrl?.trim(),
    );
    await box.put(machine.id, machine);
    logger.info('MachineService: added machine "${machine.name}"');
    return machine;
  }

  /// Update an existing machine.
  Future<void> updateMachine(Machine machine) async {
    await _initFuture;
    final box = _box;
    if (box == null) {
      throw StateError('MachineService is not initialized');
    }
    await box.put(machine.id, machine);
    logger.info('MachineService: updated machine "${machine.name}"');
  }

  /// Delete a machine by id.
  Future<void> deleteMachine(String id) async {
    await _initFuture;
    final box = _box;
    if (box == null) {
      throw StateError('MachineService is not initialized');
    }
    await box.delete(id);
    logger.info('MachineService: deleted machine $id');
  }

  /// Save (or replace) the WireGuard VPN config for a machine.
  Future<void> saveVpnConfig(String machineId, VpnConfig config) async {
    final machine = findById(machineId);
    if (machine == null) return;
    machine.vpnConfig = config;
    await machine.save();
    logger.info('MachineService: saved VPN config for "${machine.name}"');
  }

  /// Remove the VPN config from a machine.
  Future<void> clearVpnConfig(String machineId) async {
    final machine = findById(machineId);
    if (machine == null) return;
    machine.vpnConfig = null;
    await machine.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _normaliseUrl(String url, int port) {
    var u = url.trim();
    if (!u.startsWith('http')) u = 'http://$u';
    // Strip any trailing slash.
    u = u.replaceAll(RegExp(r'/+$'), '');
    // Append port only if not already present and not the default 80/443.
    if (!RegExp(r':\d+$').hasMatch(u) && port != 80 && port != 443) {
      u = '$u:$port';
    }
    return u;
  }

  static String _buildWsUrl(String httpUrl, int port) {
    final normalised = _normaliseUrl(httpUrl, port);
    return normalised
        .replaceFirst(RegExp('^http://'), 'ws://')
        .replaceFirst(RegExp('^https://'), 'wss://')
        + AppConstants.moonrakerWsPath;
  }
}
