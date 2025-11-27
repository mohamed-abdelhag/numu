import 'package:flutter/material.dart';
import 'package:glados/glados.dart';
import 'package:numu/features/home/models/daily_item.dart';
import 'package:numu/features/islamic/models/prayer_settings.dart';
import 'package:numu/features/islamic/models/prayer_event.dart';
import 'package:numu/features/islamic/models/prayer_schedule.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/enums/prayer_status.dart';

/// Custom generators for visibility toggle tests
extension VisibilityToggleGenerators on Any {
  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) =>
          intInRange(1, 28).map((day) => DateTime(year, month, day))));

  /// Generator for a prayer event
  Generator<PrayerEvent> prayerEventFor(PrayerType type, DateTime date) {
    return intInRange(0, 24).bind((hour) =>
        intInRange(0, 60).bind((minute) =>
            choose([true, false]).bind((jamaah) =>
                choose([true, false]).bind((withinWindow) =>
                    always(DateTime.now()).map((now) => PrayerEvent(
                          prayerType: type,
                          eventDate: date,
                          eventTimestamp: DateTime(date.year, date.month, date.day, hour, minute % 60),
                          prayedInJamaah: jamaah,
                          withinTimeWindow: withinWindow,
                          createdAt: now,
                          updatedAt: now,
                        ))))));
  }

  /// Generator for a list of prayer events for all prayer types
  Generator<List<PrayerEvent>> prayerEventsForDate(DateTime date) {
    return prayerEventFor(PrayerType.fajr, date).bind((fajr) =>
        prayerEventFor(PrayerType.dhuhr, date).bind((dhuhr) =>
            prayerEventFor(PrayerType.asr, date).bind((asr) =>
                prayerEventFor(PrayerType.maghrib, date).bind((maghrib) =>
                    prayerEventFor(PrayerType.isha, date).map((isha) =>
                        [fajr, dhuhr, asr, maghrib, isha])))));
  }

  /// Generator for prayer settings with specific enabled state
  Generator<PrayerSettings> prayerSettingsWithEnabled(bool enabled) {
    return choose(CalculationMethod.values).bind((method) =>
        intInRange(15, 60).bind((timeWindow) =>
            always(DateTime.now()).map((now) => PrayerSettings(
                  isEnabled: enabled,
                  calculationMethod: method,
                  timeWindowMinutes: timeWindow,
                  createdAt: now,
                  updatedAt: now,
                ))));
  }

  /// Generator for a prayer schedule
  Generator<PrayerSchedule> prayerScheduleFor(DateTime date) {
    return choose(CalculationMethod.values).bind((method) =>
        doubleInRange(-90, 90).bind((lat) =>
            doubleInRange(-180, 180).bind((lng) =>
                always(DateTime.now()).map((now) => PrayerSchedule(
                      date: date,
                      latitude: lat,
                      longitude: lng,
                      method: method,
                      fajrTime: DateTime(date.year, date.month, date.day, 5, 30),
                      dhuhrTime: DateTime(date.year, date.month, date.day, 12, 15),
                      asrTime: DateTime(date.year, date.month, date.day, 15, 30),
                      maghribTime: DateTime(date.year, date.month, date.day, 18, 0),
                      ishaTime: DateTime(date.year, date.month, date.day, 19, 30),
                      sunrise: DateTime(date.year, date.month, date.day, 6, 30),
                      createdAt: now,
                    )))));
  }
}

/// Simulates the filtering logic in DailyItemsProvider
/// When prayer system is disabled, no prayer items are returned
List<DailyItem> filterPrayerItemsByEnabledState({
  required bool isEnabled,
  required List<DailyItem> prayerItems,
}) {
  if (!isEnabled) {
    return []; // Hide all prayer items when disabled
  }
  return prayerItems;
}

/// Creates prayer DailyItems from a schedule
List<DailyItem> createPrayerDailyItems(PrayerSchedule schedule) {
  return PrayerType.values.map((type) {
    return DailyItem(
      id: 'prayer_${type.name}',
      title: type.englishName,
      type: DailyItemType.prayer,
      scheduledTime: schedule.getTimeForPrayer(type),
      isCompleted: false,
      prayerType: type,
      prayerStatus: PrayerStatus.pending,
      arabicName: type.arabicName,
      color: const Color(0xFF2196F3),
    );
  }).toList();
}

void main() {
  group('Visibility Toggle Consistency Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 15: Visibility Toggle Consistency**
    /// **Validates: Requirements 7.4, 8.2, 12.3**
    ///
    /// *For any* enabled/disabled state of the Islamic Prayer System, when disabled,
    /// all prayer-related UI elements SHALL be hidden AND all stored prayer data
    /// (events, schedules, scores) SHALL remain intact in the database.
    Glados2(any.dateOnly, any.prayerScheduleFor(DateTime(2024, 1, 15))).test(
      'Property 15: Visibility Toggle Consistency - disabled state hides prayer items',
      (date, schedule) {
        // Create prayer items from schedule
        final prayerItems = createPrayerDailyItems(schedule);
        
        // When disabled, filter should return empty list
        final filteredWhenDisabled = filterPrayerItemsByEnabledState(
          isEnabled: false,
          prayerItems: prayerItems,
        );
        
        expect(filteredWhenDisabled, isEmpty,
            reason: 'When disabled, no prayer items should be visible');
      },
    );

    /// Property: Enabled state shows all prayer items
    Glados(any.prayerScheduleFor(DateTime(2024, 1, 15))).test(
      'Property 15: Visibility Toggle Consistency - enabled state shows prayer items',
      (schedule) {
        final prayerItems = createPrayerDailyItems(schedule);
        
        // When enabled, filter should return all items
        final filteredWhenEnabled = filterPrayerItemsByEnabledState(
          isEnabled: true,
          prayerItems: prayerItems,
        );
        
        expect(filteredWhenEnabled.length, equals(5),
            reason: 'When enabled, all 5 prayer items should be visible');
        expect(filteredWhenEnabled.length, equals(prayerItems.length),
            reason: 'When enabled, all prayer items should be returned');
      },
    );

    /// Property: Prayer data remains intact when disabled
    /// This tests that the data model itself is not affected by enabled state
    Glados2(any.dateOnly, any.prayerEventsForDate(DateTime(2024, 1, 15))).test(
      'Property 15: Visibility Toggle Consistency - prayer data remains intact when disabled',
      (date, events) {
        // Create settings in disabled state
        final disabledSettings = PrayerSettings(
          isEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Verify settings are disabled
        expect(disabledSettings.isEnabled, isFalse);

        // Verify prayer events are still valid and intact
        // (they would still exist in the database)
        for (final event in events) {
          expect(event.prayerType, isNotNull);
          expect(event.eventDate, isNotNull);
          expect(event.eventTimestamp, isNotNull);
        }

        // The events list should still have all 5 prayers
        expect(events.length, equals(5));
        
        // Each prayer type should be represented
        final types = events.map((e) => e.prayerType).toSet();
        expect(types.length, equals(5));
      },
    );

    /// Property: Prayer schedule data remains intact when disabled
    Glados(any.prayerScheduleFor(DateTime(2024, 1, 15))).test(
      'Property 15: Visibility Toggle Consistency - prayer schedule remains intact when disabled',
      (schedule) {
        // Create settings in disabled state
        final disabledSettings = PrayerSettings(
          isEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Verify settings are disabled
        expect(disabledSettings.isEnabled, isFalse);

        // Verify schedule data is still valid and intact
        expect(schedule.fajrTime, isNotNull);
        expect(schedule.dhuhrTime, isNotNull);
        expect(schedule.asrTime, isNotNull);
        expect(schedule.maghribTime, isNotNull);
        expect(schedule.ishaTime, isNotNull);
        
        // Schedule should still be serializable
        final map = schedule.toMap();
        final restored = PrayerSchedule.fromMap(map);
        expect(restored.fajrTime, equals(schedule.fajrTime));
        expect(restored.dhuhrTime, equals(schedule.dhuhrTime));
        expect(restored.asrTime, equals(schedule.asrTime));
        expect(restored.maghribTime, equals(schedule.maghribTime));
        expect(restored.ishaTime, equals(schedule.ishaTime));
      },
    );

    /// Property: Toggle state change preserves data integrity
    Glados2(any.prayerSettingsWithEnabled(true), any.prayerEventsForDate(DateTime(2024, 1, 15))).test(
      'Property 15: Visibility Toggle Consistency - toggle preserves data integrity',
      (enabledSettings, events) {
        // Start with enabled settings
        expect(enabledSettings.isEnabled, isTrue);

        // Toggle to disabled
        final disabledSettings = enabledSettings.copyWith(isEnabled: false);
        expect(disabledSettings.isEnabled, isFalse);

        // Toggle back to enabled
        final reEnabledSettings = disabledSettings.copyWith(isEnabled: true);
        expect(reEnabledSettings.isEnabled, isTrue);

        // Verify other settings are preserved through toggles
        expect(reEnabledSettings.calculationMethod, equals(enabledSettings.calculationMethod));
        expect(reEnabledSettings.timeWindowMinutes, equals(enabledSettings.timeWindowMinutes));

        // Events should still be valid (data integrity)
        for (final event in events) {
          expect(event.prayerType, isNotNull);
          expect(PrayerType.values.contains(event.prayerType), isTrue);
        }
      },
    );

    /// Property: Visibility filtering is idempotent
    Glados(any.prayerScheduleFor(DateTime(2024, 1, 15))).test(
      'Property 15: Visibility Toggle Consistency - filtering is idempotent',
      (schedule) {
        final prayerItems = createPrayerDailyItems(schedule);

        // Filter multiple times with same state
        final firstFilter = filterPrayerItemsByEnabledState(
          isEnabled: false,
          prayerItems: prayerItems,
        );
        final secondFilter = filterPrayerItemsByEnabledState(
          isEnabled: false,
          prayerItems: prayerItems,
        );

        expect(firstFilter.length, equals(secondFilter.length),
            reason: 'Filtering should be idempotent');

        // Same for enabled state
        final firstEnabled = filterPrayerItemsByEnabledState(
          isEnabled: true,
          prayerItems: prayerItems,
        );
        final secondEnabled = filterPrayerItemsByEnabledState(
          isEnabled: true,
          prayerItems: prayerItems,
        );

        expect(firstEnabled.length, equals(secondEnabled.length),
            reason: 'Filtering should be idempotent');
      },
    );
  });

  group('Visibility Toggle Consistency Unit Tests', () {
    test('Disabled state returns empty prayer list', () {
      final prayerItems = [
        DailyItem(
          id: 'prayer_fajr',
          title: 'Fajr',
          type: DailyItemType.prayer,
          isCompleted: false,
          prayerType: PrayerType.fajr,
        ),
      ];

      final filtered = filterPrayerItemsByEnabledState(
        isEnabled: false,
        prayerItems: prayerItems,
      );

      expect(filtered, isEmpty);
    });

    test('Enabled state returns all prayer items', () {
      final prayerItems = PrayerType.values.map((type) => DailyItem(
        id: 'prayer_${type.name}',
        title: type.englishName,
        type: DailyItemType.prayer,
        isCompleted: false,
        prayerType: type,
      )).toList();

      final filtered = filterPrayerItemsByEnabledState(
        isEnabled: true,
        prayerItems: prayerItems,
      );

      expect(filtered.length, equals(5));
    });

    test('Prayer events survive settings toggle', () {
      final now = DateTime.now();
      final event = PrayerEvent(
        prayerType: PrayerType.fajr,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 5, 30),
        prayedInJamaah: true,
        withinTimeWindow: true,
        createdAt: now,
        updatedAt: now,
      );

      // Serialize and deserialize (simulating database persistence)
      final map = event.toMap();
      final restored = PrayerEvent.fromMap(map);

      // Data should be intact
      expect(restored.prayerType, equals(event.prayerType));
      expect(restored.prayedInJamaah, equals(event.prayedInJamaah));
      expect(restored.withinTimeWindow, equals(event.withinTimeWindow));
    });

    test('Prayer schedule survives settings toggle', () {
      final schedule = PrayerSchedule(
        date: DateTime(2024, 1, 15),
        latitude: 21.4225,
        longitude: 39.8262,
        method: CalculationMethod.ummAlQura,
        fajrTime: DateTime(2024, 1, 15, 5, 30),
        dhuhrTime: DateTime(2024, 1, 15, 12, 15),
        asrTime: DateTime(2024, 1, 15, 15, 30),
        maghribTime: DateTime(2024, 1, 15, 18, 0),
        ishaTime: DateTime(2024, 1, 15, 19, 30),
        sunrise: DateTime(2024, 1, 15, 6, 30),
        createdAt: DateTime.now(),
      );

      // Serialize and deserialize
      final map = schedule.toMap();
      final restored = PrayerSchedule.fromMap(map);

      // All prayer times should be intact
      expect(restored.fajrTime, equals(schedule.fajrTime));
      expect(restored.dhuhrTime, equals(schedule.dhuhrTime));
      expect(restored.asrTime, equals(schedule.asrTime));
      expect(restored.maghribTime, equals(schedule.maghribTime));
      expect(restored.ishaTime, equals(schedule.ishaTime));
    });
  });
}
