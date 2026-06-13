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
  final _caCertificateController = TextEditingController();
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
    _caCertificateController.dispose();
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
      _caCertificateController.text = config.ipsecCaCert ?? '';
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
        VpnProtocol.ikev2Eap => VpnConfig.ikev2Eap(
            serverAddress: _serverAddressController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            caCert: _caCertificateController.text.trim().isEmpty
                ? null
                : _caCertificateController.text.trim(),
          ),
        VpnProtocol.ikev2Psk => VpnConfig(
            protocol: VpnProtocol.ikev2Psk,
            label: 'IKEv2/IPSec PSK',
            serverAddress: _serverAddressController.text.trim(),
            ipsecPsk: _pskController.text.trim(),
            ipsecCaCert: _caCertificateController.text.trim().isEmpty
                ? null
                : _caCertificateController.text.trim(),
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
                    message: 'Paste your WireGuard .conf file content here',
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _wgConfigController,
                    minLines: 8,
                    maxLines: 14,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'WireGuard Config (.conf)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => _selectedProtocol == VpnProtocol.wireguard
                        ? _requireValue(value, 'WireGuard config')
                        : null,
                  ),
                ],
              VpnProtocol.openVpn => [
                  _InfoCard(
                    icon: Icons.info_outline,
                    message:
                        'Paste your .ovpn file content. Username/password are optional if auth is embedded.',
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _ovpnConfigController,
                    minLines: 8,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      labelText: 'OpenVPN Config (.ovpn)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => _selectedProtocol == VpnProtocol.openVpn
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
                    message: 'IKEv2 with EAP-MSCHAPv2 authentication',
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
                    onToggle: () => setState(() {
                      _passwordObscured = !_passwordObscured;
                    }),
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _caCertificateController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'CA Certificate (PEM)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
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
                    onToggle: () => setState(() {
                      _pskObscured = !_pskObscured;
                    }),
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _caCertificateController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'CA Certificate (PEM)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
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
                    onToggle: () => setState(() {
                      _passwordObscured = !_passwordObscured;
                    }),
                  ),
                  const Gap(12),
                  _passwordField(
                    controller: _pskController,
                    label: 'IPSec Pre-shared key',
                    required: true,
                    obscured: _pskObscured,
                    onToggle: () => setState(() {
                      _pskObscured = !_pskObscured;
                    }),
                  ),
                ],
              VpnProtocol.pptp => [
                  const _WarningCard(
                    message:
                        'PPTP is insecure and not supported on Android 10+. Use only on older devices or trusted networks.',
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
                    onToggle: () => setState(() {
                      _passwordObscured = !_passwordObscured;
                    }),
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

  Widget _serverField({required bool required}) {
    return TextFormField(
      controller: _serverAddressController,
      decoration: const InputDecoration(
        labelText: 'Server address',
        border: OutlineInputBorder(),
      ),
      validator: (value) => required ? _requireValue(value, 'Server address') : null,
    );
  }

  Widget _usernameField({required bool required}) {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username',
        border: OutlineInputBorder(),
      ),
      validator: (value) => required ? _requireValue(value, 'Username') : null,
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
            obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) => required ? _requireValue(value, label) : null,
    );
  }
}

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
