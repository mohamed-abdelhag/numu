import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_settings.dart';
import '../models/enums/calculation_method.dart';
import '../models/enums/prayer_type.dart';
import '../repositories/prayer_settings_repository.dart';

part 'prayer_settings_provider.g.dart';

/// Provider for managing Islamic Prayer System settings.
/// Handles enabled state, calculation method, time window, and reminder configuration.
///
/// **Validates: Requirements 8.1, 8.2, 8.3, 9.1, 9.2**
@riverpod
class PrayerSettingsNotifier extends _$PrayerSettingsNotifier {
  late final PrayerSettingsRepository _repository;
  
  /// Track if the notifier is still mounted/active
  bool _isMounted = true;

  @override
  Future<PrayerSettings> build() async {
    _repository = PrayerSettingsRepository();
    _isMounted = true;
    
    // Set up disposal callback to mark as unmounted
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'dispose',
        'Provider disposed, marking as unmounted',
      );
    });
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'build',
        'Loading prayer settings',
      );
      
      final settings = await _repository.getSettings();
      
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'build',
        'Loaded prayer settings: enabled=${settings.isEnabled}',
      );
      
      return settings;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'build',
        'Failed to load prayer settings: $e\n$stackTrace',
      );
      rethrow;
    }
  }


  /// Toggle the enabled state of the Islamic Prayer System.
  ///
  /// **Validates: Requirements 8.1, 8.2, 9.1, 9.2**
  Future<void> setEnabled(bool enabled) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setEnabled',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setEnabled',
        'Setting enabled state to: $enabled',
      );
      
      final updatedSettings = await _repository.setEnabled(enabled);
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'PrayerSettingsProvider',
          'setEnabled',
          'State update cancelled: provider disposed',
        );
        return;
      }
      
      state = AsyncValue.data(updatedSettings);
      
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setEnabled',
        'Successfully updated enabled state to: $enabled',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'setEnabled',
        'Failed to set enabled state: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update the calculation method for prayer times.
  ///
  /// **Validates: Requirements 8.4**
  Future<void> setCalculationMethod(CalculationMethod method) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setCalculationMethod',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setCalculationMethod',
        'Setting calculation method to: ${method.displayName}',
      );
      
      final updatedSettings = await _repository.setCalculationMethod(method);
      
      if (!_isMounted) return;
      
      state = AsyncValue.data(updatedSettings);
      
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setCalculationMethod',
        'Successfully updated calculation method',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'setCalculationMethod',
        'Failed to set calculation method: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update the time window duration in minutes.
  ///
  /// **Validates: Requirements 8.5**
  Future<void> setTimeWindowMinutes(int minutes) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setTimeWindowMinutes',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setTimeWindowMinutes',
        'Setting time window to: $minutes minutes',
      );
      
      final updatedSettings = await _repository.setTimeWindowMinutes(minutes);
      
      if (!_isMounted) return;
      
      state = AsyncValue.data(updatedSettings);
      
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setTimeWindowMinutes',
        'Successfully updated time window',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'setTimeWindowMinutes',
        'Failed to set time window: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update the last known location.
  Future<void> setLastLocation(double latitude, double longitude) async {
    if (!_isMounted) return;
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setLastLocation',
        'Setting last location to: ($latitude, $longitude)',
      );
      
      final updatedSettings = await _repository.setLastLocation(latitude, longitude);
      
      if (!_isMounted) return;
      
      state = AsyncValue.data(updatedSettings);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'setLastLocation',
        'Failed to set last location: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update reminder enabled state for a specific prayer.
  Future<void> setReminderEnabled(PrayerType type, bool enabled) async {
    if (!_isMounted) return;
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setReminderEnabled',
        'Setting reminder for ${type.englishName} to: $enabled',
      );
      
      final updatedSettings = await _repository.setReminderEnabled(type, enabled);
      
      if (!_isMounted) return;
      
      state = AsyncValue.data(updatedSettings);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'setReminderEnabled',
        'Failed to set reminder enabled: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update reminder offset for a specific prayer.
  Future<void> setReminderOffset(PrayerType type, int offsetMinutes) async {
    if (!_isMounted) return;
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'setReminderOffset',
        'Setting reminder offset for ${type.englishName} to: $offsetMinutes minutes',
      );
      
      final updatedSettings = await _repository.setReminderOffset(type, offsetMinutes);
      
      if (!_isMounted) return;
      
      state = AsyncValue.data(updatedSettings);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'setReminderOffset',
        'Failed to set reminder offset: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Save complete settings object.
  Future<void> saveSettings(PrayerSettings settings) async {
    if (!_isMounted) return;
    
    try {
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'saveSettings',
        'Saving complete settings',
      );
      
      final updatedSettings = await _repository.saveSettings(settings);
      
      if (!_isMounted) return;
      
      state = AsyncValue.data(updatedSettings);
      
      CoreLoggingUtility.info(
        'PrayerSettingsProvider',
        'saveSettings',
        'Successfully saved settings',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerSettingsProvider',
        'saveSettings',
        'Failed to save settings: $e\n$stackTrace',
      );
      
      if (!_isMounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh settings from the repository.
  Future<void> refresh() async {
    if (!_isMounted) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getSettings());
  }
}

/// Convenience provider for checking if the Islamic Prayer System is enabled.
///
/// **Validates: Requirements 8.1, 8.2, 9.2**
@riverpod
Future<bool> isPrayerSystemEnabled(Ref ref) async {
  final settings = await ref.watch(prayerSettingsProvider.future);
  return settings.isEnabled;
}
