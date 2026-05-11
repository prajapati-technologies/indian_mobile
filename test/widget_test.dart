import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indian_mobile/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianInfoApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
