import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/services/prayer_reminder_service.dart';

/// Custom generators for PrayerReminderService tests
extension PrayerReminderGenerators on Any {
  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for a valid prayer time (future time within a day)
  Generator<DateTime> get prayerTime {
    return intInRange(2024, 2026).bind((year) =>
        intInRange(1, 12).bind((month) =>
            intInRange(1, 28).bind((day) =>
                intInRange(0, 23).bind((hour) =>
                    intInRange(0, 59).map((minute) =>
                        DateTime(year, month, day, hour, minute))))));
  }

  /// Generator for reminder offset in minutes (0 to 60 minutes)
  Generator<int> get reminderOffsetMinutes => intInRange(0, 60);

  /// Generator for positive reminder offset (1 to 60 minutes)
  Generator<int> get positiveReminderOffset => intInRange(1, 60);
}

void main() {
  group('PrayerReminderService Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 11: Reminder Scheduling with Offset**
    /// **Validates: Requirements 5.2, 5.3**
    ///
    /// *For any* prayer time and reminder offset in minutes, the scheduled reminder time
    /// SHALL equal the prayer time minus the offset duration.
    Glados2(any.prayerTime, any.reminderOffsetMinutes).test(
      'Property 11: Reminder Scheduling with Offset - reminder time equals prayer time minus offset',
      (prayerTime, offsetMinutes) {
        // Calculate the reminder time using the service's static method
        final reminderTime = PrayerReminderService.calculateReminderTime(
          prayerTime,
          offsetMinutes,
        );

        // Expected reminder time is prayer time minus offset
        final expectedReminderTime = prayerTime.subtract(
          Duration(minutes: offsetMinutes),
        );

        // Verify the reminder time equals the expected time
        expect(reminderTime, equals(expectedReminderTime),
            reason: 'Reminder time should equal prayer time minus offset duration');

        // Verify the difference is exactly the offset
        final difference = prayerTime.difference(reminderTime);
        expect(difference.inMinutes, equals(offsetMinutes),
            reason: 'Difference between prayer time and reminder time should equal offset');
      },
    );

    /// Additional property: Zero offset means reminder at prayer time
    Glados(any.prayerTime).test(
      'Zero offset means reminder at prayer time',
      (prayerTime) {
        final reminderTime = PrayerReminderService.calculateReminderTime(
          prayerTime,
          0,
        );

        expect(reminderTime, equals(prayerTime),
            reason: 'With zero offset, reminder time should equal prayer time');
      },
    );

    /// Additional property: Reminder time is always before or equal to prayer time
    Glados2(any.prayerTime, any.positiveReminderOffset).test(
      'Reminder time is always before prayer time for positive offset',
      (prayerTime, offsetMinutes) {
        final reminderTime = PrayerReminderService.calculateReminderTime(
          prayerTime,
          offsetMinutes,
        );

        expect(reminderTime.isBefore(prayerTime), isTrue,
            reason: 'Reminder time should be before prayer time for positive offset');
      },
    );
  });

  group('PrayerReminderService Unit Tests', () {
    test('calculateReminderTime with 15 minute offset', () {
      final prayerTime = DateTime(2024, 6, 15, 12, 30);
      final reminderTime = PrayerReminderService.calculateReminderTime(
        prayerTime,
        15,
      );

      expect(reminderTime, equals(DateTime(2024, 6, 15, 12, 15)));
    });

    test('calculateReminderTime with 30 minute offset', () {
      final prayerTime = DateTime(2024, 6, 15, 5, 0);
      final reminderTime = PrayerReminderService.calculateReminderTime(
        prayerTime,
        30,
      );

      expect(reminderTime, equals(DateTime(2024, 6, 15, 4, 30)));
    });

    test('calculateReminderTime handles hour boundary crossing', () {
      final prayerTime = DateTime(2024, 6, 15, 13, 10);
      final reminderTime = PrayerReminderService.calculateReminderTime(
        prayerTime,
        20,
      );

      expect(reminderTime, equals(DateTime(2024, 6, 15, 12, 50)));
    });

    test('calculateReminderTime handles day boundary crossing', () {
      final prayerTime = DateTime(2024, 6, 15, 0, 15);
      final reminderTime = PrayerReminderService.calculateReminderTime(
        prayerTime,
        30,
      );

      expect(reminderTime, equals(DateTime(2024, 6, 14, 23, 45)));
    });

    test('PrayerReminderSettings equality', () {
      const settings1 = PrayerReminderSettings(
        prayerType: PrayerType.fajr,
        isEnabled: true,
        offsetMinutes: 15,
      );
      const settings2 = PrayerReminderSettings(
        prayerType: PrayerType.fajr,
        isEnabled: true,
        offsetMinutes: 15,
      );
      const settings3 = PrayerReminderSettings(
        prayerType: PrayerType.dhuhr,
        isEnabled: true,
        offsetMinutes: 15,
      );

      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
    });

    test('PrayerReminderSettings hashCode consistency', () {
      const settings1 = PrayerReminderSettings(
        prayerType: PrayerType.fajr,
        isEnabled: true,
        offsetMinutes: 15,
      );
      const settings2 = PrayerReminderSettings(
        prayerType: PrayerType.fajr,
        isEnabled: true,
        offsetMinutes: 15,
      );

      expect(settings1.hashCode, equals(settings2.hashCode));
    });

    test('PrayerReminderSettings toString', () {
      const settings = PrayerReminderSettings(
        prayerType: PrayerType.fajr,
        isEnabled: true,
        offsetMinutes: 15,
      );

      expect(settings.toString(), contains('fajr'));
      expect(settings.toString(), contains('true'));
      expect(settings.toString(), contains('15'));
    });
  });
}
