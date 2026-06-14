// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../../../../data/dto/machine/printer.dart';
import '../../../../service/moonraker/printer_service.dart';
import '../../../components/common_widgets.dart';

class MotionSystemsCard extends HookWidget {
  const MotionSystemsCard({
    super.key,
    required this.printer,
    required this.printerService,
    required this.availableObjects,
    this.bedMesh,
    this.probe,
    this.quadGantryLevel,
    this.zTilt,
  });

  final Printer printer;
  final PrinterService printerService;
  final List<String> availableObjects;
  final Map<String, dynamic>? bedMesh;
  final Map<String, dynamic>? probe;
  final Map<String, dynamic>? quadGantryLevel;
  final Map<String, dynamic>? zTilt;

  @override
  Widget build(BuildContext context) {
    final busyAction = useState<String?>(null);
    final homedAxes = <String>[
      if (printer.toolhead.homedX) 'X',
      if (printer.toolhead.homedY) 'Y',
      if (printer.toolhead.homedZ) 'Z',
    ];
    final meshProfile = bedMesh?['profile_name']?.toString();
    final supportsProbe = _hasAnyObject(const ['probe', 'bltouch']);
    final supportsBedMesh = availableObjects.contains('bed_mesh');
    final supportsZTilt = availableObjects.contains('z_tilt');
    final supportsQuadGantry = availableObjects.contains('quad_gantry_level');
    final supportsScrewsTilt = availableObjects.contains('screws_tilt_adjust');

    Future<void> runAction(String label, String command) async {
      if (busyAction.value != null) return;
      busyAction.value = label;
      try {
        await printerService.sendGcode(command);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to run $command: $error')),
          );
        }
      } finally {
        busyAction.value = null;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Motion & Leveling'),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AxisChip(label: 'X', value: printer.toolhead.position[0]),
                _AxisChip(label: 'Y', value: printer.toolhead.position[1]),
                _AxisChip(label: 'Z', value: printer.toolhead.position[2]),
                Chip(
                  label: Text(
                    homedAxes.isEmpty ? 'Not homed' : 'Homed ${homedAxes.join('/')}',
                  ),
                  avatar: Icon(
                    homedAxes.length == 3 ? Icons.check_circle : Icons.home_outlined,
                    size: 18,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionButton(
                  label: 'Home All',
                  icon: Icons.home_filled,
                  busy: busyAction.value == 'home_all',
                  onPressed: () => runAction('home_all', 'G28'),
                ),
                for (final axis in const ['X', 'Y', 'Z'])
                  _ActionButton(
                    label: 'Home $axis',
                    icon: Icons.straighten,
                    busy: busyAction.value == 'home_$axis',
                    onPressed: () => runAction('home_$axis', 'G28 $axis'),
                  ),
              ],
            ),
            if (supportsProbe ||
                supportsBedMesh ||
                supportsZTilt ||
                supportsQuadGantry ||
                supportsScrewsTilt) ...[
              const Gap(16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (supportsQuadGantry)
                    _ActionButton(
                      label: 'Quad Gantry',
                      icon: Icons.align_vertical_bottom,
                      busy: busyAction.value == 'quad_gantry_level',
                      onPressed: () => runAction(
                        'quad_gantry_level',
                        'QUAD_GANTRY_LEVEL',
                      ),
                    ),
                  if (supportsZTilt)
                    _ActionButton(
                      label: 'Z Tilt',
                      icon: Icons.unfold_more,
                      busy: busyAction.value == 'z_tilt_adjust',
                      onPressed: () => runAction('z_tilt_adjust', 'Z_TILT_ADJUST'),
                    ),
                  if (supportsScrewsTilt)
                    _ActionButton(
                      label: 'Screws Tilt',
                      icon: Icons.grid_4x4,
                      busy: busyAction.value == 'screws_tilt_adjust',
                      onPressed: () => runAction(
                        'screws_tilt_adjust',
                        'SCREWS_TILT_CALCULATE',
                      ),
                    ),
                  if (supportsBedMesh)
                    _ActionButton(
                      label: 'Bed Mesh',
                      icon: Icons.grid_view,
                      busy: busyAction.value == 'bed_mesh_calibrate',
                      onPressed: () => runAction(
                        'bed_mesh_calibrate',
                        'BED_MESH_CALIBRATE',
                      ),
                    ),
                  if (supportsProbe)
                    _ActionButton(
                      label: 'Probe Calibrate',
                      icon: Icons.center_focus_strong,
                      busy: busyAction.value == 'probe_calibrate',
                      onPressed: () => runAction(
                        'probe_calibrate',
                        'PROBE_CALIBRATE',
                      ),
                    ),
                ],
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (supportsQuadGantry)
                    _StatusChip(
                      label: 'Quad gantry',
                      value: quadGantryLevel?['applied'] == true ? 'Applied' : 'Needs run',
                    ),
                  if (supportsZTilt)
                    _StatusChip(
                      label: 'Z tilt',
                      value: zTilt?['applied'] == true ? 'Applied' : 'Needs run',
                    ),
                  if (supportsBedMesh)
                    _StatusChip(
                      label: 'Bed mesh',
                      value: meshProfile?.isNotEmpty == true ? meshProfile! : 'Not loaded',
                    ),
                  if (supportsProbe)
                    _StatusChip(
                      label: 'Probe',
                      value: probe?['last_z_result']?.toString() ?? 'Ready',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasAnyObject(List<String> candidates) {
    for (final candidate in candidates) {
      if (availableObjects.contains(candidate)) return true;
    }
    return false;
  }
}

class _AxisChip extends StatelessWidget {
  const _AxisChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label ${value.toStringAsFixed(2)}'),
      avatar: const Icon(Icons.place_outlined, size: 18),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
