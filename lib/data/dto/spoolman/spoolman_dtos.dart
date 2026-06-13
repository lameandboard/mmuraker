// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

/// DTOs for the Spoolman filament manager REST API.
///
/// Spoolman API reference: https://donkie.github.io/Spoolman/
/// All Spoolman features are free and unlocked — see FeatureFlags.spoolman.

// ── Filament / vendor / spool DTOs ────────────────────────────────────────────

class SpoolmanVendor {
  const SpoolmanVendor({
    required this.id,
    required this.name,
    this.comment,
  });

  final int id;
  final String name;
  final String? comment;

  factory SpoolmanVendor.fromJson(Map<String, dynamic> j) => SpoolmanVendor(
        id: j['id'] as int,
        name: j['name'] as String,
        comment: j['comment'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (comment != null) 'comment': comment,
      };
}

class SpoolmanFilament {
  const SpoolmanFilament({
    required this.id,
    required this.name,
    this.vendor,
    this.material,
    this.colorHex,
    this.density,
    this.diameter,
    this.weight,
    this.spoolWeight,
    this.articleNumber,
    this.comment,
    this.settingsExtruderTemp,
    this.settingsBedTemp,
  });

  final int id;
  final String name;
  final SpoolmanVendor? vendor;
  final String? material;

  /// Hex colour string without '#', e.g. "FF5733".
  final String? colorHex;
  final double? density;
  final double? diameter;

  /// Nominal weight of filament on spool in grams.
  final double? weight;

  /// Weight of the empty spool in grams.
  final double? spoolWeight;
  final String? articleNumber;
  final String? comment;
  final int? settingsExtruderTemp;
  final int? settingsBedTemp;

  factory SpoolmanFilament.fromJson(Map<String, dynamic> j) {
    return SpoolmanFilament(
      id: j['id'] as int,
      name: j['name'] as String,
      vendor: j['vendor'] != null
          ? SpoolmanVendor.fromJson(j['vendor'] as Map<String, dynamic>)
          : null,
      material: j['material'] as String?,
      colorHex: j['color_hex'] as String?,
      density: (j['density'] as num?)?.toDouble(),
      diameter: (j['diameter'] as num?)?.toDouble(),
      weight: (j['weight'] as num?)?.toDouble(),
      spoolWeight: (j['spool_weight'] as num?)?.toDouble(),
      articleNumber: j['article_number'] as String?,
      comment: j['comment'] as String?,
      settingsExtruderTemp: j['settings_extruder_temp'] as int?,
      settingsBedTemp: j['settings_bed_temp'] as int?,
    );
  }

  /// Colour as Flutter Color, or null if no colour set.
  int? get colorValue {
    if (colorHex == null || colorHex!.isEmpty) return null;
    return int.tryParse('FF${colorHex!.replaceAll('#', '')}', radix: 16);
  }
}

class SpoolmanSpool {
  const SpoolmanSpool({
    required this.id,
    required this.filament,
    this.usedWeight,
    this.usedLength,
    this.remainingWeight,
    this.remainingLength,
    this.location,
    this.lotNr,
    this.comment,
    this.archived,
    this.firstUsed,
    this.lastUsed,
  });

  final int id;
  final SpoolmanFilament filament;

  /// Grams of filament used from this spool.
  final double? usedWeight;

  /// Millimetres of filament used.
  final double? usedLength;

  /// Remaining filament weight in grams (computed by Spoolman).
  final double? remainingWeight;

  /// Remaining filament length in mm.
  final double? remainingLength;

  /// Physical storage location string.
  final String? location;
  final String? lotNr;
  final String? comment;
  final bool? archived;
  final DateTime? firstUsed;
  final DateTime? lastUsed;

  /// Whether this spool is running low (< 10% remaining).
  bool get isLow {
    if (remainingWeight != null && filament.weight != null && filament.weight! > 0) {
      return (remainingWeight! / filament.weight!) < 0.10;
    }
    return false;
  }

  /// Remaining weight as a percentage 0–100.
  double? get remainingPercent {
    if (remainingWeight != null && filament.weight != null && filament.weight! > 0) {
      return (remainingWeight! / filament.weight!) * 100;
    }
    return null;
  }

  /// Short display string, e.g. "PrusaSament PLA Red (450 g left)".
  String get displaySummary {
    final vendor = filament.vendor?.name;
    final mat = filament.material ?? '';
    final name = filament.name;
    final rem = remainingWeight != null
        ? '${remainingWeight!.toStringAsFixed(0)} g left'
        : '';
    final parts = [
      if (vendor != null && vendor.isNotEmpty) vendor,
      mat,
      name,
      if (rem.isNotEmpty) '($rem)',
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }

  factory SpoolmanSpool.fromJson(Map<String, dynamic> j) {
    return SpoolmanSpool(
      id: j['id'] as int,
      filament: SpoolmanFilament.fromJson(
          j['filament'] as Map<String, dynamic>),
      usedWeight: (j['used_weight'] as num?)?.toDouble(),
      usedLength: (j['used_length'] as num?)?.toDouble(),
      remainingWeight: (j['remaining_weight'] as num?)?.toDouble(),
      remainingLength: (j['remaining_length'] as num?)?.toDouble(),
      location: j['location'] as String?,
      lotNr: j['lot_nr'] as String?,
      comment: j['comment'] as String?,
      archived: j['archived'] as bool?,
      firstUsed: j['first_used'] != null
          ? DateTime.tryParse(j['first_used'] as String)
          : null,
      lastUsed: j['last_used'] != null
          ? DateTime.tryParse(j['last_used'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filament': {'id': filament.id},
        if (usedWeight != null) 'used_weight': usedWeight,
        if (location != null) 'location': location,
        if (comment != null) 'comment': comment,
      };
}

/// Summary statistics across all spools.
class SpoolmanStats {
  const SpoolmanStats({
    required this.totalSpools,
    required this.activeSpools,
    required this.totalUsedWeight,
    required this.totalRemainingWeight,
  });

  final int totalSpools;
  final int activeSpools;
  final double totalUsedWeight;
  final double totalRemainingWeight;
}
