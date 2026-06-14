// mmuraker – a community derivative app inspired by Mobileraker.
// Mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

/// Ensures [url] has an `http://` or `https://` scheme prefix.
///
/// Accepts bare hostnames / IP addresses (`192.168.1.100`), addresses with
/// ports (`192.168.1.100:7125`), and fully-qualified URLs
/// (`http://192.168.1.100:7125`).  If no scheme is present, `http://` is
/// prepended automatically.
///
/// Returns the trimmed input unchanged when it already contains `://`, or an
/// empty string when [url] is blank.
String coerceHttpUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.contains('://')) return trimmed;
  return 'http://$trimmed';
}

/// Resolves [candidate] against [baseUrl] when [candidate] is relative.
///
/// Returns `null` when [candidate] is blank or cannot be parsed.
String? absolutizeHttpUrl(String baseUrl, String? candidate) {
  final trimmed = candidate?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final baseUri = Uri.tryParse(baseUrl);
  final candidateUri = Uri.tryParse(trimmed);
  if (candidateUri == null) return null;
  if (candidateUri.hasScheme) return candidateUri.toString();
  if (baseUri == null) return null;
  return baseUri.resolveUri(candidateUri).toString();
}

/// Extracts the best webcam stream or snapshot URL from a Moonraker response.
///
/// Supports both `/server/webcams/list` and database-backed webcam payloads.
String? extractMoonrakerWebcamUrl(String baseUrl, Object? payload) {
  final root = _asStringKeyedMap(payload);
  final webcams = _extractMoonrakerWebcams(root);

  for (final webcam in webcams) {
    for (final key in const [
      'stream_url',
      'streamUrl',
      'url_stream',
      'urlStream',
      'snapshot_url',
      'snapshotUrl',
      'url_snapshot',
      'urlSnapshot',
      'url',
    ]) {
      final resolved = absolutizeHttpUrl(baseUrl, webcam[key]?.toString());
      if (resolved != null) return resolved;
    }
  }
  return null;
}

Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _extractMoonrakerWebcams(Map<String, dynamic> root) {
  final candidates = <Object?>[
    root['webcams'],
    _asStringKeyedMap(root['result'])['webcams'],
    _asStringKeyedMap(root['result'])['value'],
    root['value'],
  ];

  for (final candidate in candidates) {
    final webcams = _normaliseWebcamList(candidate);
    if (webcams.isNotEmpty) return webcams;
  }
  return const [];
}

List<Map<String, dynamic>> _normaliseWebcamList(Object? value) {
  if (value is List) {
    return value.map(_asStringKeyedMap).where((map) => map.isNotEmpty).toList();
  }
  if (value is Map) {
    return value.values
        .map(_asStringKeyedMap)
        .where((map) => map.isNotEmpty)
        .toList();
  }
  return const [];
}
