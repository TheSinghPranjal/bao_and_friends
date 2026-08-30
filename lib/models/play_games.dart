import 'package:flutter/material.dart';

/// One playable game under the Play activity screen.
class PlayGameSpec {
  const PlayGameSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    this.idleVideoAsset,
    this.actionVideoAsset,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;

  /// Loops when idle; e.g. bao_not_playing_football_video.mp4
  final String? idleVideoAsset;

  /// Plays once per bubble tap; e.g. bao_playing_football_video.mp4
  final String? actionVideoAsset;

  bool get hasVideos =>
      idleVideoAsset != null && actionVideoAsset != null;
}

/// All games shown in the Play tray (matches former Play hub list).
abstract final class PlayGames {
  static const all = <PlayGameSpec>[
    PlayGameSpec(
      id: 'football',
      label: 'Football',
      icon: Icons.sports_soccer_rounded,
      accent: Color(0xFF81C784),
      idleVideoAsset:
          'assets/videos/play/football/bao_not_playing_football_video.mp4',
      actionVideoAsset:
          'assets/videos/play/football/bao_playing_football_video.mp4',
    ),
    PlayGameSpec(
      id: 'cricket',
      label: 'Cricket',
      icon: Icons.sports_cricket_rounded,
      accent: Color(0xFF4DB6AC),
      idleVideoAsset:
          'assets/videos/play/cricket/bao_not_playing_cricket_video.mp4',
      actionVideoAsset:
          'assets/videos/play/cricket/bao_playing_cricket_video.mp4',
    ),
    PlayGameSpec(
      id: 'badminton',
      label: 'Badminton',
      icon: Icons.sports_tennis_rounded,
      accent: Color(0xFF64B5F6),
    ),
    PlayGameSpec(
      id: 'hockey',
      label: 'Hockey',
      icon: Icons.sports_hockey_rounded,
      accent: Color(0xFF90A4AE),
    ),
    PlayGameSpec(
      id: 'basketball',
      label: 'Basketball',
      icon: Icons.sports_basketball_rounded,
      accent: Color(0xFFFFB74D),
    ),
    PlayGameSpec(
      id: 'skipping',
      label: 'Skipping',
      icon: Icons.directions_run_rounded,
      accent: Color(0xFFCE93D8),
      idleVideoAsset:
          'assets/videos/play/skipping/bao_not_doing_skipping_video.mp4',
      actionVideoAsset:
          'assets/videos/play/skipping/bao_doing_skipping_video.mp4',
    ),
    PlayGameSpec(
      id: 'dance',
      label: 'Dance',
      icon: Icons.nightlife_rounded,
      accent: Color(0xFFF48FB1),
      idleVideoAsset:
          'assets/videos/play/dance/bao_not_doing_dance_video.mp4',
      actionVideoAsset:
          'assets/videos/play/dance/bao_doing_dance_video.mp4',
    ),
    PlayGameSpec(
      id: 'yoga',
      label: 'Yoga',
      icon: Icons.self_improvement_rounded,
      accent: Color(0xFFA5D6A7),
      idleVideoAsset:
          'assets/videos/play/yoga/bao_not_doing_yoga_video.mp4',
      actionVideoAsset:
          'assets/videos/play/yoga/bao_doing_yoga_video.mp4',
    ),
    PlayGameSpec(
      id: 'coloring',
      label: 'Coloring',
      icon: Icons.brush_rounded,
      accent: Color(0xFF7986CB),
    ),
    PlayGameSpec(
      id: 'puzzle',
      label: 'Puzzle',
      icon: Icons.extension_rounded,
      accent: Color(0xFF4DD0E1),
    ),
    PlayGameSpec(
      id: 'memory',
      label: 'Memory',
      icon: Icons.grid_view_rounded,
      accent: Color(0xFFFFD54F),
    ),
    PlayGameSpec(
      id: 'music',
      label: 'Music',
      icon: Icons.library_music_rounded,
      accent: Color(0xFFBA68C8),
    ),
  ];

  static PlayGameSpec? byId(String id) {
    for (final game in all) {
      if (game.id == id) return game;
    }
    return null;
  }
}
