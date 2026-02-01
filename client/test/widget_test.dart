import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/main.dart';

void main() {
  testWidgets('ArenaApp boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ArenaApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
