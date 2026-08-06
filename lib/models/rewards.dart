/// Positive-only needs language. Never hungry / sad / crying / sick / angry.
enum NeedState {
  ready('Ready', 'Bao is ready for this!'),
  interested('Interested', 'Bao would love to try this!'),
  waiting('Waiting', 'This will be ready soon.'),
  letsPlay('Let\'s Play', 'Time to play together!');

  const NeedState(this.label, this.voiceLine);
  final String label;
  final String voiceLine;
}

class RewardResult {
  const RewardResult({
    this.stars = 0,
    this.magicBeans = 0,
    this.message = 'Great job!',
  });

  final int stars;
  final int magicBeans;
  final String message;
}

/// Drink Water reward math (master loop).
abstract final class DrinkWaterRules {
  static const int maxGlasses = 4;
  static const int glassesForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 glass → 1 star. All required glasses → 3 stars + 1 Magic Bean.
  static RewardResult rewardForGlasses(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep sipping!');
    }
    if (completed >= glassesForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao feels refreshed!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy water! One star for you!'
          : 'Great sipping! Keep going!',
    );
  }
}

/// Chore cooldown timers (positive waiting, never punishment).
abstract final class ChoreTimers {
  static const Duration brushTeeth = Duration(hours: 6);
  static const Duration makeBed = Duration(hours: 8);
  static const Duration washFace = Duration(hours: 8);
  static const Duration combHair = Duration(hours: 8);
  static const Duration wearShoes = Duration(hours: 24);
}
