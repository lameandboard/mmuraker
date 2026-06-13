// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmuraker/util/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('all features are free and enabled', () {
      expect(FeatureFlags.autoVpn, isTrue);
      expect(FeatureFlags.multiPrinter, isTrue);
      expect(FeatureFlags.mmuDashboardCard, isTrue);
      expect(FeatureFlags.gcodeConsole, isTrue);
      expect(FeatureFlags.spoolman, isTrue,
          reason: 'Spoolman must always be free');
      expect(FeatureFlags.webcam, isTrue);
      expect(FeatureFlags.notifications, isTrue);
    });

    test('no ads, no support popups, no rate prompts', () {
      expect(FeatureFlags.ADS_ENABLED, isFalse,
          reason: 'mmuraker must never show ads');
      expect(FeatureFlags.SUPPORT_POPUPS_ENABLED, isFalse,
          reason: 'mmuraker must never show support popups');
      expect(FeatureFlags.RATE_APP_PROMPT_ENABLED, isFalse,
          reason: 'mmuraker must never prompt for ratings');
    });
  });

  group('Widget smoke test', () {
    testWidgets('MaterialApp renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('MMURaker')),
          ),
        ),
      );
      expect(find.text('MMURaker'), findsOneWidget);
    });
  });
}
