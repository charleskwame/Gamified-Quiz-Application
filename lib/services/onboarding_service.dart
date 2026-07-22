import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _key = 'has_seen_onboarding_tour';

  /// Returns true if the user has NOT yet seen the tour.
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  /// Mark the tour as completed so it never shows again.
  static Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Reset for testing — shows tour again on next launch.
  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
