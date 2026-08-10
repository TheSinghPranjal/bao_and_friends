import 'package:go_router/go_router.dart';

import '../screens/character_home/character_home_screen.dart';
import '../screens/character_selection/character_selection_screen.dart';
import '../screens/chores/chores_screen.dart';
import '../screens/chores/wake_up_screen.dart';
import '../screens/drink/drink_water_screen.dart';
import '../screens/feed/drink_milk_screen.dart';
import '../screens/feed/eat_apple_screen.dart';
import '../screens/feed/eat_banana_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/hubs/module_hubs.dart';
import '../screens/shared/module_hub_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/system/parent_gate_screen.dart';
import '../screens/system/utility_screens.dart';

GoRouter createAppRouter({bool skipSplash = false}) {
  return GoRouter(
    initialLocation: skipSplash ? '/select' : '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: '/select',
        builder: (context, state) => const CharacterSelectionScreen(),
      ),
      GoRoute(
        path: '/home/:characterId',
        builder: (context, state) => CharacterHomeScreen(
          characterId: state.pathParameters['characterId'] ?? 'bao',
        ),
      ),
      GoRoute(
        path: '/learn',
        builder: (context, state) => const LearnHubScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/drink-milk',
        builder: (context, state) => const DrinkMilkScreen(),
      ),
      GoRoute(
        path: '/eat-apple',
        builder: (context, state) => const EatAppleScreen(),
      ),
      GoRoute(
        path: '/eat-banana',
        builder: (context, state) => const EatBananaScreen(),
      ),
      GoRoute(
        path: '/play',
        builder: (context, state) => const PlayHubScreen(),
      ),
      GoRoute(
        path: '/chores',
        builder: (context, state) => const ChoresScreen(),
      ),
      GoRoute(
        path: '/wake-up',
        builder: (context, state) => const WakeUpScreen(),
      ),
      GoRoute(
        path: '/drink',
        builder: (context, state) => const DrinkWaterScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => ActivityPlaceholderScreen(
          title: state.uri.queryParameters['title'] ?? 'Activity',
          module: state.uri.queryParameters['module'] ?? 'Play',
        ),
      ),
      GoRoute(
        path: '/parent-gate',
        builder: (context, state) => const ParentGateScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Profile',
          body: 'Your little learner\'s profile lives here.',
        ),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Daily Streak',
          body: 'Come back each day for gentle rewards — never guilt.',
        ),
      ),
      GoRoute(
        path: '/parent-dashboard',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Parent Dashboard',
          body: 'Progress insights for grown-ups. Positive only.',
        ),
      ),
      GoRoute(
        path: '/sound',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Sound & Music',
          body: 'Soft piano, ukulele, birds, and wind chimes.',
        ),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Help',
          body: 'Tap big bubbles. Bao never gets sad — only ready to play!',
        ),
      ),
      GoRoute(
        path: '/stickers',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Sticker Book',
          body: 'Collect stickers from learning and kind habits.',
        ),
      ),
      GoRoute(
        path: '/room',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Room Customization',
          body: 'Spend Magic Beans on rugs, beds, and curtains — cosmetics only.',
        ),
      ),
      GoRoute(
        path: '/wardrobe',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Wardrobe',
          body: 'Hats, shirts, and glasses for Bao — for fun, never power.',
        ),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const PlaceholderInfoScreen(
          title: 'Achievements',
          body: 'Celebrate curiosity, kindness, and healthy habits.',
        ),
      ),
    ],
  );
}
