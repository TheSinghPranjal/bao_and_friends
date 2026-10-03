import 'package:flutter/material.dart';

/// One learning topic under the Learn activity screen.
class LearnTopicSpec {
  const LearnTopicSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;

  /// Dedicated activity route when ready; null → placeholder.
  final String? route;

  bool get hasActivity => route != null;
}

/// All topics shown in the Learn tray (matches former Learn hub list).
abstract final class LearnTopics {
  static const all = <LearnTopicSpec>[
    LearnTopicSpec(
      id: 'alphabet',
      label: 'Alphabet',
      icon: Icons.abc_rounded,
      accent: Color(0xFF64B5F6),
      route: '/learn/alphabet',
    ),
    LearnTopicSpec(
      id: 'numbers',
      label: 'Numbers',
      icon: Icons.looks_one_rounded,
      accent: Color(0xFFFFB74D),
      route: '/learn/numbers',
    ),
    LearnTopicSpec(
      id: 'words',
      label: 'Word Time',
      icon: Icons.spellcheck_rounded,
      accent: Color(0xFF81C784),
      route: '/learn/words',
    ),
    // LearnTopicSpec(
    //   id: 'colours',
    //   label: 'Colours',
    //   icon: Icons.palette_rounded,
    //   accent: Color(0xFFF48FB1),
    // ),
    // LearnTopicSpec(
    //   id: 'shapes',
    //   label: 'Shapes',
    //   icon: Icons.category_rounded,
    //   accent: Color(0xFFBA68C8),
    // ),
    // LearnTopicSpec(
    //   id: 'animals',
    //   label: 'Animals',
    //   icon: Icons.pets_rounded,
    //   accent: Color(0xFFA1887F),
    // ),
    // LearnTopicSpec(
    //   id: 'months',
    //   label: 'Months',
    //   icon: Icons.calendar_month_rounded,
    //   accent: Color(0xFF4DB6AC),
    // ),
    // LearnTopicSpec(
    //   id: 'weekdays',
    //   label: 'Weekdays',
    //   icon: Icons.view_week_rounded,
    //   accent: Color(0xFF90CAF9),
    // ),
    // LearnTopicSpec(
    //   id: 'weather',
    //   label: 'Weather',
    //   icon: Icons.wb_cloudy_rounded,
    //   accent: Color(0xFF80DEEA),
    // ),
    // LearnTopicSpec(
    //   id: 'body_parts',
    //   label: 'Body Parts',
    //   icon: Icons.accessibility_new_rounded,
    //   accent: Color(0xFFEF9A9A),
    // ),
    // LearnTopicSpec(
    //   id: 'fruits_veggies',
    //   label: 'Fruits & Veggies',
    //   icon: Icons.eco_rounded,
    //   accent: Color(0xFFAED581),
    // ),
    // LearnTopicSpec(
    //   id: 'opposites',
    //   label: 'Opposites',
    //   icon: Icons.compare_arrows_rounded,
    //   accent: Color(0xFFFFCC80),
    // ),
    // LearnTopicSpec(
    //   id: 'emotions',
    //   label: 'Emotions',
    //   icon: Icons.emoji_emotions_rounded,
    //   accent: Color(0xFFFFF176),
    // ),
    // LearnTopicSpec(
    //   id: 'vehicles',
    //   label: 'Vehicles',
    //   icon: Icons.directions_car_rounded,
    //   accent: Color(0xFF90A4AE),
    // ),
    // LearnTopicSpec(
    //   id: 'music',
    //   label: 'Music',
    //   icon: Icons.music_note_rounded,
    //   accent: Color(0xFFCE93D8),
    // ),
    // LearnTopicSpec(
    //   id: 'nature',
    //   label: 'Nature',
    //   icon: Icons.park_rounded,
    //   accent: Color(0xFF66BB6A),
    // ),
  ];

  static LearnTopicSpec? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Alphabet segment videos (A–Z in order).
abstract final class AlphabetVideos {
  static const folder = 'assets/videos/learn/alphabets';

  static const segments = <String>[
    '$folder/Bao_speaking_alphabet_AtoD.mp4',
    '$folder/Bao_speaking_alphabet_EtoH.mp4',
    '$folder/Bao_speaking_alphabet_ItoL.mp4',
    '$folder/Bao_speaking_alphabet_MtoP.mp4',
    '$folder/Bao_speaking_alphabet_QtoT.mp4',
    '$folder/Bao_speaking_alphabet_UtoX.mp4',
    '$folder/Bao_speaking_alphabet_YtoZ.mp4',
  ];

  static const labels = <String>[
    'A – D',
    'E – H',
    'I – L',
    'M – P',
    'Q – T',
    'U – X',
    'Y – Z',
  ];
}

/// Numbers segment videos (1–20 in order).
abstract final class NumberVideos {
  static const folder = 'assets/videos/learn/numbers';

  static const segments = <String>[
    '$folder/numbers_from_1to5.mp4',
    '$folder/numbers_from_6to10.mp4',
    '$folder/numbers_from_11to15.mp4',
    '$folder/numbers_from_16to20.mp4',
  ];

  static const labels = <String>[
    '1 – 5',
    '6 – 10',
    '11 – 15',
    '16 – 20',
  ];
}

/// One 3-letter Word Time lesson.
///
/// Add a word by appending a [WordTimeLesson] to [WordTimeLessons.lessons].
class WordTimeLesson {
  const WordTimeLesson({
    required this.word,
    required this.asset,
  });

  final String word;

  /// Full Flutter asset path for this word's looping lesson.
  final String asset;

  String get fileName {
    final slash = asset.lastIndexOf('/');
    return slash < 0 ? asset : asset.substring(slash + 1);
  }
}

/// Ordered Word Time catalog. Each clip is one seamless loop:
/// Bao points to each letter, says the whole word, then shows the object.
abstract final class WordTimeLessons {
  static const screenTitle = "BAO'S WORD TIME 🐼";

  static const folder = 'assets/videos/learn/words';

  static const lessons = <WordTimeLesson>[
    WordTimeLesson(word: 'CAT', asset: '$folder/word_cat.mp4'),
    WordTimeLesson(word: 'DOG', asset: '$folder/word_dog.mp4'),
    WordTimeLesson(word: 'MAT', asset: '$folder/word_mat.mp4'),
    WordTimeLesson(word: 'BAT', asset: '$folder/word_bat.mp4'),
    WordTimeLesson(word: 'RAT', asset: '$folder/word_rat.mp4'),
    WordTimeLesson(word: 'HAT', asset: '$folder/word_hat.mp4'),
    WordTimeLesson(word: 'SUN', asset: '$folder/word_sun.mp4'),
    WordTimeLesson(word: 'CUP', asset: '$folder/word_cup.mp4'),
    WordTimeLesson(word: 'BUS', asset: '$folder/word_bus.mp4'),
    WordTimeLesson(word: 'PEN', asset: '$folder/word_pen.mp4'),
  ];

  static List<String> get fileNames => [
        for (final lesson in lessons) lesson.fileName,
      ];
}
