// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import 'debug_service.dart';

part 'github_report_service.g.dart';

/// Result of uploading a diagnostic report to GitHub.
class GithubUploadResult {
  const GithubUploadResult({
    required this.success,
    this.gistUrl,
    this.issueUrl,
    this.error,
  });

  final bool success;

  /// URL of the created GitHub Gist, e.g. https://gist.github.com/abc123
  final String? gistUrl;

  /// Pre-filled GitHub Issue URL (open in browser to submit).
  final String? issueUrl;

  final String? error;
}

/// Uploads diagnostic reports to GitHub.
///
/// Two upload paths are available:
///   1. **GitHub Gist** — creates an anonymous public Gist containing the full
///      Markdown report. No authentication required. Returns a shareable URL.
///   2. **GitHub Issue** — builds a deep-link URL that opens the mmuraker
///      Issues page with the report pre-filled. The user taps to submit.
///
/// If a [githubToken] is provided (optional personal access token stored in
/// settings), the Gist is created under the user's account instead of anonymously.
class GithubReportService {
  GithubReportService(this._ref);

  final Ref _ref;

  static const _repoOwner = 'lameandboard';
  static const _repoName = 'mmuraker';
  static const _gistApiUrl = 'https://api.github.com/gists';
  static const _issueApiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/issues';

  /// Upload a [DiagnosticReport] to GitHub.
  ///
  /// Creates a public Gist and returns its URL.
  /// Optionally also creates a GitHub Issue if [createIssue] is true.
  Future<GithubUploadResult> upload(
    DiagnosticReport report, {
    String? githubToken,
    bool createIssue = false,
  }) async {
    String? gistUrl;
    String? issueUrl;

    // ── 1. Create public GitHub Gist ────────────────────────────────────────
    try {
      gistUrl = await _createGist(report, token: githubToken);
    } catch (e) {
      debugPrint('Gist upload failed: $e');
      return GithubUploadResult(
        success: false,
        error: 'Gist upload failed: $e',
      );
    }

    // ── 2. Optionally create a GitHub Issue ─────────────────────────────────
    if (createIssue) {
      try {
        issueUrl = await _createIssue(report, gistUrl: gistUrl, token: githubToken);
      } catch (e) {
        // Issue creation failure is non-fatal — we already have the Gist URL.
        debugPrint('Issue creation failed (non-fatal): $e');
        // Fall back to pre-filled deep-link URL.
        issueUrl = _buildIssueDeepLink(report, gistUrl: gistUrl);
      }
    } else {
      issueUrl = _buildIssueDeepLink(report, gistUrl: gistUrl);
    }

    return GithubUploadResult(
      success: true,
      gistUrl: gistUrl,
      issueUrl: issueUrl,
    );
  }

  // ── Gist creation ──────────────────────────────────────────────────────────

  Future<String> _createGist(DiagnosticReport report, {String? token}) async {
    final fileName =
        'mmuraker-diag-${report.timestamp.millisecondsSinceEpoch}.md';

    final body = jsonEncode({
      'description': 'MMURaker diagnostic report — ${report.timestamp.toIso8601String()}',
      'public': true,
      'files': {
        fileName: {'content': report.toMarkdown()},
        'device-info.txt': {
          'content': [
            'Platform: ${report.platform}',
            'Device: ${report.deviceModel}',
            'OS: ${report.osVersion}',
            'App: ${report.appVersion}+${report.buildNumber}',
            'Build: ${report.isDebugBuild ? 'DEBUG' : 'RELEASE'}',
            'Dart: ${report.dartVersion}',
          ].join('\n'),
        },
      },
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http
        .post(Uri.parse(_gistApiUrl), headers: headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 201) {
      throw Exception('GitHub API ${resp.statusCode}: ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['html_url'] as String;
  }

  // ── Issue creation ─────────────────────────────────────────────────────────

  Future<String> _createIssue(
    DiagnosticReport report, {
    String? gistUrl,
    String? token,
  }) async {
    if (token == null || token.isEmpty) {
      // No token → can't create issues via API, use deep link.
      return _buildIssueDeepLink(report, gistUrl: gistUrl);
    }

    final body = _buildIssueBody(report, gistUrl: gistUrl);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $token',
      'X-GitHub-Api-Version': '2022-11-28',
    };

    final payload = jsonEncode({
      'title': report.issueSummary,
      'body': body,
      'labels': ['bug', 'auto-reported'],
    });

    final resp = await http
        .post(Uri.parse(_issueApiUrl), headers: headers, body: payload)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 201) {
      throw Exception('Issue API ${resp.statusCode}: ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['html_url'] as String;
  }

  String _buildIssueBody(DiagnosticReport report, {String? gistUrl}) {
    return '''
## Description
<!-- Describe what you were doing when this happened -->

## Diagnostic Report
${gistUrl != null ? '📋 Full logs: $gistUrl' : ''}

**App:** ${report.appVersion}+${report.buildNumber} (${report.isDebugBuild ? 'DEBUG' : 'RELEASE'})
**Platform:** ${report.platform} — ${report.deviceModel} — ${report.osVersion}
**Time:** ${report.timestamp.toIso8601String()}

${report.errorSummary != null ? '''
## Error
```
${report.errorSummary}
```
''' : ''}

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behaviour
<!-- What should have happened? -->

## Actual Behaviour
<!-- What actually happened? -->
''';
  }

  String _buildIssueDeepLink(DiagnosticReport report, {String? gistUrl}) {
    final body = Uri.encodeComponent(_buildIssueBody(report, gistUrl: gistUrl));
    final title = Uri.encodeComponent(report.issueSummary);
    final labels = Uri.encodeComponent('bug,auto-reported');
    return 'https://github.com/$_repoOwner/$_repoName/issues/new'
        '?title=$title&body=$body&labels=$labels';
  }
}
