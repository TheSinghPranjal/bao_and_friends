/// Time-of-day + timed special-event bedroom backgrounds for Bao's home (awake).
enum CharacterBgPeriod {
  nightYawning, // 10pm – midnight
  nightSleeping, // midnight – 6am
  morning, // 6am – 12 noon
  noon, // 12 noon – 5pm
  evening, // 5pm – 10pm
}

/// A short special clip that overrides the default period video.
class CharacterBgSpecial {
  const CharacterBgSpecial({
    required this.id,
    required this.asset,
    required this.startMinute,
    required this.endMinute,
  });

  final String id;
  final String asset;

  /// Inclusive start, minutes from midnight.
  final int startMinute;

  /// Inclusive end, minutes from midnight (e.g. 2:30 means through 2:30).
  final int endMinute;

  bool contains(int minutes) =>
      minutes >= startMinute && minutes <= endMinute;
}

/// Resolves which looping bg video to show by clock time.
abstract final class CharacterBgVideos {
  static const folder = 'assets/videos/bao_character_screen_bg_video_list';

  /// Generic fallback while period clips are placeholders / missing.
  static const fallback = '$folder/bao_character_screen_bg_video.mp4';

  static const nightYawning =
      '$folder/bao_character_screen_night_yawning_bg_video.mp4';
  static const nightSleeping =
      '$folder/bao_character_screen_night_sleeping_bg_video.mp4';
  static const morning = '$folder/bao_character_screen_morning_bg_video.mp4';
  static const noon = '$folder/bao_character_screen_noon_bg_video.mp4';
  static const evening = '$folder/bao_character_screen_evening_bg_video.mp4';

  static const eatingApple =
      '$folder/bao_character_screen_bg_eating_apple_video.mp4';
  static const cleaningFloor =
      '$folder/bao_character_screen_bg_cleaning_floor_video.mp4';
  static const cleaningShelf =
      '$folder/bao_character_screen_bg_cleaning_shelf_video.mp4';
  static const makingPancakes =
      '$folder/bao_character_screen_bg_making_pancakes_video.mp4';

  static const allPeriodAssets = <String>[
    nightYawning,
    nightSleeping,
    morning,
    noon,
    evening,
  ];

  /// Exclusive end was too early for "until 2:30" — ends are inclusive.
  /// 12:30pm – 1:00pm
  static const specials = <CharacterBgSpecial>[
    CharacterBgSpecial(
      id: 'eating_apple',
      asset: eatingApple,
      startMinute: 12 * 60 + 30,
      endMinute: 13 * 60,
    ),
    // 2:15pm – 2:30pm
    CharacterBgSpecial(
      id: 'cleaning_floor',
      asset: cleaningFloor,
      startMinute: 14 * 60 + 15,
      endMinute: 14 * 60 + 30,
    ),
    // 3:15pm – 3:30pm
    CharacterBgSpecial(
      id: 'cleaning_shelf',
      asset: cleaningShelf,
      startMinute: 15 * 60 + 15,
      endMinute: 15 * 60 + 30,
    ),
    // 4:45pm – 5:00pm
    CharacterBgSpecial(
      id: 'making_pancakes',
      asset: makingPancakes,
      startMinute: 16 * 60 + 45,
      endMinute: 17 * 60,
    ),
  ];

  static const allSpecialAssets = <String>[
    eatingApple,
    cleaningFloor,
    cleaningShelf,
    makingPancakes,
  ];

  static CharacterBgPeriod periodFor([DateTime? now]) {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    // 10:00pm – midnight
    if (minutes >= 22 * 60) {
      return CharacterBgPeriod.nightYawning;
    }
    // midnight – 6:00am
    if (minutes < 6 * 60) {
      return CharacterBgPeriod.nightSleeping;
    }
    if (minutes < 12 * 60) return CharacterBgPeriod.morning;
    if (minutes < 17 * 60) return CharacterBgPeriod.noon;
    return CharacterBgPeriod.evening;
  }

  static String assetForPeriod(CharacterBgPeriod period) => switch (period) {
        CharacterBgPeriod.nightYawning => nightYawning,
        CharacterBgPeriod.nightSleeping => nightSleeping,
        CharacterBgPeriod.morning => morning,
        CharacterBgPeriod.noon => noon,
        CharacterBgPeriod.evening => evening,
      };

  /// Active special event for [now], if any.
  static CharacterBgSpecial? specialFor([DateTime? now]) {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    for (final s in specials) {
      if (s.contains(minutes)) return s;
    }
    return null;
  }

  /// Preferred clip for [now]: special window first, else period default.
  static String assetForNow([DateTime? now]) {
    final special = specialFor(now);
    if (special != null) return special.asset;
    return assetForPeriod(periodFor(now));
  }

  /// Stable key for the current awake clip (special id or period name).
  static String awakeKeyFor([DateTime? now]) {
    final special = specialFor(now);
    if (special != null) return 'special:${special.id}';
    return 'period:${periodFor(now).name}';
  }

  /// True if [dataSource] already matches the expected awake clip for [now].
  static bool matchesAwakeSource(String dataSource, [DateTime? now]) {
    final expected = assetForNow(now);
    return dataSource.contains(_fileName(expected));
  }

  static bool isPeriodAsset(String dataSource, CharacterBgPeriod period) {
    return dataSource.contains(_fileName(assetForPeriod(period)));
  }

  static String _fileName(String path) => path.split('/').last;
}
