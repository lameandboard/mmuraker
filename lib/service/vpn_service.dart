// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';

import '../data/model/vpn_config.dart';
import '../util/app_constants.dart';
import '../util/feature_flags.dart';
import '../util/logger.dart';
import 'network_service.dart';

part 'vpn_service.g.dart';

/// The current state of the WireGuard auto-VPN tunnel.
enum VpnTunnelState {
  /// No VPN config is saved; feature is configured but idle.
  notConfigured,

  /// Printer is reachable locally — VPN is not needed.
  idle,

  /// Attempting to bring up the tunnel.
  connecting,

  /// Tunnel is up and active.
  connected,

  /// Tunnel failed or was disconnected.
  error,
}

@riverpod
VpnService vpnService(Ref ref) {
  final service = VpnService(ref);
  ref.onDispose(service.dispose);
  return service;
}

/// Manages the WireGuard auto-VPN tunnel.
///
/// Policy (always free — see [FeatureFlags.autoVpn]):
///   1. If the printer is reachable on the local network → do nothing.
///   2. If the printer is NOT reachable AND a [VpnConfig] with
///      [VpnConfig.autoConnect] == true is stored → start the tunnel.
///   3. Once the printer is reachable locally again → optionally tear down
///      the tunnel to save battery.
///
/// WireGuard® is a registered trademark of Jason A. Donenfeld.
/// This service uses the `wireguard_flutter` plugin (MIT).
class VpnService {
  VpnService(this._ref) {
    assert(FeatureFlags.autoVpn, 'Auto-VPN feature flag must be true');
  }

  final Ref _ref;

  final _stateController = StreamController<VpnTunnelState>.broadcast();
  Stream<VpnTunnelState> get stateStream => _stateController.stream;

  VpnTunnelState _state = VpnTunnelState.idle;
  VpnTunnelState get state => _state;

  StreamSubscription<PrinterReachability>? _reachabilitySub;

  /// Attach to the [NetworkService] stream for a specific machine and
  /// auto-manage the VPN tunnel based on reachability.
  void attachToMachine({
    required String httpUrl,
    required VpnConfig? vpnConfig,
  }) {
    _reachabilitySub?.cancel();

    if (vpnConfig == null || !vpnConfig.autoConnect) {
      _setState(VpnTunnelState.notConfigured);
      return;
    }

    final networkService = _ref.read(networkServiceProvider);
    networkService.startPolling(httpUrl);

    _reachabilitySub = networkService.reachabilityStream.listen((reachability) {
      _handleReachabilityChange(reachability, vpnConfig);
    });
  }

  void detach() {
    _reachabilitySub?.cancel();
    _reachabilitySub = null;
    _ref.read(networkServiceProvider).stopPolling();
  }

  Future<void> _handleReachabilityChange(
    PrinterReachability reachability,
    VpnConfig vpnConfig,
  ) async {
    switch (reachability) {
      case PrinterReachability.localReachable:
        // Printer is on LAN — disconnect VPN if it was active (save battery).
        if (_state == VpnTunnelState.connected) {
          await _disconnect();
        } else {
          _setState(VpnTunnelState.idle);
        }

      case PrinterReachability.localUnreachable:
        // Printer unreachable locally → bring up VPN.
        if (_state != VpnTunnelState.connected &&
            _state != VpnTunnelState.connecting) {
          await _connect(vpnConfig);
        }

      case PrinterReachability.checking:
        break;
    }
  }

  /// Manually connect with [config].
  Future<void> connect(VpnConfig config) => _connect(config);

  /// Manually disconnect.
  Future<void> disconnect() => _disconnect();

  Future<void> _connect(VpnConfig config) async {
    if (config.protocol != VpnProtocol.wireguard) {
      logger.warning(
        'VpnService: unsupported protocol for auto-connect: ${config.protocol}',
      );
      _setState(VpnTunnelState.notConfigured);
      return;
    }
    final wgConfigBlock = config.wgConfigBlock?.trim();
    if (wgConfigBlock == null || wgConfigBlock.isEmpty) {
      logger.warning('VpnService: missing WireGuard config block');
      _setState(VpnTunnelState.notConfigured);
      return;
    }

    _setState(VpnTunnelState.connecting);
    logger.info('VpnService: starting WireGuard tunnel "${config.label}"');
    try {
      await WireGuardFlutter.instance.initialize(interfaceName: 'mmuraker0');
      await WireGuardFlutter.instance.startVpn(
        serverAddress: _extractEndpointAddress(wgConfigBlock),
        wgQuickConfig: wgConfigBlock,
        providerBundleIdentifier: 'com.mmuraker.android.network',
      );
      _setState(VpnTunnelState.connected);
      logger.info('VpnService: tunnel up');
    } catch (e, st) {
      logger.error('VpnService: failed to start tunnel', e, st);
      _setState(VpnTunnelState.error);
    }
  }

  Future<void> _disconnect() async {
    logger.info('VpnService: stopping WireGuard tunnel');
    try {
      await WireGuardFlutter.instance.stopVpn();
      _setState(VpnTunnelState.idle);
      logger.info('VpnService: tunnel down');
    } catch (e, st) {
      logger.error('VpnService: failed to stop tunnel', e, st);
    }
  }

  void _setState(VpnTunnelState next) {
    _state = next;
    _stateController.add(next);
  }

  /// Extract the `Endpoint` host from a WireGuard config block for display.
  static String _extractEndpointAddress(String config) {
    final match = RegExp(r'Endpoint\s*=\s*([^\s:]+)').firstMatch(config);
    return match?.group(1) ?? 'unknown';
  }

  void dispose() {
    _reachabilitySub?.cancel();
    _stateController.close();
  }
}
