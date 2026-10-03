import 'package:go_router/go_router.dart';

import '../screens/character_home/character_home_screen.dart';
import '../screens/character_selection/character_selection_screen.dart';
import '../screens/chores/chores_screen.dart';
import '../screens/chores/bath_screen.dart';
import '../screens/chores/brush_teeth_screen.dart';
import '../screens/chores/comb_hair_screen.dart';
import '../screens/chores/get_dressed_screen.dart';
import '../screens/chores/make_bed_screen.dart';
import '../screens/chores/wash_face_screen.dart';
import '../screens/chores/wake_up_screen.dart';
import '../screens/chores/wear_shoes_screen.dart';
import '../screens/drink/drink_water_screen.dart';
import '../screens/feed/eat_food_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/learn/alphabet_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/learn/numbers_screen.dart';
import '../screens/learn/word_time_screen.dart';
import '../screens/play/play_game_screen.dart';
import '../screens/play/play_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/shared/module_hub_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/system/activity_timers_settings_screen.dart';
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
        builder: (context, state) => const LearnScreen(),
      ),
      GoRoute(
        path: '/learn/alphabet',
        builder: (context, state) => const AlphabetScreen(),
      ),
      GoRoute(
        path: '/learn/numbers',
        builder: (context, state) => const NumbersScreen(),
      ),
      GoRoute(
        path: '/learn/words',
        builder: (context, state) => const WordTimeScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/eat-food/:foodId',
        builder: (context, state) => EatFoodScreen(
          foodId: state.pathParameters['foodId'] ?? 'apple',
        ),
      ),
      // Legacy feed deep-links → unified eat screen
      GoRoute(
        path: '/drink-milk',
        builder: (context, state) => const EatFoodScreen(foodId: 'milk'),
      ),
      GoRoute(
        path: '/eat-apple',
        builder: (context, state) => const EatFoodScreen(foodId: 'apple'),
      ),
      GoRoute(
        path: '/eat-banana',
        builder: (context, state) => const EatFoodScreen(foodId: 'banana'),
      ),
      GoRoute(
        path: '/eat-veggies',
        builder: (context, state) => const EatFoodScreen(foodId: 'veggies'),
      ),
      GoRoute(
        path: '/eat-sandwich',
        builder: (context, state) => const EatFoodScreen(foodId: 'sandwich'),
      ),
      GoRoute(
        path: '/eat-rice',
        builder: (context, state) => const EatFoodScreen(foodId: 'rice'),
      ),
      GoRoute(
        path: '/play',
        builder: (context, state) => const PlayScreen(),
      ),
      GoRoute(
        path: '/play-game/:gameId',
        builder: (context, state) => PlayGameScreen(
          gameId: state.pathParameters['gameId'] ?? 'football',
        ),
      ),
      GoRoute(
        path: '/chores',
        builder: (context, state) => const ChoresScreen(),
      ),
      GoRoute(
        path: '/make-bed',
        builder: (context, state) => const MakeBedScreen(),
      ),
      GoRoute(
        path: '/brush-teeth',
        builder: (context, state) => const BrushTeethScreen(),
      ),
      GoRoute(
        path: '/wash-face',
        builder: (context, state) => const WashFaceScreen(),
      ),
      GoRoute(
        path: '/bath',
        builder: (context, state) => const BathScreen(),
      ),
      GoRoute(
        path: '/get-dressed',
        builder: (context, state) => const GetDressedScreen(),
      ),
      GoRoute(
        path: '/wear-shoes',
        builder: (context, state) => const WearShoesScreen(),
      ),
      GoRoute(
        path: '/comb-hair',
        builder: (context, state) => const CombHairScreen(),
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
        path: '/premium',
        builder: (context, state) {
          final fromSettings =
              state.uri.queryParameters['from'] == 'settings';
          return PremiumScreen(fromSettings: fromSettings);
        },
      ),
      GoRoute(
        path: '/activity-timers',
        builder: (context, state) => const ActivityTimersSettingsScreen(),
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
