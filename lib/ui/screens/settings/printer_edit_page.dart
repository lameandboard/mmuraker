// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/model/machine.dart';
import '../../../data/model/vpn_config.dart';
import '../../../routing/app_router.dart';
import '../../../service/machine_service.dart';
import '../../../service/network_service.dart';
import '../../../util/app_constants.dart';
import '../../../util/logger.dart';

class PrinterEditPage extends ConsumerStatefulWidget {
  const PrinterEditPage({super.key, this.machineId});

  final String? machineId;

  @override
  ConsumerState<PrinterEditPage> createState() => _PrinterEditPageState();
}

class _PrinterEditPageState extends ConsumerState<PrinterEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _httpUrlController = TextEditingController();
  final _wsUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _webcamUrlController = TextEditingController();

  bool _apiKeyObscured = true;
  bool _saving = false;
  bool _testingConnection = false;
  bool _initialised = false;
  bool _syncingWs = false;
  bool _wsManuallyEdited = false;
  String? _currentMachineId;
  VpnConfig? _vpnConfig;

  @override
  void initState() {
    super.initState();
    _currentMachineId = widget.machineId;
    _httpUrlController.addListener(_handleHttpUrlChanged);
    _wsUrlController.addListener(_handleWsUrlChanged);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _httpUrlController.dispose();
    _wsUrlController.dispose();
    _apiKeyController.dispose();
    _webcamUrlController.dispose();
    super.dispose();
  }

  void _handleHttpUrlChanged() {
    if (_wsManuallyEdited) return;
    final derived = _deriveWsUrl(_httpUrlController.text.trim());
    if (_wsUrlController.text.trim() == derived) return;
    _syncingWs = true;
    _wsUrlController.text = derived;
    _wsUrlController.selection = TextSelection.collapsed(
      offset: _wsUrlController.text.length,
    );
    _syncingWs = false;
  }

  void _handleWsUrlChanged() {
    if (_syncingWs) return;
    _wsManuallyEdited =
        _wsUrlController.text.trim() != _deriveWsUrl(_httpUrlController.text.trim());
  }

  bool _ensureLoaded(MachineService machineService) {
    if (_initialised) return true;
    if (_currentMachineId == null) {
      _initialised = true;
      _handleHttpUrlChanged();
      return true;
    }

    final machine = machineService.findById(_currentMachineId!);
    if (machine == null) return false;

    _displayNameController.text = machine.name;
    _httpUrlController.text = machine.httpUrl;
    _syncingWs = true;
    _wsUrlController.text = machine.wsUrl;
    _syncingWs = false;
    _apiKeyController.text = machine.apiKey ?? '';
    _webcamUrlController.text = machine.webcamUrl ?? '';
    _vpnConfig = machine.vpnConfig;
    _wsManuallyEdited = machine.wsUrl != _deriveWsUrl(machine.httpUrl);
    _initialised = true;
    return true;
  }

  Future<Machine?> _persistMachine({required bool popAfterSave}) async {
    final machineService = ref.read(machineServiceProvider);
    if (!_formKey.currentState!.validate()) return null;

    setState(() => _saving = true);
    try {
      final displayName = _displayNameController.text.trim();
      final httpUrl = _httpUrlController.text.trim();
      final apiKey = _emptyToNull(_apiKeyController.text);
      final webcamUrl = _emptyToNull(_webcamUrlController.text);
      final port = _extractPort(httpUrl);
      final normalisedHttpUrl = _normaliseHttpUrl(httpUrl, port);
      final wsUrl = _wsManuallyEdited
          ? _wsUrlController.text.trim()
          : _deriveWsUrl(normalisedHttpUrl);

      Machine machine;
      if (_currentMachineId == null) {
        machine = await machineService.addMachine(
          name: displayName,
          httpUrl: httpUrl,
          port: port,
          apiKey: apiKey,
          vpnConfig: _vpnConfig,
          webcamUrl: webcamUrl,
        );
        _currentMachineId = machine.id;
      } else {
        final existing = machineService.findById(_currentMachineId!);
        if (existing == null) return null;
        machine = existing;
      }

      machine
        ..name = displayName
        ..httpUrl = normalisedHttpUrl
        ..wsUrl = wsUrl
        ..port = port
        ..apiKey = apiKey
        ..vpnConfig = _vpnConfig
        ..webcamUrl = webcamUrl;

      await machineService.updateMachine(machine);

      if (!mounted) return machine;
      if (popAfterSave) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer saved.')),
        );
        setState(() {});
      }
      return machine;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openVpnSettings() async {
    final machine = await _persistMachine(popAfterSave: false);
    if (machine == null || !mounted) return;

    await context.push('${Routes.vpnSettings}/${machine.id}');

    final refreshed = ref.read(machineServiceProvider).findById(machine.id);
    if (mounted) {
      setState(() {
        _vpnConfig = refreshed?.vpnConfig;
      });
    }
  }

  Future<void> _testConnection() async {
    final httpUrl = _httpUrlController.text.trim();
    final urlError = _validateHttpUrl(httpUrl);
    if (urlError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(urlError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _testingConnection = true);
    try {
      final normalisedHttpUrl = _normaliseHttpUrl(
        httpUrl,
        _extractPort(httpUrl),
      );
      final reachable =
          await ref.read(networkServiceProvider).isReachable(normalisedHttpUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reachable
                ? 'Connection successful! Printer is reachable.'
                : 'Connection failed. Check the URL and network settings.',
          ),
          backgroundColor: reachable
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  Future<void> _deletePrinter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Printer?'),
        content: const Text(
          'This will permanently remove the printer configuration.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => ctx.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(machineServiceProvider).deleteMachine(_currentMachineId!);
      if (mounted) context.pop();
    } catch (error, stackTrace) {
      appLogger.error(
        'Failed to delete printer ${_currentMachineId!}',
        error,
        stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete printer. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int _extractPort(String httpUrl) {
    final uri = Uri.tryParse(httpUrl);
    if (uri != null && uri.hasPort) return uri.port;
    return AppConstants.defaultMoonrakerPort;
  }

  String _deriveWsUrl(String httpUrl) {
    final uri = Uri.tryParse(httpUrl);
    if (uri == null || uri.host.isEmpty) return '';
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? uri.port : AppConstants.defaultMoonrakerPort;
    final portSuffix = port == 80 || port == 443 ? '' : ':$port';
    return '$scheme://${uri.host}$portSuffix${AppConstants.moonrakerWsPath}';
  }

  String _normaliseHttpUrl(String httpUrl, int port) {
    final uri = Uri.parse(httpUrl);
    final base = '${uri.scheme}://${uri.host}';
    final portSuffix = uri.hasPort
        ? ':${uri.port}'
        : (port == 80 || port == 443 ? '' : ':$port');
    return '$base$portSuffix';
  }

  String? _validateHttpUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'HTTP URL is required.';
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid HTTP URL.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://';
    }
    return null;
  }

  String? _validateWsUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'WebSocket URL is required.';
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid WebSocket URL.';
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      return 'URL must start with ws:// or wss://';
    }
    return null;
  }

  String? _validateOptionalHttpUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid URL.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://';
    }
    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final machineService = ref.watch(machineServiceProvider);

    try {
      if (!_ensureLoaded(machineService)) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
    } catch (_) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isEditing = _currentMachineId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Printer' : 'Add Printer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Display name is required.' : null,
            ),
            const Gap(16),
            TextFormField(
              controller: _httpUrlController,
              decoration: const InputDecoration(
                labelText: 'HTTP URL e.g. http://192.168.1.100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: _validateHttpUrl,
            ),
            const Gap(16),
            TextFormField(
              controller: _wsUrlController,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL e.g. ws://192.168.1.100/websocket',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: _validateWsUrl,
            ),
            const Gap(16),
            TextFormField(
              controller: _apiKeyController,
              obscureText: _apiKeyObscured,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() {
                    _apiKeyObscured = !_apiKeyObscured;
                  }),
                  icon: Icon(
                    _apiKeyObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const Gap(16),
            TextFormField(
              controller: _webcamUrlController,
              decoration: const InputDecoration(
                labelText: 'Webcam URL',
                hintText: 'http://192.168.1.100/webcam/?action=stream',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: _validateOptionalHttpUrl,
            ),
            const Gap(16),
            OutlinedButton.icon(
              onPressed: _saving ? null : _openVpnSettings,
              icon: const Icon(Icons.vpn_lock_outlined),
              label: Text(
                _vpnConfig == null
                    ? 'Configure VPN'
                    : 'Configure VPN (${_vpnConfig!.protocolDisplayName})',
              ),
            ),
            const Gap(12),
            OutlinedButton.icon(
              onPressed: (_saving || _testingConnection) ? null : _testConnection,
              icon: _testingConnection
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check_outlined),
              label: Text(_testingConnection ? 'Testing...' : 'Test Connection'),
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: _saving ? null : () => _persistMachine(popAfterSave: true),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save'),
            ),
            if (isEditing) ...[
              const Gap(12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onPressed: (_saving || _testingConnection) ? null : _deletePrinter,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Printer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
