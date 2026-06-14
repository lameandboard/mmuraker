// mmuraker – a community derivative app inspired by mobileraker.
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmuraker/data/dto/machine/printer.dart';
import 'package:mmuraker/ui/screens/dashboard/components/temperature_card.dart';

void main() {
  Future<void> pumpTemperatureCard(
    WidgetTester tester, {
    required void Function(int, double) onSetExtruderTemp,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TemperatureCard(
            printer: Printer(
              extruders: const [
                Extruder(index: 0, temperature: 205, target: 215),
              ],
            ),
            onSetExtruderTemp: onSetExtruderTemp,
            onSetBedTemp: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('set temperature only performs one set action', (tester) async {
    final values = <double>[];
    await pumpTemperatureCard(
      tester,
      onSetExtruderTemp: (_, temp) => values.add(temp),
    );

    await tester.tap(find.text('Extruder'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '230');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(values, [230]);
  });

  testWidgets('off action does not trigger a second post-dismiss update', (
    tester,
  ) async {
    final values = <double>[];
    await pumpTemperatureCard(
      tester,
      onSetExtruderTemp: (_, temp) => values.add(temp),
    );

    await tester.tap(find.text('Extruder'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();

    expect(values, [0]);
  });
}
