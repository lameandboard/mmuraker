// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/model/machine.dart';
import '../../../data/model/vpn_config.dart';
import '../../../service/machine_service.dart';

class VpnSettingsPage extends ConsumerStatefulWidget {
  const VpnSettingsPage({super.key, required this.machineId});

  final String machineId;

  @override
  ConsumerState<VpnSettingsPage> createState() => _VpnSettingsPageState();
}

class _VpnSettingsPageState extends ConsumerState<VpnSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _wgConfigController = TextEditingController();
  final _ovpnConfigController = TextEditingController();
  final _ovpnUsernameController = TextEditingController();
  final _ovpnPasswordController = TextEditingController();
  final _serverAddressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _caCertController = TextEditingController();
  final _clientCertController = TextEditingController();
  final _clientKeyController = TextEditingController();
  final _pskController = TextEditingController();

  bool _ovpnPasswordObscured = true;
  bool _passwordObscured = true;
  bool _pskObscured = true;
  bool _initialised = false;
  bool _saving = false;
  VpnProtocol? _selectedProtocol;
  Machine? _machine;

  @override
  void dispose() {
    _wgConfigController.dispose();
    _ovpnConfigController.dispose();
    _ovpnUsernameController.dispose();
    _ovpnPasswordController.dispose();
    _serverAddressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _caCertController.dispose();
    _clientCertController.dispose();
    _clientKeyController.dispose();
    _pskController.dispose();
    super.dispose();
  }

  bool _ensureLoaded(MachineService machineService) {
    if (_initialised) return true;
    final machine = machineService.findById(widget.machineId);
    if (machine == null) return false;

    _machine = machine;
    final config = machine.vpnConfig;
    _selectedProtocol = config?.protocol;
    if (config != null) {
      _wgConfigController.text = config.wgConfigBlock ?? '';
      _ovpnConfigController.text = config.ovpnConfigBlock ?? '';
      _ovpnUsernameController.text = config.ovpnUsername ?? '';
      _ovpnPasswordController.text = config.ovpnPassword ?? '';
      _serverAddressController.text = config.serverAddress ?? '';
      _usernameController.text = config.username ?? '';
      _passwordController.text = config.password ?? '';
      _caCertController.text = config.ipsecCaCert ?? '';
      _clientCertController.text = config.ipsecClientCert ?? '';
      _clientKeyController.text = config.ipsecClientKey ?? '';
      _pskController.text = config.ipsecPsk ?? '';
    }
    _initialised = true;
    return true;
  }

  String? _requireValue(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final machine = _machine;
    if (machine == null) return;

    setState(() => _saving = true);
    try {
      machine.vpnConfig = switch (_selectedProtocol) {
        null => null,
        VpnProtocol.wireguard => VpnConfig.wireguard(
            configBlock: _wgConfigController.text.trim(),
          ),
        VpnProtocol.openVpn => VpnConfig.openVpn(
            configBlock: _ovpnConfigController.text.trim(),
            username: _ovpnUsernameController.text.trim().isEmpty
                ? null
                : _ovpnUsernameController.text.trim(),
            password: _ovpnPasswordController.text.trim().isEmpty
                ? null
                : _ovpnPasswordController.text.trim(),
          ),
        VpnProtocol.ikev2Eap => VpnConfig(
            protocol: VpnProtocol.ikev2Eap,
            label: 'IKEv2/IPSec EAP',
            serverAddress: _serverAddressController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            ipsecCaCert: _emptyToNull(_caCertController.text),
            ipsecClientCert: _emptyToNull(_clientCertController.text),
            ipsecClientKey: _emptyToNull(_clientKeyController.text),
          ),
        VpnProtocol.ikev2Psk => VpnConfig(
            protocol: VpnProtocol.ikev2Psk,
            label: 'IKEv2/IPSec PSK',
            serverAddress: _serverAddressController.text.trim(),
            ipsecPsk: _pskController.text.trim(),
            ipsecCaCert: _emptyToNull(_caCertController.text),
            ipsecClientCert: _emptyToNull(_clientCertController.text),
            ipsecClientKey: _emptyToNull(_clientKeyController.text),
          ),
        VpnProtocol.l2tpIpsecPsk => VpnConfig.l2tpIpsecPsk(
            serverAddress: _serverAddressController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            psk: _pskController.text.trim(),
          ),
        VpnProtocol.pptp => VpnConfig.pptp(
            serverAddress: _serverAddressController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          ),
      };

      await ref.read(machineServiceProvider).updateMachine(machine);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String text) {
    final t = text.trim();
    return t.isEmpty ? null : t;
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

    return Scaffold(
      appBar: AppBar(title: const Text('VPN Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_machine != null)
              Text(
                _machine!.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const Gap(12),
            DropdownButtonFormField<VpnProtocol?>(
              value: _selectedProtocol,
              decoration: const InputDecoration(
                labelText: 'Protocol',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<VpnProtocol?>(value: null, child: Text('None')),
                DropdownMenuItem<VpnProtocol?>(
                  value: VpnProtocol.wireguard,
                  child: Text('WireGuard'),
                ),
                DropdownMenuItem<VpnProtocol?>(
                  value: VpnProtocol.openVpn,
                  child: Text('OpenVPN'),
                ),
                DropdownMenuItem<VpnProtocol?>(
                  value: VpnProtocol.ikev2Eap,
                  child: Text('IKEv2/EAP'),
                ),
                DropdownMenuItem<VpnProtocol?>(
                  value: VpnProtocol.ikev2Psk,
                  child: Text('IKEv2/PSK'),
                ),
                DropdownMenuItem<VpnProtocol?>(
                  value: VpnProtocol.l2tpIpsecPsk,
                  child: Text('L2TP/IPSec PSK'),
                ),
                DropdownMenuItem<VpnProtocol?>(
                  value: VpnProtocol.pptp,
                  child: Text('PPTP ⚠️ Insecure'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedProtocol = value),
            ),
            const Gap(16),
            ...switch (_selectedProtocol) {
              null => [
                  _InfoCard(
                    icon: Icons.info_outline,
                    message:
                        'No VPN configured. The app will connect directly. Auto-VPN is disabled.',
                  ),
                ],
              VpnProtocol.wireguard => [
                  _InfoCard(
                    icon: Icons.info_outline,
                    message:
                        'Paste your WireGuard .conf content, or import it from a file.',
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _wgConfigController,
                    label: 'WireGuard Config (.conf)',
                    allowedExtensions: const ['conf', 'txt'],
                    minLines: 8,
                    maxLines: 14,
                    validator: (value) =>
                        _selectedProtocol == VpnProtocol.wireguard
                            ? _requireValue(value, 'WireGuard config')
                            : null,
                  ),
                ],
              VpnProtocol.openVpn => [
                  _InfoCard(
                    icon: Icons.info_outline,
                    message:
                        'Paste your .ovpn content or import it from a file. '
                        'Username/password are optional if auth is embedded.',
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _ovpnConfigController,
                    label: 'OpenVPN Config (.ovpn)',
                    allowedExtensions: const ['ovpn', 'conf', 'txt'],
                    minLines: 8,
                    maxLines: 14,
                    validator: (value) =>
                        _selectedProtocol == VpnProtocol.openVpn
                            ? _requireValue(value, 'OpenVPN config')
                            : null,
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _ovpnUsernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _ovpnPasswordController,
                    obscureText: _ovpnPasswordObscured,
                    decoration: InputDecoration(
                      labelText: 'Password (optional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() {
                          _ovpnPasswordObscured = !_ovpnPasswordObscured;
                        }),
                        icon: Icon(
                          _ovpnPasswordObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              VpnProtocol.ikev2Eap => [
                  _InfoCard(
                    icon: Icons.info_outline,
                    message: 'IKEv2 with EAP-MSCHAPv2 authentication. '
                        'CA certificate and client certificate are optional.',
                  ),
                  const Gap(12),
                  _serverField(required: true),
                  const Gap(12),
                  _usernameField(required: true),
                  const Gap(12),
                  _passwordField(
                    label: 'Password',
                    required: true,
                    obscured: _passwordObscured,
                    onToggle: () =>
                        setState(() => _passwordObscured = !_passwordObscured),
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _caCertController,
                    label: 'CA Certificate (PEM) — optional',
                    allowedExtensions: const ['pem', 'crt', 'cer', 'txt'],
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _clientCertController,
                    label: 'Client Certificate (PEM) — optional',
                    allowedExtensions: const ['pem', 'crt', 'cer', 'txt'],
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _clientKeyController,
                    label: 'Client Private Key (PEM) — optional',
                    allowedExtensions: const ['pem', 'key', 'txt'],
                  ),
                ],
              VpnProtocol.ikev2Psk => [
                  _serverField(required: true),
                  const Gap(12),
                  _passwordField(
                    controller: _pskController,
                    label: 'Pre-shared key',
                    required: true,
                    obscured: _pskObscured,
                    onToggle: () =>
                        setState(() => _pskObscured = !_pskObscured),
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _caCertController,
                    label: 'CA Certificate (PEM) — optional',
                    allowedExtensions: const ['pem', 'crt', 'cer', 'txt'],
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _clientCertController,
                    label: 'Client Certificate (PEM) — optional',
                    allowedExtensions: const ['pem', 'crt', 'cer', 'txt'],
                  ),
                  const Gap(12),
                  _CertFilePickerField(
                    controller: _clientKeyController,
                    label: 'Client Private Key (PEM) — optional',
                    allowedExtensions: const ['pem', 'key', 'txt'],
                  ),
                ],
              VpnProtocol.l2tpIpsecPsk => [
                  _serverField(required: true),
                  const Gap(12),
                  _usernameField(required: true),
                  const Gap(12),
                  _passwordField(
                    label: 'Password',
                    required: true,
                    obscured: _passwordObscured,
                    onToggle: () =>
                        setState(() => _passwordObscured = !_passwordObscured),
                  ),
                  const Gap(12),
                  _passwordField(
                    controller: _pskController,
                    label: 'IPSec Pre-shared key',
                    required: true,
                    obscured: _pskObscured,
                    onToggle: () =>
                        setState(() => _pskObscured = !_pskObscured),
                  ),
                ],
              VpnProtocol.pptp => [
                  const _WarningCard(
                    message:
                        'PPTP is insecure and not supported on Android 10+. '
                        'Use only on older devices or trusted networks.',
                  ),
                  const Gap(12),
                  _serverField(required: true),
                  const Gap(12),
                  _usernameField(required: true),
                  const Gap(12),
                  _passwordField(
                    label: 'Password',
                    required: true,
                    obscured: _passwordObscured,
                    onToggle: () =>
                        setState(() => _passwordObscured = !_passwordObscured),
                  ),
                ],
            },
            const Gap(24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Common field helpers ──────────────────────────────────────────────────

  Widget _serverField({required bool required}) {
    return TextFormField(
      controller: _serverAddressController,
      decoration: const InputDecoration(
        labelText: 'Server address',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          required ? _requireValue(value, 'Server address') : null,
    );
  }

  Widget _usernameField({required bool required}) {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          required ? _requireValue(value, 'Username') : null,
    );
  }

  Widget _passwordField({
    TextEditingController? controller,
    required String label,
    required bool required,
    required bool obscured,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller ?? _passwordController,
      obscureText: obscured,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) => required ? _requireValue(value, label) : null,
    );
  }
}

// ── Certificate / config file picker field ────────────────────────────────────

/// A text area pre-filled from a file picker.
///
/// Shows a multi-line [TextFormField] for manual paste, plus an
/// "Import from file" button that reads the selected file's text content
/// directly into the controller.
///
/// Supported file types should be text-based (PEM, .conf, .ovpn, .key, etc.).
/// Binary certificate formats such as PKCS#12 (.p12 / .pfx) are not
/// supported — export the certificate chain as PEM first.
class _CertFilePickerField extends StatelessWidget {
  const _CertFilePickerField({
    required this.controller,
    required this.label,
    this.allowedExtensions = const ['pem', 'crt', 'cer', 'key'],
    this.minLines = 4,
    this.maxLines = 10,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final List<String> allowedExtensions;
  final int minLines;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        // withData: true reads the file bytes into memory without needing a
        // file path – required on web and cleaner on mobile.
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not read the selected file.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      controller.text = utf8.decode(bytes, allowMalformed: false);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not import file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final extList = allowedExtensions.map((e) => '.$e').join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            hintText: '— paste here or import from file —',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          validator: validator,
        ),
        const Gap(4),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _pickFile(context),
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text('Import file ($extList)'),
          ),
        ),
      ],
    );
  }
}

// ── Info / warning cards ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Gap(12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 20)),
            const Gap(12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
