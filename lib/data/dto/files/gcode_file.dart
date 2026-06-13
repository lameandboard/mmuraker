// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'gcode_file.freezed.dart';

/// Metadata for a G-code file as returned by Moonraker's file metadata API.
///
/// The MMU-specific fields mirror what mobileraker already surfaces in its
/// `common/lib/data/dto/files/gcode_file.dart`.
@freezed
class GCodeFile with _$GCodeFile {
  const factory GCodeFile({
    required String name,
    required String path,
    @Default(0) int size,
    @Default(0) double printTime,
    String? thumbnailSmall,
    String? thumbnailLarge,

    // ── Slicer info ───────────────────────────────────────────────────────
    String? slicerVersion,
    String? layerHeight,
    String? objectHeight,
    String? firstLayerHeight,
    String? firstLayerBedTemp,
    String? firstLayerExtruderTemp,

    // ── MMU metadata ──────────────────────────────────────────────────────

    /// True when the slicer has flagged this as an MMU/multi-material print.
    @Default(false) bool mmuPrint,

    /// Number of filament colour changes in the file.
    @Default(0) int filamentChangeCount,

    /// Which tool indices are used in this print (e.g. [0, 1, 2]).
    @Default([]) List<int> referencedTools,

    /// Per-tool filament colours in hex format (index matches referencedTools).
    @Default([]) List<String> filamentColors,

    /// Per-extruder colour metadata (may differ from filamentColors on MMU).
    @Default([]) List<String> extruderColors,

    /// Total filament usage in mm per tool.
    @Default([]) List<double> filamentUsedMm,
  }) = _GCodeFile;

  const GCodeFile._();

  /// Whether this file has meaningful MMU colour metadata.
  bool get hasMmuColorData =>
      mmuPrint && filamentColors.isNotEmpty;

  /// Estimated print time as a [Duration].
  Duration get estimatedPrintTime =>
      Duration(seconds: printTime.round());
}
