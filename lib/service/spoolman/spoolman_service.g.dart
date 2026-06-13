// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'spoolman_service.dart';

// ── Riverpod providers ────────────────────────────────────────────────────────

/// Family provider — one SpoolmanService per machine ID.
final spoolmanServiceProvider =
    Provider.family<SpoolmanService, String>((ref, machineId) {
  final machine = ref.watch(machineServiceProvider).findById(machineId);
  if (machine == null) {
    throw StateError('Unknown machine ID: $machineId');
  }
  return SpoolmanService(ref, machine);
});

/// Async provider that fetches all active spools for a machine.
final spoolmanSpoolsProvider =
    FutureProvider.family<List<SpoolmanSpool>, String>((ref, machineId) async {
  return ref.watch(spoolmanServiceProvider(machineId)).getSpools();
});
