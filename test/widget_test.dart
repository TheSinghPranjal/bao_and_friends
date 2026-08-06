import 'package:bao_and_friends/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tiny Think app boots to splash logo', (tester) async {
    await tester.pumpWidget(const TinyThinkApp());
    await tester.pump();
    expect(
      find.bySemanticsLabel('Tiny Think – Learning Together'),
      findsOneWidget,
    );
    // Flush splash navigation timer so no pending timers remain.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));
  });
}
