import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  final SharedPreferences _prefs;

  // Keys for SharedPreferences
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingCompletedAtKey = 'onboarding_completed_at';

  OnboardingRepository(this._prefs);

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    try {
      return _prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      // If SharedPreferences fails, assume onboarding is not completed
      // This ensures the app doesn't crash and users see onboarding
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    try {
      final success = await _prefs.setBool(_onboardingCompletedKey, true);
      if (!success) {
        throw Exception('Failed to save onboarding completion status');
      }
      
      final dateSuccess = await _prefs.setString(
        _onboardingCompletedAtKey,
        DateTime.now().toIso8601String(),
      );
      if (!dateSuccess) {
        throw Exception('Failed to save onboarding completion date');
      }
    } catch (e) {
      throw Exception('Failed to mark onboarding as completed: $e');
    }
  }

  /// Reset onboarding status (for testing purposes)
  Future<void> resetOnboarding() async {
    try {
      await _prefs.remove(_onboardingCompletedKey);
      await _prefs.remove(_onboardingCompletedAtKey);
    } catch (e) {
      throw Exception('Failed to reset onboarding status: $e');
    }
  }

  /// Get the date when onboarding was completed (if available)
  Future<DateTime?> getOnboardingCompletedAt() async {
    try {
      final dateString = _prefs.getString(_onboardingCompletedAtKey);
      if (dateString == null) {
        return null;
      }
      return DateTime.parse(dateString);
    } catch (e) {
      // If parsing fails, return null gracefully
      return null;
    }
  }
}
