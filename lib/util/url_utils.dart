// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
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
