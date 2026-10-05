import 'package:flutter/material.dart';

/// One step in a multi-step Bao scenario.
///
/// [idleVideoAsset] loops (muted) until the child taps. [actionVideoAsset]
/// plays once on that tap, then the scenario advances. Missing files are
/// skipped — the screen falls back to a color wash and Bao's face.
class BaoScenarioStep {
  const BaoScenarioStep({
    required this.label,
    required this.detail,
    required this.icon,
    required this.idleVideoAsset,
    required this.actionVideoAsset,
  });

  final String label;
  final String detail;
  final IconData icon;

  /// Looping, muted clip shown for this step (`setLooping`, volume 0).
  final String idleVideoAsset;

  /// Muted action clip played when the child taps this step.
  final String actionVideoAsset;
}

/// A catalogued multi-step activity for Bao (source notes may say "Piku").
class BaoScenario {
  const BaoScenario({
    required this.id,
    required this.title,
    required this.route,
    required this.trayIcon,
    required this.trayAccent,
    required this.gradient,
    required this.steps,
  });

  final String id;
  final String title;
  final String route;
  final IconData trayIcon;
  final Color trayAccent;
  final List<Color> gradient;
  final List<BaoScenarioStep> steps;

  List<String> get videoAssets => [
        for (final step in steps) ...[
          step.idleVideoAsset,
          step.actionVideoAsset,
        ],
      ];
}

/// Scenario 28 (Drawing Time) and scenario 30 (Rainy Day Routine).
///
/// Videos are generated separately and are not committed. Drop the mp4s into
/// the folders declared in `pubspec.yaml`. Exact filenames:
///
/// Drawing Time — `assets/videos/drawing_time/`
/// - step_1_get_supplies.mp4 (idle, looping)
/// - step_1_get_supplies_action.mp4
/// - step_2_set_up_table.mp4 (idle, looping)
/// - step_2_set_up_table_action.mp4
/// - step_3_draw_picture.mp4 (idle, looping)
/// - step_3_draw_picture_action.mp4
/// - step_4_add_details.mp4 (idle, looping)
/// - step_4_add_details_action.mp4
/// - step_5_display_artwork.mp4 (idle, looping)
/// - step_5_display_artwork_action.mp4
///
/// Rainy Day Routine — `assets/videos/rainy_day/`
/// - step_1_look_outside.mp4 (idle, looping)
/// - step_1_look_outside_action.mp4
/// - step_2_get_raincoat.mp4 (idle, looping)
/// - step_2_get_raincoat_action.mp4
/// - step_3_put_on_boots.mp4 (idle, looping)
/// - step_3_put_on_boots_action.mp4
/// - step_4_take_umbrella.mp4 (idle, looping)
/// - step_4_take_umbrella_action.mp4
/// - step_5_ready_for_rain.mp4 (idle, looping)
/// - step_5_ready_for_rain_action.mp4
///
/// Routes: `/drawing-time`, `/rainy-day` (opened from the Chores tray).
abstract final class BaoScenarios {
  static const drawingTimeId = 'drawing-time';
  static const rainyDayId = 'rainy-day';

  static const _drawingFolder = 'assets/videos/drawing_time';
  static const _rainyFolder = 'assets/videos/rainy_day';

  static const drawingTime = BaoScenario(
    id: drawingTimeId,
    title: 'Drawing Time',
    route: '/drawing-time',
    trayIcon: Icons.brush_rounded,
    trayAccent: Color(0xFFFFB74D),
    gradient: [
      Color(0xFFFFF8E1),
      Color(0xFFFFE0B2),
      Color(0xFFF8BBD0),
    ],
    steps: [
      BaoScenarioStep(
        label: 'Get Supplies',
        detail: 'Bao gets paper, crayons and a pencil.',
        icon: Icons.palette_rounded,
        idleVideoAsset: '$_drawingFolder/step_1_get_supplies.mp4',
        actionVideoAsset: '$_drawingFolder/step_1_get_supplies_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Set Up Table',
        detail: 'Bao places everything neatly on the table.',
        icon: Icons.table_restaurant_rounded,
        idleVideoAsset: '$_drawingFolder/step_2_set_up_table.mp4',
        actionVideoAsset: '$_drawingFolder/step_2_set_up_table_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Draw Picture',
        detail: 'Bao happily draws a colorful picture.',
        icon: Icons.brush_rounded,
        idleVideoAsset: '$_drawingFolder/step_3_draw_picture.mp4',
        actionVideoAsset: '$_drawingFolder/step_3_draw_picture_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Add Details',
        detail: 'Bao adds flowers, clouds and a little house.',
        icon: Icons.local_florist_rounded,
        idleVideoAsset: '$_drawingFolder/step_4_add_details.mp4',
        actionVideoAsset: '$_drawingFolder/step_4_add_details_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Display Artwork',
        detail: 'Bao proudly places the finished drawing on the refrigerator.',
        icon: Icons.kitchen_rounded,
        idleVideoAsset: '$_drawingFolder/step_5_display_artwork.mp4',
        actionVideoAsset: '$_drawingFolder/step_5_display_artwork_action.mp4',
      ),
    ],
  );

  static const rainyDay = BaoScenario(
    id: rainyDayId,
    title: 'Rainy Day',
    route: '/rainy-day',
    trayIcon: Icons.umbrella_rounded,
    trayAccent: Color(0xFF64B5F6),
    gradient: [
      Color(0xFFE3F2FD),
      Color(0xFFB3E5FC),
      Color(0xFF90CAF9),
    ],
    steps: [
      BaoScenarioStep(
        label: 'Look Outside',
        detail: 'Bao looks through the window at the rain.',
        icon: Icons.visibility_rounded,
        idleVideoAsset: '$_rainyFolder/step_1_look_outside.mp4',
        actionVideoAsset: '$_rainyFolder/step_1_look_outside_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Get Raincoat',
        detail: 'Bao picks up a colorful raincoat.',
        icon: Icons.checkroom_rounded,
        idleVideoAsset: '$_rainyFolder/step_2_get_raincoat.mp4',
        actionVideoAsset: '$_rainyFolder/step_2_get_raincoat_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Put On Boots',
        detail: 'Bao puts on small rain boots.',
        icon: Icons.snowshoeing_rounded,
        idleVideoAsset: '$_rainyFolder/step_3_put_on_boots.mp4',
        actionVideoAsset: '$_rainyFolder/step_3_put_on_boots_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Take Umbrella',
        detail: 'Bao grabs a little umbrella.',
        icon: Icons.umbrella_rounded,
        idleVideoAsset: '$_rainyFolder/step_4_take_umbrella.mp4',
        actionVideoAsset: '$_rainyFolder/step_4_take_umbrella_action.mp4',
      ),
      BaoScenarioStep(
        label: 'Ready for Rain',
        detail: 'Bao stands at the door fully prepared for the rainy day.',
        icon: Icons.door_front_door_rounded,
        idleVideoAsset: '$_rainyFolder/step_5_ready_for_rain.mp4',
        actionVideoAsset: '$_rainyFolder/step_5_ready_for_rain_action.mp4',
      ),
    ],
  );

  static const all = <BaoScenario>[drawingTime, rainyDay];

  static BaoScenario? byId(String id) {
    for (final scenario in all) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }
}
