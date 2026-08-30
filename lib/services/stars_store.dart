import 'package:shared_preferences/shared_preferences.dart';

/// Persists total stars earned.
class StarsStore {
  StarsStore._();

  static const _key = 'bao_stars_total';

  static Future<int> total() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 12;
  }

  static Future<int> add(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_key) ?? 12) + amount;
    await prefs.setInt(_key, next < 0 ? 0 : next);
    return next;
  }
}
