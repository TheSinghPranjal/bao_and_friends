import 'package:bao_and_friends/models/learn_topics.dart';
import 'package:bao_and_friends/models/rewards.dart';
import 'package:bao_and_friends/navigation/app_router.dart';
import 'package:bao_and_friends/screens/learn/word_time_screen.dart';
import 'package:bao_and_friends/services/stars_store.dart';
import 'package:bao_and_friends/theme/tt_typography.dart';
import 'package:bao_and_friends/widgets/bao_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await StarsStore.total();
  });

  test('Word Time catalog lists the ten words and asset filenames', () {
    expect(WordTimeLessons.lessons.map((lesson) => lesson.word).toList(), [
      'CAT',
      'DOG',
      'MAT',
      'BAT',
      'RAT',
      'HAT',
      'SUN',
      'CUP',
      'BUS',
      'PEN',
    ]);
    expect(WordTimeLessons.fileNames, [
      'word_cat.mp4',
      'word_dog.mp4',
      'word_mat.mp4',
      'word_bat.mp4',
      'word_rat.mp4',
      'word_hat.mp4',
      'word_sun.mp4',
      'word_cup.mp4',
      'word_bus.mp4',
      'word_pen.mp4',
    ]);
    expect(WordTimeLessons.lessons.map((lesson) => lesson.asset).toList(), [
      for (final name in WordTimeLessons.fileNames)
        '${WordTimeLessons.folder}/$name',
    ]);
  });

  test('Word Time is a Learn topic and /learn/words is routed', () {
    final topic = LearnTopics.byId('words');
    expect(topic, isNotNull);
    expect(topic!.label, 'Word Time');
    expect(topic.route, '/learn/words');
    expect(topic.hasActivity, isTrue);
    expect(
      _routePaths(createAppRouter(skipSplash: true)),
      contains('/learn/words'),
    );
  });

  testWidgets('Next walks every Word Time word when videos are absent', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(WordTimeLessons.screenTitle), findsOneWidget);
    expect(find.text('CAT'), findsOneWidget);
    expect(find.byType(BaoFace), findsOneWidget);
    expect(find.byKey(const Key('word-time-word')), findsOneWidget);

    await _tap(tester, 'Replay');
    expect(find.text('CAT'), findsOneWidget);
    expect(find.text('DOG'), findsNothing);

    const words = [
      'CAT',
      'DOG',
      'MAT',
      'BAT',
      'RAT',
      'HAT',
      'SUN',
      'CUP',
      'BUS',
      'PEN',
    ];
    for (var i = 0; i < words.length; i++) {
      expect(find.text(words[i]), findsOneWidget);
      expect(find.byType(BaoFace), findsOneWidget);
      if (i == words.length - 1) break;
      await _tap(tester, 'Next');
    }

    final starsBefore = StarsStore.totalListenable.value;
    await _tap(tester, 'Next');

    expect(find.text(WordTimeScreen.completionTitle), findsOneWidget);
    expect(find.text('PEN'), findsNothing);
    expect(find.byType(BaoFace), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Wonderful!'), findsOneWidget);
    expect(
      find.text(LearnWordTimeRules.rewardForComplete().message),
      findsWidgets,
    );
    expect(
      StarsStore.totalListenable.value,
      starsBefore + LearnWordTimeRules.rewardForComplete().stars,
    );

    await _tap(tester, 'Yay!');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Restart from CAT'), findsOneWidget);
    expect(find.text('Back to Learn'), findsOneWidget);

    await _tap(tester, 'Restart from CAT');
    expect(find.text('CAT'), findsOneWidget);
    expect(find.text(WordTimeLessons.screenTitle), findsOneWidget);
    expect(find.text(WordTimeScreen.completionTitle), findsNothing);

    for (final word in [
      'DOG',
      'MAT',
      'BAT',
      'RAT',
      'HAT',
      'SUN',
      'CUP',
      'BUS',
      'PEN',
    ]) {
      await _tap(tester, 'Next');
      expect(find.text(word), findsOneWidget);
    }
    await _tap(tester, 'Next');
    expect(find.text(WordTimeScreen.completionTitle), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await _tap(tester, 'Yay!');
    await tester.pump(const Duration(milliseconds: 400));

    await _tap(tester, 'Back to Learn');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Learn hub'), findsOneWidget);
    expect(find.text(WordTimeScreen.completionTitle), findsNothing);
  });
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  // Let bounce / dialog transitions finish so the control can take the hit.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
}

Widget _harness() {
  final router = GoRouter(
    initialLocation: '/learn/words',
    routes: [
      GoRoute(
        path: '/learn',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Learn hub'))),
        routes: [
          GoRoute(
            path: 'words',
            builder: (context, state) => const WordTimeScreen(),
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(theme: buildTinyThinkTheme(), routerConfig: router);
}

List<String> _routePaths(GoRouter router) {
  final paths = <String>[];
  void walk(List<RouteBase> routes, String prefix) {
    for (final route in routes) {
      if (route is GoRoute) {
        final path = route.path.startsWith('/')
            ? route.path
            : '$prefix/${route.path}'.replaceAll('//', '/');
        paths.add(path);
        walk(route.routes, path);
      }
    }
  }

  walk(router.configuration.routes, '');
  return paths;
}
