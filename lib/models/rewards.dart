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

/// Play reward math — complete games from the Play tray (same loop as Chores).
abstract final class PlayRules {
  static const int maxGames = 12;
  static const int gamesForFullReward = 12;
  static const Duration reminderInterval = Duration(hours: 4);

  /// 1 game → 1 star. All required games → 3 stars + 1 Magic Bean.
  static RewardResult rewardForGames(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep playing with Bao!');
    }
    if (completed >= gamesForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! What a fun play day!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Great game! One star for you!'
          : 'Great playing! Keep going!',
    );
  }
}

/// Per-game play reward math (same loop as Make Bed; reached from Play).
abstract final class PlayGameRules {
  static const int maxSteps = 4;
  static const int stepsForFullReward = 4;

  static RewardResult rewardForGame(String gameLabel, int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep playing!');
    }
    if (completed >= stepsForFullReward) {
      return RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao loved $gameLabel!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Fun $gameLabel! One star for you!'
          : 'Great playing! Keep going!',
    );
  }
}

/// Chores reward math — tap floating chores (same loop shape as Feed).
abstract final class ChoresRules {
  static const int maxChores = 10;
  static const int choresForFullReward = 10;
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

/// Comb Hair reward math (same loop as Make Bed; reached from Chores).
abstract final class CombHairRules {
  static const int maxSteps = 4;
  static const int stepsForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 8);

  /// 1 step → 1 star. All required steps → 3 stars + 1 Magic Bean.
  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep combing!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao\'s hair looks so neat!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Nice combing! One star for you!'
          : 'Great combing! Keep going!',
    );
  }
}

/// Wash Face reward math (same loop as Make Bed; reached from Chores).
abstract final class WashFaceRules {
  static const int maxSteps = 4;
  static const int stepsForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 8);

  /// 1 step → 1 star. All required steps → 3 stars + 1 Magic Bean.
  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep washing!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao\'s face feels so fresh!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Nice washing! One star for you!'
          : 'Great washing! Keep going!',
    );
  }
}

/// Bath reward math — tap floating bath bubbles.
abstract final class BathRules {
  static const int maxSteps = 4;
  static const int stepsForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 6);

  /// 1 step → 1 star. All required steps → 3 stars + 1 Magic Bean.
  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep bathing!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao is squeaky clean!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Nice bathing! One star for you!'
          : 'Great bathing! Keep going!',
    );
  }
}

/// Get Dressed — clothes then tie (2 steps).
abstract final class GetDressedRules {
  static const int maxSteps = 2;
  static const int stepsForFullReward = 2;
  static const Duration reminderInterval = Duration(hours: 12);

  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Help Bao get dressed!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao is ready for the day!',
      );
    }
    return const RewardResult(
      stars: 1,
      message: 'Clothes on! Now add the tie!',
    );
  }
}

/// Wear Shoes — shoes then bag (2 steps).
abstract final class WearShoesRules {
  static const int maxSteps = 2;
  static const int stepsForFullReward = 2;
  static const Duration reminderInterval = Duration(hours: 12);

  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Help Bao put on shoes!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao is ready to go!',
      );
    }
    return const RewardResult(
      stars: 1,
      message: 'Shoes on! Now grab the bag!',
    );
  }
}

/// Alphabet lesson complete.
abstract final class LearnAlphabetRules {
  static RewardResult rewardForComplete() {
    return const RewardResult(
      stars: 3,
      magicBeans: 1,
      message: 'Amazing! You learned A to Z with Bao!',
    );
  }
}

/// Brush Teeth reward math (same loop as Make Bed; reached from Chores).
abstract final class BrushTeethRules {
  static const int maxSteps = 4;
  static const int stepsForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 6);

  /// 1 step → 1 star. All required steps → 3 stars + 1 Magic Bean.
  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep brushing!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! Bao\'s teeth are sparkling!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Nice brushing! One star for you!'
          : 'Great brushing! Keep going!',
    );
  }
}

/// Make Bed reward math (same loop as Eat Apple; reached from Chores).
abstract final class MakeBedRules {
  static const int maxSteps = 4;
  static const int stepsForFullReward = 4;
  static const Duration reminderInterval = Duration(hours: 8);

  /// 1 step → 1 star. All required steps → 3 stars + 1 Magic Bean.
  static RewardResult rewardForSteps(int completed) {
    if (completed <= 0) {
      return const RewardResult(message: 'Keep helping!');
    }
    if (completed >= stepsForFullReward) {
      return const RewardResult(
        stars: 3,
        magicBeans: 1,
        message: 'Amazing! The bed looks so cozy!',
      );
    }
    return RewardResult(
      stars: 1,
      message: completed == 1
          ? 'Nice work! One star for you!'
          : 'Great helping! Keep going!',
    );
  }
}

/// Wake Up — after a night wake Bao stays awake [DefaultSchedules.awakeAfterNightWakeMinutes].
abstract final class WakeUpRules {
  static const Duration sleepInterval = Duration(minutes: 30);

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
  static const Duration bath = Duration(hours: 6);
  static const Duration getDressed = Duration(hours: 12);
  static const Duration combHair = Duration(hours: 8);
  static const Duration wearShoes = Duration(hours: 24);
}
