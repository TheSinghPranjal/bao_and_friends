import 'package:bao_and_friends/models/bao_scenarios.dart';
import 'package:bao_and_friends/models/rewards.dart';
import 'package:bao_and_friends/navigation/app_router.dart';
import 'package:bao_and_friends/screens/chores/bao_scenario_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('drawing time and rainy day list five steps and asset filenames', () {
    expect(BaoScenarios.drawingTime.steps, hasLength(5));
    expect(BaoScenarios.rainyDay.steps, hasLength(5));
    expect(BaoScenarios.drawingTime.route, '/drawing-time');
    expect(BaoScenarios.rainyDay.route, '/rainy-day');

    expect(BaoScenarios.drawingTime.videoAssets, [
      'assets/videos/drawing_time/step_1_get_supplies.mp4',
      'assets/videos/drawing_time/step_1_get_supplies_action.mp4',
      'assets/videos/drawing_time/step_2_set_up_table.mp4',
      'assets/videos/drawing_time/step_2_set_up_table_action.mp4',
      'assets/videos/drawing_time/step_3_draw_picture.mp4',
      'assets/videos/drawing_time/step_3_draw_picture_action.mp4',
      'assets/videos/drawing_time/step_4_add_details.mp4',
      'assets/videos/drawing_time/step_4_add_details_action.mp4',
      'assets/videos/drawing_time/step_5_display_artwork.mp4',
      'assets/videos/drawing_time/step_5_display_artwork_action.mp4',
    ]);
    expect(BaoScenarios.rainyDay.videoAssets, [
      'assets/videos/rainy_day/step_1_look_outside.mp4',
      'assets/videos/rainy_day/step_1_look_outside_action.mp4',
      'assets/videos/rainy_day/step_2_get_raincoat.mp4',
      'assets/videos/rainy_day/step_2_get_raincoat_action.mp4',
      'assets/videos/rainy_day/step_3_put_on_boots.mp4',
      'assets/videos/rainy_day/step_3_put_on_boots_action.mp4',
      'assets/videos/rainy_day/step_4_take_umbrella.mp4',
      'assets/videos/rainy_day/step_4_take_umbrella_action.mp4',
      'assets/videos/rainy_day/step_5_ready_for_rain.mp4',
      'assets/videos/rainy_day/step_5_ready_for_rain_action.mp4',
    ]);

    final drawing = DrawingTimeRules.rewardForSteps(5);
    final rainy = RainyDayRules.rewardForSteps(5);
    expect(drawing.stars, 3);
    expect(drawing.magicBeans, 1);
    expect(rainy.stars, 3);
    expect(rainy.magicBeans, 1);
  });

  test('router exposes drawing time and rainy day', () {
    final router = createAppRouter(skipSplash: true);
    final paths = router.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();
    expect(paths, containsAll(['/drawing-time', '/rainy-day']));
  });

  testWidgets('drawing time falls back without videos and rewards after 5 taps',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/chores',
      routes: [
        GoRoute(
          path: '/chores',
          builder: (context, state) => const Scaffold(
            body: Text('chores-back'),
          ),
        ),
        GoRoute(
          path: '/drawing-time',
          builder: (context, state) => const BaoScenarioScreen(
            scenarioId: BaoScenarios.drawingTimeId,
          ),
        ),
        GoRoute(
          path: '/parent-gate',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    router.push('/drawing-time');
    await tester.pump();
    await tester.pump();

    expect(find.text('Drawing Time!'), findsOneWidget);
    expect(find.text('Get Supplies'), findsOneWidget);
    expect(find.byKey(const Key('scenario-video-fallback')), findsOneWidget);

    const labels = [
      'Set Up Table',
      'Draw Picture',
      'Add Details',
      'Display Artwork',
    ];
    for (final label in labels) {
      await _tapStep(tester);
      expect(find.text(label), findsOneWidget);
      expect(find.byKey(const Key('scenario-video-fallback')), findsOneWidget);
    }

    await _tapStep(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Wonderful!'), findsOneWidget);
    expect(
      find.text('Amazing! Bao\'s drawing is on the fridge!'),
      findsOneWidget,
    );

    await tester.tap(find.text('Yay!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('chores-back'), findsOneWidget);
  });

  testWidgets('rainy day opens on the first step with a face fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BaoScenarioScreen(scenarioId: BaoScenarios.rainyDayId),
      ),
    );
    await tester.pump();

    expect(find.text('Rainy Day!'), findsOneWidget);
    expect(find.text('Look Outside'), findsOneWidget);
    expect(
      find.text('Bao looks through the window at the rain.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('scenario-video-fallback')), findsOneWidget);
  });
}

Future<void> _tapStep(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('scenario-step-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}
