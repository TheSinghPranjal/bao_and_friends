import 'package:bao_and_friends/main.dart';
import 'package:bao_and_friends/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tiny Think app boots to splash logo', (tester) async {
    await tester.pumpWidget(const TinyThinkApp());
    await tester.pump();
    expect(
      find.bySemanticsLabel('Tiny Think – Learning Together'),
      findsOneWidget,
    );
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    // Flush splash navigation timer so no pending timers remain.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('splash byline fits phones, tablets, and landscape', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    const sizes = <Size>[
      Size(320, 568),
      Size(390, 844),
      Size(800, 1280),
      Size(844, 390),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const TinyThinkApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('by'), findsOneWidget, reason: '$size');
      expect(find.text('The Lazy Bear Club'), findsOneWidget, reason: '$size');
      expect(find.textContaining('overflowed'), findsNothing, reason: '$size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 4000));
    }

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(find.textContaining('overflowed'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 4000));
  });
}
