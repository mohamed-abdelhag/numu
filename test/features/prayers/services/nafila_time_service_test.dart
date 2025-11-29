import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/prayer_schedule.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/nafila_type.dart';
import 'package:numu/features/islamic/services/nafila_time_service.dart';

/// Custom generators for NafilaTimeService tests
extension NafilaTimeGenerators on Any {
  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2025).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for prayer schedule with variable times
  Generator<PrayerSchedule> get variablePrayerSchedule {
    return dateOnly.bind((date) =>
        intInRange(4, 5).bind((fajrHour) =>
            intInRange(0, 30).bind((fajrMin) =>
                intInRange(0, 30).bind((sunriseOffset) =>
                    intInRange(0, 30).map((dhuhrOffset) {
                      final fajrTime = DateTime(date.year, date.month, date.day, fajrHour, fajrMin);
                      final sunriseTime = fajrTime.add(Duration(hours: 1, minutes: 30 + sunriseOffset));
                      final dhuhrTime = sunriseTime.add(Duration(hours: 5, minutes: dhuhrOffset));
                      
                      return PrayerSchedule(
                        date: date,
                        latitude: 21.4225,
                        longitude: 39.8262,
                        method: CalculationMethod.ummAlQura,
                        fajrTime: fajrTime,
                        sunrise: sunriseTime,
                        dhuhrTime: dhuhrTime,
                        asrTime: dhuhrTime.add(const Duration(hours: 3)),
                        maghribTime: dhuhrTime.add(const Duration(hours: 6)),
                        ishaTime: dhuhrTime.add(const Duration(hours: 8)),
                        createdAt: DateTime.now(),
                      );
                    })))));
  }
}

void main() {
  late NafilaTimeService service;

  setUp(() {
    service = NafilaTimeService();
  });

  group('NafilaTimeService Property Tests', () {
    /// **Feature: nafila-prayer-system, Property 1: Sunnah Fajr Time Validation**
    /// **Validates: Requirements 1.3**
    Glados(any.variablePrayerSchedule).test(
      'Property 1: Sunnah Fajr Time Validation - times in window are valid',
      (schedule) {
        final fajrMinutes = schedule.fajrTime.hour * 60 + schedule.fajrTime.minute;
        final sunriseMinutes = schedule.sunrise.hour * 60 + schedule.sunrise.minute;
        if (sunriseMinutes - fajrMinutes < 2) return;
        
        expect(service.isValidTimeForSunnahFajr(schedule.fajrTime, schedule), isTrue);
        
        final middleMinutes = (fajrMinutes + sunriseMinutes) ~/ 2;
        final middleTime = DateTime(schedule.date.year, schedule.date.month, schedule.date.day, middleMinutes ~/ 60, middleMinutes % 60);
        expect(service.isValidTimeForSunnahFajr(middleTime, schedule), isTrue);
        
        expect(service.isValidTimeForSunnahFajr(schedule.sunrise, schedule), isFalse);
      },
    );

    Glados(any.variablePrayerSchedule).test(
      'Property 1: Sunnah Fajr Time Validation - times outside window are invalid',
      (schedule) {
        final beforeFajr = schedule.fajrTime.subtract(const Duration(minutes: 30));
        expect(service.isValidTimeForSunnahFajr(beforeFajr, schedule), isFalse);
        
        final afterSunrise = schedule.sunrise.add(const Duration(minutes: 30));
        expect(service.isValidTimeForSunnahFajr(afterSunrise, schedule), isFalse);
      },
    );


    /// **Feature: nafila-prayer-system, Property 2: Duha Time Validation**
    /// **Validates: Requirements 1.4**
    Glados(any.variablePrayerSchedule).test(
      'Property 2: Duha Time Validation - times in window are valid',
      (schedule) {
        final (start, end) = service.getDuhaWindow(schedule);
        final startMinutes = start.hour * 60 + start.minute;
        final endMinutes = end.hour * 60 + end.minute;
        if (endMinutes - startMinutes < 2) return;
        
        expect(service.isValidTimeForDuha(start, schedule), isTrue);
        
        final middleMinutes = (startMinutes + endMinutes) ~/ 2;
        final middleTime = DateTime(schedule.date.year, schedule.date.month, schedule.date.day, middleMinutes ~/ 60, middleMinutes % 60);
        expect(service.isValidTimeForDuha(middleTime, schedule), isTrue);
        
        expect(service.isValidTimeForDuha(end, schedule), isFalse);
      },
    );

    Glados(any.variablePrayerSchedule).test(
      'Property 2: Duha Time Validation - times outside window are invalid',
      (schedule) {
        final (start, end) = service.getDuhaWindow(schedule);
        
        final beforeStart = start.subtract(const Duration(minutes: 30));
        expect(service.isValidTimeForDuha(beforeStart, schedule), isFalse);
        
        final afterEnd = end.add(const Duration(minutes: 30));
        expect(service.isValidTimeForDuha(afterEnd, schedule), isFalse);
      },
    );

    /// **Feature: nafila-prayer-system, Property 3: Shaf'i/Witr Time Validation**
    /// **Validates: Requirements 1.5**
    Glados(any.variablePrayerSchedule).test(
      'Property 3: Shafi/Witr Time Validation - times in window are valid',
      (schedule) {
        final nextDay = schedule.date.add(const Duration(days: 1));
        final nextDaySchedule = PrayerSchedule(
          date: nextDay,
          latitude: schedule.latitude,
          longitude: schedule.longitude,
          method: schedule.method,
          fajrTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.fajrTime.hour, schedule.fajrTime.minute),
          sunrise: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.sunrise.hour, schedule.sunrise.minute),
          dhuhrTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.dhuhrTime.hour, schedule.dhuhrTime.minute),
          asrTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.asrTime.hour, schedule.asrTime.minute),
          maghribTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.maghribTime.hour, schedule.maghribTime.minute),
          ishaTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.ishaTime.hour, schedule.ishaTime.minute),
          createdAt: DateTime.now(),
        );
        
        expect(service.isValidTimeForShafiWitr(schedule.ishaTime, schedule, nextDaySchedule), isTrue);
        
        final midnight = DateTime(nextDay.year, nextDay.month, nextDay.day, 0, 0);
        expect(service.isValidTimeForShafiWitr(midnight, schedule, nextDaySchedule), isTrue);
        
        final beforeNextFajr = nextDaySchedule.fajrTime.subtract(const Duration(minutes: 1));
        expect(service.isValidTimeForShafiWitr(beforeNextFajr, schedule, nextDaySchedule), isTrue);
        
        expect(service.isValidTimeForShafiWitr(nextDaySchedule.fajrTime, schedule, nextDaySchedule), isFalse);
      },
    );

    Glados(any.variablePrayerSchedule).test(
      'Property 3: Shafi/Witr Time Validation - times outside window are invalid',
      (schedule) {
        final nextDay = schedule.date.add(const Duration(days: 1));
        final nextDaySchedule = PrayerSchedule(
          date: nextDay,
          latitude: schedule.latitude,
          longitude: schedule.longitude,
          method: schedule.method,
          fajrTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.fajrTime.hour, schedule.fajrTime.minute),
          sunrise: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.sunrise.hour, schedule.sunrise.minute),
          dhuhrTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.dhuhrTime.hour, schedule.dhuhrTime.minute),
          asrTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.asrTime.hour, schedule.asrTime.minute),
          maghribTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.maghribTime.hour, schedule.maghribTime.minute),
          ishaTime: DateTime(nextDay.year, nextDay.month, nextDay.day, schedule.ishaTime.hour, schedule.ishaTime.minute),
          createdAt: DateTime.now(),
        );
        
        final beforeIsha = schedule.ishaTime.subtract(const Duration(minutes: 30));
        expect(service.isValidTimeForShafiWitr(beforeIsha, schedule, nextDaySchedule), isFalse);
        
        final afterNextFajr = nextDaySchedule.fajrTime.add(const Duration(minutes: 30));
        expect(service.isValidTimeForShafiWitr(afterNextFajr, schedule, nextDaySchedule), isFalse);
      },
    );
  });

  group('NafilaTimeService Unit Tests', () {
    test('getSunnahFajrWindow returns correct window', () {
      final schedule = _createTestSchedule();
      final (start, end) = service.getSunnahFajrWindow(schedule);
      expect(start, equals(schedule.fajrTime));
      expect(end, equals(schedule.sunrise));
    });

    test('getDuhaWindow returns correct window with offsets', () {
      final schedule = _createTestSchedule();
      final (start, end) = service.getDuhaWindow(schedule);
      expect(start, equals(schedule.sunrise.add(const Duration(minutes: 15))));
      expect(end, equals(schedule.dhuhrTime.subtract(const Duration(minutes: 15))));
    });

    test('getShafiWitrWindow returns correct window with next day schedule', () {
      final schedule = _createTestSchedule();
      final nextDaySchedule = _createTestSchedule(daysOffset: 1);
      final (start, end) = service.getShafiWitrWindow(schedule, nextDaySchedule);
      expect(start, equals(schedule.ishaTime));
      expect(end, equals(nextDaySchedule.fajrTime));
    });

    test('getShafiWitrWindow uses default end when no next day schedule', () {
      final schedule = _createTestSchedule();
      final (start, end) = service.getShafiWitrWindow(schedule, null);
      expect(start, equals(schedule.ishaTime));
      final nextDay = schedule.date.add(const Duration(days: 1));
      expect(end, equals(DateTime(nextDay.year, nextDay.month, nextDay.day, 6, 0)));
    });

    test('getNafilaTypeForTime returns correct type for each window', () {
      final schedule = _createTestSchedule();
      final nextDaySchedule = _createTestSchedule(daysOffset: 1);
      
      final sunnahFajrTime = schedule.fajrTime.add(const Duration(minutes: 10));
      expect(service.getNafilaTypeForTime(sunnahFajrTime, schedule, nextDaySchedule: nextDaySchedule), equals(NafilaType.sunnahFajr));
      
      final duhaTime = schedule.sunrise.add(const Duration(hours: 2));
      expect(service.getNafilaTypeForTime(duhaTime, schedule, nextDaySchedule: nextDaySchedule), equals(NafilaType.duha));
      
      final shafiWitrTime = schedule.ishaTime.add(const Duration(hours: 1));
      expect(service.getNafilaTypeForTime(shafiWitrTime, schedule, nextDaySchedule: nextDaySchedule), equals(NafilaType.shafiWitr));
      
      final afternoonTime = DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 14, 0);
      expect(service.getNafilaTypeForTime(afternoonTime, schedule, nextDaySchedule: nextDaySchedule), isNull);
    });

    test('isValidTimeForSunnahFajr handles edge cases', () {
      final schedule = _createTestSchedule();
      expect(service.isValidTimeForSunnahFajr(schedule.fajrTime, schedule), isTrue);
      expect(service.isValidTimeForSunnahFajr(schedule.sunrise, schedule), isFalse);
      final beforeSunrise = schedule.sunrise.subtract(const Duration(minutes: 1));
      expect(service.isValidTimeForSunnahFajr(beforeSunrise, schedule), isTrue);
    });

    test('isValidTimeForDuha handles edge cases', () {
      final schedule = _createTestSchedule();
      final (start, end) = service.getDuhaWindow(schedule);
      expect(service.isValidTimeForDuha(start, schedule), isTrue);
      expect(service.isValidTimeForDuha(end, schedule), isFalse);
      final beforeEnd = end.subtract(const Duration(minutes: 1));
      expect(service.isValidTimeForDuha(beforeEnd, schedule), isTrue);
    });
  });
}

PrayerSchedule _createTestSchedule({int daysOffset = 0}) {
  final baseDate = DateTime(2024, 6, 15).add(Duration(days: daysOffset));
  return PrayerSchedule(
    date: baseDate,
    latitude: 21.4225,
    longitude: 39.8262,
    method: CalculationMethod.ummAlQura,
    fajrTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 4, 30),
    sunrise: DateTime(baseDate.year, baseDate.month, baseDate.day, 6, 0),
    dhuhrTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 12, 30),
    asrTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 15, 45),
    maghribTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 18, 45),
    ishaTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 20, 15),
    createdAt: DateTime.now(),
  );
}
