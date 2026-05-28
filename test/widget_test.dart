import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ink_n_motion/main.dart';

void main() {
  testWidgets('InkNMotionApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: InkNMotionApp(),
      ),
    );

    expect(find.byType(CupertinoApp), findsOneWidget);
  });
}
