// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'mmu/mmu_state.dart';

part 'printer.freezed.dart';

/// Snapshot of the full printer state as received from Moonraker.
///
/// Architecture note: inspired by the printer DTO in mobileraker's
/// `common/lib/data/dto/machine/` package.
@freezed
class Printer with _$Printer {
  const factory Printer({
    /// Whether Klipper is ready to accept commands.
    @Default(false) bool klippyReady,

    /// Human-readable Klipper state string (e.g. "ready", "error", "shutdown").
    @Default('disconnected') String klippyState,

    /// Optional Klipper state message / error text.
    String? klippyStateMessage,

    /// Current toolhead data.
    @Default(Toolhead()) Toolhead toolhead,

    /// Extruder list – index 0 is the primary extruder.
    @Default([]) List<Extruder> extruders,

    /// Current print job state (e.g. "printing", "paused", "complete").
    @Default('idle') String printState,

    /// Print progress 0.0–1.0.
    @Default(0) double printProgress,

    /// Estimated time remaining in seconds.
    int? eta,

    /// Heated bed temperature info.
    TemperatureSensor? heatedBed,

    /// MMU state – null when no MMU is detected.
    MmuState? mmuState,

    /// Whether an MMU-capable setup was detected.
    @Default(false) bool hasMmu,

    /// Raw list of available Moonraker objects (used for MMU detection).
    @Default([]) List<String> availableObjects,

    /// Available G-code macros (used for MMU tool-change detection).
    @Default([]) List<String> availableMacros,
  }) = _Printer;

  const Printer._();

  /// Active extruder index derived from toolhead.
  int get activeExtruderIndex => toolhead.activeExtruderIndex;

  /// Active [Extruder] or the first one as fallback.
  Extruder get activeExtruder {
    if (extruders.isEmpty) return const Extruder();
    final idx = activeExtruderIndex;
    if (idx < extruders.length) return extruders[idx];
    return extruders.first;
  }
}

/// Toolhead state.
@freezed
class Toolhead with _$Toolhead {
  const factory Toolhead({
    /// Active extruder name as reported by Klipper (e.g. "extruder", "extruder1").
    @Default('extruder') String activeExtruder,

    /// Position [x, y, z, e].
    @Default([0, 0, 0, 0]) List<double> position,

    /// Whether homing has been completed on each axis.
    @Default(false) bool homedX,
    @Default(false) bool homedY,
    @Default(false) bool homedZ,

    /// Actual print speed in mm/s.
    @Default(0) double printSpeed,

    /// Speed factor override 0.0–2.0+ (1.0 = 100 %).
    @Default(1.0) double speedFactor,

    /// Extrusion factor override 0.0–2.0+ (1.0 = 100 %).
    @Default(1.0) double extrudeFactor,
  }) = _Toolhead;

  const Toolhead._();

  /// Parses the active extruder name into a zero-based index.
  /// "extruder" → 0, "extruder1" → 1, etc.
  int get activeExtruderIndex {
    if (activeExtruder == 'extruder') return 0;
    final suffix = activeExtruder.replaceFirst('extruder', '');
    return int.tryParse(suffix) ?? 0;
  }
}

/// Per-extruder state.
@freezed
class Extruder with _$Extruder {
  const factory Extruder({
    /// Zero-based index.
    @Default(0) int index,

    /// Current temperature °C.
    @Default(0) double temperature,

    /// Target temperature °C.
    @Default(0) double target,

    /// Power output 0.0–1.0.
    @Default(0) double power,

    /// Whether this extruder can extrude (i.e. above min extrusion temp).
    @Default(false) bool canExtrude,

    /// Pressure advance value.
    @Default(0) double pressureAdvance,

    /// Smooth time for pressure advance.
    @Default(0) double smoothTime,
  }) = _Extruder;
}

/// Generic temperature sensor (bed, chamber, etc.).
@freezed
class TemperatureSensor with _$TemperatureSensor {
  const factory TemperatureSensor({
    @Default('') String name,
    @Default(0) double temperature,
    @Default(0) double target,
    @Default(0) double power,
  }) = _TemperatureSensor;
}
