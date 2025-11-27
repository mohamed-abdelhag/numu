import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/prayer_schedule.dart';

/// Custom generators for PrayerSchedule tests
extension PrayerScheduleGenerators on Any {
  /// Generator for valid latitude values (-90 to 90)
  Generator<double> get latitude => doubleInRange(-90.0, 90.0);

  /// Generator for valid longitude values (-180 to 180)
  Generator<double> get longitude => doubleInRange(-180.0, 180.0);

  /// Generator for CalculationMethod enum values
  Generator<CalculationMethod> get calculationMethod =>
      choose(CalculationMethod.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for a valid prayer time on a given date
  Generator<DateTime> prayerTimeOnDate(DateTime date, int minHour, int maxHour) {
    // Ensure min < max for intInRange
    final effectiveMaxHour = maxHour > minHour ? maxHour : minHour + 1;
    return intInRange(minHour, effectiveMaxHour).bind((hour) =>
        intInRange(0, 60).map((minute) =>
            DateTime(date.year, date.month, date.day, hour, minute % 60)));
  }

  /// Generator for a complete PrayerSchedule with valid prayer time ordering
  Generator<PrayerSchedule> get prayerSchedule {
    return dateOnly.bind((date) =>
        latitude.bind((lat) =>
            longitude.bind((lng) =>
                calculationMethod.bind((method) =>
                    // Fajr: 4-5 AM
                    prayerTimeOnDate(date, 4, 6).bind((fajr) =>
                        // Sunrise: 6-7 AM (after Fajr)
                        prayerTimeOnDate(date, 6, 8).bind((sunrise) =>
                            // Dhuhr: 12-13 PM
                            prayerTimeOnDate(date, 12, 14).bind((dhuhr) =>
                                // Asr: 15-16 PM
                                prayerTimeOnDate(date, 15, 17).bind((asr) =>
                                    // Maghrib: 18-19 PM
                                    prayerTimeOnDate(date, 18, 20).bind((maghrib) =>
                                        // Isha: 19-21 PM
                                        prayerTimeOnDate(date, 19, 22).bind((isha) =>
                                            // CreatedAt: current time
                                            always(DateTime.now()).map((createdAt) =>
                                                PrayerSchedule(
                                                  date: date,
                                                  latitude: lat,
                                                  longitude: lng,
                                                  method: method,
                                                  fajrTime: fajr,
                                                  dhuhrTime: dhuhr,
                                                  asrTime: asr,
                                                  maghribTime: maghrib,
                                                  ishaTime: isha,
                                                  sunrise: sunrise,
                                                  createdAt: createdAt,
                                                ))))))))))));
  }
}

void main() {
  group('PrayerSchedule Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 1: Prayer Schedule Round-Trip Persistence**
    /// **Validates: Requirements 1.2**
    ///
    /// *For any* valid prayer schedule with date, coordinates, calculation method,
    /// and five prayer times, storing the schedule and then retrieving it by date
    /// SHALL produce an equivalent schedule with all fields preserved.
    Glados(any.prayerSchedule).test(
      'Property 1: Prayer Schedule Round-Trip Persistence - toMap/fromMap preserves all fields',
      (schedule) {
        // Serialize to map (simulating database storage)
        final map = schedule.toMap();

        // Deserialize from map (simulating database retrieval)
        final restored = PrayerSchedule.fromMap(map);

        // Verify all fields are preserved
        expect(restored.date.year, equals(schedule.date.year));
        expect(restored.date.month, equals(schedule.date.month));
        expect(restored.date.day, equals(schedule.date.day));
        expect(restored.latitude, equals(schedule.latitude));
        expect(restored.longitude, equals(schedule.longitude));
        expect(restored.method, equals(schedule.method));
        expect(restored.fajrTime, equals(schedule.fajrTime));
        expect(restored.dhuhrTime, equals(schedule.dhuhrTime));
        expect(restored.asrTime, equals(schedule.asrTime));
        expect(restored.maghribTime, equals(schedule.maghribTime));
        expect(restored.ishaTime, equals(schedule.ishaTime));
        expect(restored.sunrise, equals(schedule.sunrise));
        expect(restored.createdAt, equals(schedule.createdAt));
      },
    );
  });

  group('PrayerSchedule Helper Methods Tests', () {
    test('getTimeForPrayer returns correct time for each prayer type', () {
      final date = DateTime(2024, 1, 15);
      final schedule = PrayerSchedule(
        date: date,
        latitude: 21.4225,
        longitude: 39.8262,
        method: CalculationMethod.ummAlQura,
        fajrTime: DateTime(2024, 1, 15, 5, 30),
        dhuhrTime: DateTime(2024, 1, 15, 12, 15),
        asrTime: DateTime(2024, 1, 15, 15, 30),
        maghribTime: DateTime(2024, 1, 15, 18, 0),
        ishaTime: DateTime(2024, 1, 15, 19, 30),
        sunrise: DateTime(2024, 1, 15, 6, 45),
        createdAt: DateTime.now(),
      );

      expect(schedule.getTimeForPrayer(PrayerType.fajr), equals(schedule.fajrTime));
      expect(schedule.getTimeForPrayer(PrayerType.dhuhr), equals(schedule.dhuhrTime));
      expect(schedule.getTimeForPrayer(PrayerType.asr), equals(schedule.asrTime));
      expect(schedule.getTimeForPrayer(PrayerType.maghrib), equals(schedule.maghribTime));
      expect(schedule.getTimeForPrayer(PrayerType.isha), equals(schedule.ishaTime));
    });

    test('getTimeWindowEnd returns correct end time', () {
      final date = DateTime(2024, 1, 15);
      final schedule = PrayerSchedule(
        date: date,
        latitude: 21.4225,
        longitude: 39.8262,
        method: CalculationMethod.ummAlQura,
        fajrTime: DateTime(2024, 1, 15, 5, 30),
        dhuhrTime: DateTime(2024, 1, 15, 12, 15),
        asrTime: DateTime(2024, 1, 15, 15, 30),
        maghribTime: DateTime(2024, 1, 15, 18, 0),
        ishaTime: DateTime(2024, 1, 15, 19, 30),
        sunrise: DateTime(2024, 1, 15, 6, 45),
        createdAt: DateTime.now(),
      );

      // Default 30-minute window
      expect(
        schedule.getTimeWindowEnd(PrayerType.fajr, 30),
        equals(DateTime(2024, 1, 15, 6, 0)),
      );
      expect(
        schedule.getTimeWindowEnd(PrayerType.dhuhr, 30),
        equals(DateTime(2024, 1, 15, 12, 45)),
      );
    });

    test('copyWith creates new instance with updated fields', () {
      final original = PrayerSchedule(
        date: DateTime(2024, 1, 15),
        latitude: 21.4225,
        longitude: 39.8262,
        method: CalculationMethod.ummAlQura,
        fajrTime: DateTime(2024, 1, 15, 5, 30),
        dhuhrTime: DateTime(2024, 1, 15, 12, 15),
        asrTime: DateTime(2024, 1, 15, 15, 30),
        maghribTime: DateTime(2024, 1, 15, 18, 0),
        ishaTime: DateTime(2024, 1, 15, 19, 30),
        sunrise: DateTime(2024, 1, 15, 6, 45),
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        latitude: 40.7128,
        longitude: -74.0060,
        method: CalculationMethod.isna,
      );

      expect(updated.latitude, equals(40.7128));
      expect(updated.longitude, equals(-74.0060));
      expect(updated.method, equals(CalculationMethod.isna));
      // Original fields should be preserved
      expect(updated.date, equals(original.date));
      expect(updated.fajrTime, equals(original.fajrTime));
    });
  });
}
