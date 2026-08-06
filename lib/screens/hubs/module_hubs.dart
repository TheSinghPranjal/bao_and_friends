import 'package:flutter/material.dart';

import '../../theme/tt_colors.dart';
import '../shared/module_hub_screen.dart';

class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  static const items = <HubItem>[
    HubItem('Alphabet', Icons.abc_rounded),
    HubItem('Numbers', Icons.looks_one_rounded),
    HubItem('Words', Icons.spellcheck_rounded),
    HubItem('Colours', Icons.palette_rounded),
    HubItem('Shapes', Icons.category_rounded),
    HubItem('Animals', Icons.pets_rounded),
    HubItem('Months', Icons.calendar_month_rounded),
    HubItem('Weekdays', Icons.view_week_rounded),
    HubItem('Weather', Icons.wb_cloudy_rounded),
    HubItem('Body Parts', Icons.accessibility_new_rounded),
    HubItem('Fruits & Veggies', Icons.eco_rounded),
    HubItem('Opposites', Icons.compare_arrows_rounded),
    HubItem('Emotions', Icons.emoji_emotions_rounded),
    HubItem('Vehicles', Icons.directions_car_rounded),
    HubItem('Music', Icons.music_note_rounded),
    HubItem('Nature', Icons.park_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScreen(
      title: 'Learn',
      subtitle: 'Explore something new with Bao',
      accent: TTColors.skyBlue,
      items: items,
    );
  }
}

class FeedHubScreen extends StatelessWidget {
  const FeedHubScreen({super.key});

  static const items = <HubItem>[
    HubItem('Milk', Icons.local_drink_rounded),
    HubItem('Apple', Icons.apple),
    HubItem('Banana', Icons.breakfast_dining_rounded),
    HubItem('Rice', Icons.rice_bowl_rounded),
    HubItem('Vegetables', Icons.grass_rounded),
    HubItem('Soup', Icons.soup_kitchen_rounded),
    HubItem('Egg', Icons.egg_rounded),
    HubItem('Bread', Icons.bakery_dining_rounded),
    HubItem('Fruit Bowl', Icons.food_bank_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScreen(
      title: 'Feed',
      subtitle: 'Yummy healthy foods',
      accent: TTColors.momoCoral,
      items: items,
    );
  }
}

class PlayHubScreen extends StatelessWidget {
  const PlayHubScreen({super.key});

  static const items = <HubItem>[
    HubItem('Football', Icons.sports_soccer_rounded),
    HubItem('Cricket', Icons.sports_cricket_rounded),
    HubItem('Badminton', Icons.sports_tennis_rounded),
    HubItem('Hockey', Icons.sports_hockey_rounded),
    HubItem('Basketball', Icons.sports_basketball_rounded),
    HubItem('Skipping', Icons.directions_run_rounded),
    HubItem('Dance', Icons.nightlife_rounded),
    HubItem('Yoga', Icons.self_improvement_rounded),
    HubItem('Coloring', Icons.brush_rounded),
    HubItem('Puzzle', Icons.extension_rounded),
    HubItem('Memory', Icons.grid_view_rounded),
    HubItem('Music', Icons.library_music_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScreen(
      title: 'Play',
      subtitle: 'Move, create, and have fun',
      accent: TTColors.golden,
      items: items,
    );
  }
}

class ChoresHubScreen extends StatelessWidget {
  const ChoresHubScreen({super.key});

  static const items = <HubItem>[
    HubItem('Wake Up', Icons.wb_twilight_rounded),
    HubItem('Make Bed', Icons.bed_rounded),
    HubItem('Brush Teeth', Icons.clean_hands_rounded),
    HubItem('Wash Face', Icons.water_drop_outlined),
    HubItem('Comb Hair', Icons.content_cut_rounded),
    HubItem('Get Dressed', Icons.checkroom_rounded),
    HubItem('Wear Shoes', Icons.snowshoeing_rounded),
    HubItem('Eat Breakfast', Icons.free_breakfast_rounded),
    HubItem('Pack Bag', Icons.backpack_rounded),
    HubItem('Go To School', Icons.school_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScreen(
      title: 'Morning Routine',
      subtitle: 'Little helpers, big smiles',
      accent: TTColors.bambooLight,
      items: items,
    );
  }
}
