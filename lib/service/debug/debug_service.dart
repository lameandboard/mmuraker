// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../util/logger.dart';

part 'debug_service.g.dart';

/// Snapshot of the app's diagnostic state at a point in time.
class DiagnosticReport {
  const DiagnosticReport({
    required this.timestamp,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.dartVersion,
    required this.isDebugBuild,
    required this.logLines,
    this.printerState,
    this.errorSummary,
  });

  final DateTime timestamp;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String deviceModel;
  final String osVersion;
  final String dartVersion;
  final bool isDebugBuild;
  final List<String> logLines;
  final String? printerState;
  final String? errorSummary;

  /// Render as a plain-text Markdown report suitable for a GitHub Gist or Issue.
  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# MMURaker Diagnostic Report');
    buf.writeln();
    buf.writeln('Generated: ${timestamp.toIso8601String()}');
    buf.writeln();

    buf.writeln('## App Info');
    buf.writeln('| Field | Value |');
    buf.writeln('|-------|-------|');
    buf.writeln('| Version | $appVersion+$buildNumber |');
    buf.writeln('| Build | ${isDebugBuild ? 'DEBUG' : 'RELEASE'} |');
    buf.writeln('| Platform | $platform |');
    buf.writeln('| Device | $deviceModel |');
    buf.writeln('| OS | $osVersion |');
    buf.writeln('| Dart | $dartVersion |');
    buf.writeln();

    if (printerState != null) {
      buf.writeln('## Printer State');
      buf.writeln('```');
      buf.writeln(printerState);
      buf.writeln('```');
      buf.writeln();
    }

    if (errorSummary != null) {
      buf.writeln('## Error Summary');
      buf.writeln('```');
      buf.writeln(errorSummary);
      buf.writeln('```');
      buf.writeln();
    }

    buf.writeln('## Log (last ${logLines.length} lines)');
    buf.writeln('```');
    for (final line in logLines) {
      buf.writeln(line);
    }
    buf.writeln('```');

    return buf.toString();
  }

  /// Short summary for a GitHub Issue title.
  String get issueSummary =>
      errorSummary != null
          ? 'Bug: ${errorSummary!.split('\n').first.trim()}'
          : 'Bug report — $platform $appVersion';
}

/// Collects comprehensive diagnostic information about the running app.
class DebugService {
  DebugService(this._ref);

  final Ref _ref;

  /// Collect a full [DiagnosticReport].
  ///
  /// [printerState] is an optional human-readable summary of the current
  /// printer connection state — pass it in from the printer service if
  /// a machine is selected.
  Future<DiagnosticReport> collect({
    String? printerState,
    String? errorSummary,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';
    String platform = defaultTargetPlatform.name;

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = '${info.manufacturer} ${info.model}';
        osVersion = 'Android ${info.version.release} (API ${info.version.sdkInt})';
        platform = 'Android';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceModel = info.utsname.machine;
        osVersion = 'iOS ${info.systemVersion}';
        platform = 'iOS';
      }
    } catch (_) {
      // Device info collection is best-effort
    }

    // Pull the last 500 log lines from the global Talker instance.
    final logs = appLogger.history
        .take(500)
        .map((e) => '[${e.title}] ${e.message ?? ''}${e.error != null ? ' | ${e.error}' : ''}')
        .toList();

    return DiagnosticReport(
      timestamp: DateTime.now().toUtc(),
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: platform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      dartVersion: Platform.version,
      isDebugBuild: kDebugMode,
      logLines: logs,
      printerState: printerState,
      errorSummary: errorSummary,
    );
  }
}
