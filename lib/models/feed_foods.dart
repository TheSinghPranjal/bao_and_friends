import 'package:flutter/material.dart';

/// One food under the Feed activity screen.
class FeedFoodSpec {
  const FeedFoodSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.idleVideoAsset,
    required this.actionVideoAsset,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;
  final String idleVideoAsset;
  final String actionVideoAsset;
}

/// Foods shown in the Feed tray (each has idle + eating videos).
abstract final class FeedFoods {
  static const all = <FeedFoodSpec>[
    FeedFoodSpec(
      id: 'milk',
      label: 'Milk',
      icon: Icons.local_drink_rounded,
      accent: Color(0xFFF5F5F5),
      idleVideoAsset:
          'assets/videos/feed/milk/bao_not_drinking_milk_video.mp4',
      actionVideoAsset:
          'assets/videos/feed/milk/bao_drinking_milk_video.mp4',
    ),
    FeedFoodSpec(
      id: 'apple',
      label: 'Apple',
      icon: Icons.apple,
      accent: Color(0xFFE57373),
      idleVideoAsset: 'assets/videos/feed/apple/bao_not_eating_apple.mp4',
      actionVideoAsset: 'assets/videos/feed/apple/bao_eating_apple.mp4',
    ),
    FeedFoodSpec(
      id: 'banana',
      label: 'Banana',
      icon: Icons.breakfast_dining_rounded,
      accent: Color(0xFFFFD54F),
      idleVideoAsset: 'assets/videos/feed/banana/bao_not_eating_banana.mp4',
      actionVideoAsset: 'assets/videos/feed/banana/bao_eating_banana.mp4',
    ),
    FeedFoodSpec(
      id: 'rice',
      label: 'Rice',
      icon: Icons.rice_bowl_rounded,
      accent: Color(0xFFFFF8E1),
      idleVideoAsset: 'assets/videos/feed/rice/bao_not_eating_rice.mp4',
      actionVideoAsset: 'assets/videos/feed/rice/bao_eating_rice.mp4',
    ),
    FeedFoodSpec(
      id: 'veggies',
      label: 'Veggies',
      icon: Icons.grass_rounded,
      accent: Color(0xFF81C784),
      idleVideoAsset: 'assets/videos/feed/veggies/bao_not_eating_veggies.mp4',
      actionVideoAsset: 'assets/videos/feed/veggies/bao_eating_veggies.mp4',
    ),
    FeedFoodSpec(
      id: 'sandwich',
      label: 'Sandwich',
      icon: Icons.lunch_dining_rounded,
      accent: Color(0xFFE6B87A),
      idleVideoAsset:
          'assets/videos/feed/sandwich/bao_not_eating_sandwich.mp4',
      actionVideoAsset: 'assets/videos/feed/sandwich/bao_eating_sandwich.mp4',
    ),
  ];

  static FeedFoodSpec? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
