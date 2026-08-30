/// Time-of-day bedroom backgrounds for Bao's character home (when awake).
enum CharacterBgPeriod {
  night, // 10pm – 6am
  morning, // 6am – 12 noon
  noon, // 12 noon – 5pm
  evening, // 5pm – 10pm
}

/// Resolves which looping bg video to show by clock time.
abstract final class CharacterBgVideos {
  static const folder = 'assets/videos/bao_character_screen_bg_video_list';

  /// Generic fallback while period clips are placeholders / missing.
  static const fallback = '$folder/bao_character_screen_bg_video.mp4';

  static const night = '$folder/bao_character_screen_night_bg_video.mp4';
  static const morning = '$folder/bao_character_screen_morning_bg_video.mp4';
  static const noon = '$folder/bao_character_screen_noon_bg_video.mp4';
  static const evening = '$folder/bao_character_screen_evening_bg_video.mp4';

  static const allPeriodAssets = <String>[night, morning, noon, evening];

  static CharacterBgPeriod periodFor([DateTime? now]) {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    // Night wraps midnight: 22:00 → 06:00
    if (minutes >= 22 * 60 || minutes < 6 * 60) {
      return CharacterBgPeriod.night;
    }
    if (minutes < 12 * 60) return CharacterBgPeriod.morning;
    if (minutes < 17 * 60) return CharacterBgPeriod.noon;
    return CharacterBgPeriod.evening;
  }

  static String assetForPeriod(CharacterBgPeriod period) => switch (period) {
        CharacterBgPeriod.night => night,
        CharacterBgPeriod.morning => morning,
        CharacterBgPeriod.noon => noon,
        CharacterBgPeriod.evening => evening,
      };

  /// Preferred clip for [now]; callers may fall back to [fallback] on load error.
  static String assetForNow([DateTime? now]) =>
      assetForPeriod(periodFor(now));

  /// True if [dataSource] already matches the expected awake clip for [now].
  static bool matchesAwakeSource(String dataSource, [DateTime? now]) {
    final expected = assetForNow(now);
    return dataSource.contains(_fileName(expected)) ||
        dataSource.contains(_fileName(fallback));
  }

  static bool isPeriodAsset(String dataSource, CharacterBgPeriod period) {
    return dataSource.contains(_fileName(assetForPeriod(period)));
  }

  static String _fileName(String path) => path.split('/').last;
}
