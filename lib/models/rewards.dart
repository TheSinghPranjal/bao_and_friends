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

/// Drink Milk reward math (same loop as Drink Water; reached from Feed).
abstract final class DrinkMilkRules {
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
        message: 'Amazing! Bao loves that milk!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy milk! One star for you!'
          : 'Great sipping! Keep going!',
    );
  }
}

/// Eat Apple reward math (same loop as Drink Water; reached from Feed).
abstract final class EatAppleRules {
  static const int maxApples = 4;
  static const int applesForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 apple → 1 star. All required apples → 3 stars + 1 Magic Bean.
  static RewardResult rewardForApples(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep munching!');
    }
    if (completed >= applesForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao loves that apple!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy apple! One star for you!'
          : 'Great munching! Keep going!',
    );
  }
}

/// Eat Banana reward math (same loop as Eat Apple; reached from Feed).
abstract final class EatBananaRules {
  static const int maxBananas = 4;
  static const int bananasForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 banana → 1 star. All required bananas → 3 stars + 1 Magic Bean.
  static RewardResult rewardForBananas(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep munching!');
    }
    if (completed >= bananasForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao loves that banana!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy banana! One star for you!'
          : 'Great munching! Keep going!',
    );
  }
}

/// Eat Veggies reward math (same loop as Eat Apple; reached from Feed).
abstract final class EatVeggiesRules {
  static const int maxVeggies = 4;
  static const int veggiesForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 serving → 1 star. All required servings → 3 stars + 1 Magic Bean.
  static RewardResult rewardForVeggies(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep munching!');
    }
    if (completed >= veggiesForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao loves those veggies!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy veggies! One star for you!'
          : 'Great munching! Keep going!',
    );
  }
}

/// Eat Sandwich reward math (same loop as Eat Apple; reached from Feed).
abstract final class EatSandwichRules {
  static const int maxSandwiches = 4;
  static const int sandwichesForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 sandwich → 1 star. All required sandwiches → 3 stars + 1 Magic Bean.
  static RewardResult rewardForSandwiches(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep munching!');
    }
    if (completed >= sandwichesForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao loves that sandwich!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy sandwich! One star for you!'
          : 'Great munching! Keep going!',
    );
  }
}

/// Feed reward math — tap floating foods (same loop shape as Drink Water).
abstract final class FeedRules {
  static const int maxFoods = 10;
  static const int foodsForFullReward = 10;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 food → 1 star. All required foods → 3 stars + 1 Magic Bean.
  static RewardResult rewardForFoods(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep feeding Bao!');
    }
    if (completed >= foodsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Yum! Bao feels happy and full!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Yummy! One star for you!'
          : 'Great feeding! Keep going!',
    );
  }
}

/// Chores reward math — tap floating chores (same loop shape as Feed).
abstract final class ChoresRules {
  static const int maxChores = 9;
  static const int choresForFullReward = 9;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 chore → 1 star. All required chores → 3 stars + 1 Magic Bean.
  static RewardResult rewardForChores(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep helping Bao!');
    }
    if (completed >= choresForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing helper! Bao is so proud!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Great job! One star for you!'
          : 'Great helping! Keep going!',
    );
  }
}

/// Wake Up — Bao sleeps every [sleepInterval]; wake resets the timer.
abstract final class WakeUpRules {
  static const Duration sleepInterval = Duration(hours: 1);

  static const RewardResult reward = RewardResult(
    stars: 1,
    magicBeans: 0,
    message: 'Good morning! Bao is awake and ready!',
  );
}

/// Chore cooldown timers (positive waiting, never punishment).
abstract final class ChoreTimers {
  static const Duration brushTeeth = Duration(hours: 6);
  static const Duration makeBed = Duration(hours: 8);
  static const Duration washFace = Duration(hours: 8);
  static const Duration combHair = Duration(hours: 8);
  static const Duration wearShoes = Duration(hours: 24);
}
