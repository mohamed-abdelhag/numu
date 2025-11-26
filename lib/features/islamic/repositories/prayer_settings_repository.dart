import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_settings.dart';
import '../models/enums/calculation_method.dart';
import '../models/enums/prayer_type.dart';

/// Repository layer for prayer settings data access.
/// Handles loading and saving user preferences for the Islamic Prayer System.
///
/// **Validates: Requirements 8.1, 8.2, 8.3**
class PrayerSettingsRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  /// The settings table uses a single row with id = 1.
  static const int _settingsRowId = 1;

  /// Get the current prayer settings.
  /// Returns default settings if none exist.
  ///
  /// **Validates: Requirements 8.1, 8.3**
  Future<PrayerSettings> getSettings() async {
    try {
      final db = await _dbService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerSettingsTable,
        where: 'id = ?',
        whereArgs: [_settingsRowId],
        limit: 1,
      );

      if (maps.isEmpty) {
        // Return default settings if none exist
        CoreLoggingUtility.info(
          'PrayerSettingsRepository',
          'getSettings',
          'No settings found, returning defaults',
        );
        return PrayerSettings.defaults();
      }

      return PrayerSettings.fromMap(maps.first);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'getSettings',
        'Failed to fetch prayer settings: $e',
      );
      rethrow;
    }
  }

  /// Save prayer settings.
  /// Creates or updates the single settings row.
  ///
  /// **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5**
  Future<PrayerSettings> saveSettings(PrayerSettings settings) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now();

      // Ensure we always use id = 1 for the single settings row
      final settingsToSave = settings.copyWith(
        id: _settingsRowId,
        updatedAt: now,
      );

      // Check if settings exist
      final existing = await db.query(
        DatabaseService.prayerSettingsTable,
        where: 'id = ?',
        whereArgs: [_settingsRowId],
        limit: 1,
      );

      if (existing.isEmpty) {
        // Insert new settings
        await db.insert(
          DatabaseService.prayerSettingsTable,
          settingsToSave.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        CoreLoggingUtility.info(
          'PrayerSettingsRepository',
          'saveSettings',
          'Created prayer settings',
        );
      } else {
        // Update existing settings
        await db.update(
          DatabaseService.prayerSettingsTable,
          settingsToSave.toMap(),
          where: 'id = ?',
          whereArgs: [_settingsRowId],
        );

        CoreLoggingUtility.info(
          'PrayerSettingsRepository',
          'saveSettings',
          'Updated prayer settings',
        );
      }

      return settingsToSave;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'saveSettings',
        'Failed to save prayer settings: $e',
      );
      rethrow;
    }
  }


  /// Update the enabled state of the Islamic Prayer System.
  ///
  /// **Validates: Requirements 8.1, 8.2**
  Future<PrayerSettings> setEnabled(bool enabled) async {
    try {
      final currentSettings = await getSettings();
      final updatedSettings = currentSettings.copyWith(
        isEnabled: enabled,
        updatedAt: DateTime.now(),
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'setEnabled',
        'Failed to set enabled state: $e',
      );
      rethrow;
    }
  }

  /// Update the calculation method.
  ///
  /// **Validates: Requirements 8.4**
  Future<PrayerSettings> setCalculationMethod(CalculationMethod method) async {
    try {
      final currentSettings = await getSettings();
      final updatedSettings = currentSettings.copyWith(
        calculationMethod: method,
        updatedAt: DateTime.now(),
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'setCalculationMethod',
        'Failed to set calculation method: $e',
      );
      rethrow;
    }
  }

  /// Update the time window duration.
  ///
  /// **Validates: Requirements 8.5**
  Future<PrayerSettings> setTimeWindowMinutes(int minutes) async {
    if (minutes <= 0) {
      throw ArgumentError('Time window minutes must be positive');
    }

    try {
      final currentSettings = await getSettings();
      final updatedSettings = currentSettings.copyWith(
        timeWindowMinutes: minutes,
        updatedAt: DateTime.now(),
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'setTimeWindowMinutes',
        'Failed to set time window: $e',
      );
      rethrow;
    }
  }

  /// Update the last known location.
  Future<PrayerSettings> setLastLocation(double latitude, double longitude) async {
    try {
      final currentSettings = await getSettings();
      final updatedSettings = currentSettings.copyWith(
        lastLatitude: latitude,
        lastLongitude: longitude,
        updatedAt: DateTime.now(),
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'setLastLocation',
        'Failed to set last location: $e',
      );
      rethrow;
    }
  }

  /// Update reminder settings for a specific prayer.
  Future<PrayerSettings> setReminderEnabled(
    PrayerType type,
    bool enabled,
  ) async {
    try {
      final currentSettings = await getSettings();
      final updatedReminderEnabled = Map<PrayerType, bool>.from(
        currentSettings.reminderEnabled,
      );
      updatedReminderEnabled[type] = enabled;

      final updatedSettings = currentSettings.copyWith(
        reminderEnabled: updatedReminderEnabled,
        updatedAt: DateTime.now(),
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'setReminderEnabled',
        'Failed to set reminder enabled: $e',
      );
      rethrow;
    }
  }

  /// Update reminder offset for a specific prayer.
  Future<PrayerSettings> setReminderOffset(
    PrayerType type,
    int offsetMinutes,
  ) async {
    if (offsetMinutes < 0) {
      throw ArgumentError('Reminder offset cannot be negative');
    }

    try {
      final currentSettings = await getSettings();
      final updatedReminderOffset = Map<PrayerType, int>.from(
        currentSettings.reminderOffsetMinutes,
      );
      updatedReminderOffset[type] = offsetMinutes;

      final updatedSettings = currentSettings.copyWith(
        reminderOffsetMinutes: updatedReminderOffset,
        updatedAt: DateTime.now(),
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'setReminderOffset',
        'Failed to set reminder offset: $e',
      );
      rethrow;
    }
  }

  /// Check if the Islamic Prayer System is enabled.
  Future<bool> isEnabled() async {
    try {
      final settings = await getSettings();
      return settings.isEnabled;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsRepository',
        'isEnabled',
        'Failed to check enabled state: $e',
      );
      rethrow;
    }
  }
}
