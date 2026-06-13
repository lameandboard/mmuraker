// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mmu_state.freezed.dart';

/// Represents the real-time state of a Multi-Material Unit (MMU) as surfaced
/// by Klipper/Moonraker objects (e.g. `mmu`, `mmu_state`, Happy Hare, etc.).
///
/// When no MMU object is present the [PrinterService] leaves this null on
/// [Printer.mmuState] and sets [Printer.hasMmu] to false.
@freezed
class MmuState with _$MmuState {
  const factory MmuState({
    /// Currently selected tool (0-based). -1 means no tool selected / bypass.
    @Default(-1) int activeTool,

    /// Number of filament slots/gates on the unit.
    @Default(0) int toolCount,

    /// Whether the MMU is currently performing a filament operation.
    @Default(false) bool busy,

    /// Top-level MMU error string, if any.
    String? error,

    /// Human-readable sub-state string from Happy Hare / similar firmware.
    /// Examples: "idle", "loading", "unloading", "homing", "pause_locked".
    @Default('unknown') String printState,

    /// Filament colour for each tool slot (hex ARGB or RRGGBB string).
    /// May be empty when colour metadata is not available.
    @Default([]) List<String> filamentColors,

    /// Loaded/present state for each gate.
    @Default([]) List<MmuGateState> gateStates,

    /// Name of the detected MMU object key in Moonraker.
    /// Examples: "mmu", "filament_switch_sensor mmu_pre_gate_0", etc.
    @Default('mmu') String objectKey,
  }) = _MmuState;

  const MmuState._();

  /// Returns a list of [MmuTool] view-models for the given [toolCount].
  List<MmuTool> get tools => List.generate(
        toolCount,
        (i) => MmuTool(
          index: i,
          isActive: i == activeTool,
          color: i < filamentColors.length ? filamentColors[i] : null,
          gateState: i < gateStates.length ? gateStates[i] : MmuGateState.unknown,
        ),
      );
}

/// View-model for a single MMU tool / gate slot.
@freezed
class MmuTool with _$MmuTool {
  const factory MmuTool({
    required int index,
    @Default(false) bool isActive,
    String? color,
    @Default(MmuGateState.unknown) MmuGateState gateState,
  }) = _MmuTool;

  const MmuTool._();

  /// G-code macro name to select this tool (T0, T1, …).
  String get toolMacro => 'T$index';
}

/// Filament state for each gate on the MMU.
enum MmuGateState {
  /// Gate is loaded with filament.
  loaded,

  /// Gate has no filament.
  empty,

  /// Filament present but not loaded into the extruder.
  available,

  /// State is not known.
  unknown,
}
