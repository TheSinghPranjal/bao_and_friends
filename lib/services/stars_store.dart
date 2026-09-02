import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists total stars earned — one shared count for the whole app.
class StarsStore {
  StarsStore._();

  static const _key = 'bao_stars_total';
  static const _default = 12;

  /// Live total for status-bar pills (updated by [total] / [add]).
  static final ValueNotifier<int> totalListenable = ValueNotifier(_default);

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<int> total() async {
    final prefs = await _prefs;
    final v = prefs.getInt(_key) ?? _default;
    if (totalListenable.value != v) {
      totalListenable.value = v;
    }
    return v;
  }

  static Future<int> add(int amount) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_key) ?? _default;
    final next = current + amount;
    final clamped = next < 0 ? 0 : next;
    await prefs.setInt(_key, clamped);
    totalListenable.value = clamped;
    return clamped;
  }
}
