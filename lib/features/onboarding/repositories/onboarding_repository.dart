import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  final SharedPreferences _prefs;

  // Keys for SharedPreferences
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingCompletedAtKey = 'onboarding_completed_at';

  OnboardingRepository(this._prefs);

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(_onboardingCompletedKey, true);
    await _prefs.setString(
      _onboardingCompletedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Reset onboarding status (for testing purposes)
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingCompletedKey);
    await _prefs.remove(_onboardingCompletedAtKey);
  }

  /// Get the date when onboarding was completed (if available)
  Future<DateTime?> getOnboardingCompletedAt() async {
    final dateString = _prefs.getString(_onboardingCompletedAtKey);
    if (dateString == null) {
      return null;
    }
    return DateTime.parse(dateString);
  }
}
