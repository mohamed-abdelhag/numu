import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/prayer_status.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/prayer_event.dart';
import 'package:numu/features/islamic/models/prayer_schedule.dart';
import 'package:numu/features/islamic/services/prayer_status_service.dart';

/// Custom generators for PrayerStatusService tests
extension PrayerStatusGenerators on Any {
  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for valid time window minutes (positive integer, reasonable range)
  Generator<int> get timeWindowMinutes => intInRange(1, 120);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) =>
          intInRange(1, 28).map((day) => DateTime(year, month, day))));

  /// Generator for a valid prayer time on a given date
  Generator<DateTime> prayerTimeOnDate(
      DateTime date, int minHour, int maxHour) {
    final effectiveMaxHour = maxHour > minHour ? maxHour : minHour + 1;
    return intInRange(minHour, effectiveMaxHour).bind((hour) =>
        intInRange(0, 60)
            .map((minute) => DateTime(date.year, date.month, date.day, hour, minute % 60)));
  }

  /// Generator for a complete PrayerSchedule with valid prayer time ordering
  Generator<PrayerSchedule> get prayerSchedule {
    return dateOnly.bind((date) =>
        doubleInRange(-90.0, 90.0).bind((lat) =>
            doubleInRange(-180.0, 180.0).bind((lng) =>
                choose(CalculationMethod.values).bind((method) =>
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

  /// Generator for a prayer event for a specific prayer type and date
  Generator<PrayerEvent> prayerEventFor(PrayerType type, DateTime date) {
    return prayerTimeOnDate(date, 0, 24).bind((timestamp) =>
        choose([true, false]).bind((jamaah) =>
            choose([true, false]).bind((withinWindow) =>
                always(DateTime.now()).map((now) => PrayerEvent(
                      prayerType: type,
                      eventDate: date,
                      eventTimestamp: timestamp,
                      prayedInJamaah: jamaah,
                      withinTimeWindow: withinWindow,
                      createdAt: now,
                      updatedAt: now,
                    )))));
  }

  /// Generator for a list of prayer events (0 to 5 events, one per prayer type max)
  Generator<List<PrayerEvent>> prayerEventsForDate(DateTime date) {
    // Generate a subset of prayer types that have events
    return choose([
      <PrayerType>[],
      [PrayerType.fajr],
      [PrayerType.dhuhr],
      [PrayerType.fajr, PrayerType.dhuhr],
      [PrayerType.fajr, PrayerType.dhuhr, PrayerType.asr],
      PrayerType.values.toList(),
    ]).bind((types) {
      if (types.isEmpty) {
        return always(<PrayerEvent>[]);
      }
      return _generateEventsForTypes(types, date);
    });
  }

  Generator<List<PrayerEvent>> _generateEventsForTypes(
      List<PrayerType> types, DateTime date) {
    if (types.isEmpty) {
      return always(<PrayerEvent>[]);
    }
    if (types.length == 1) {
      return prayerEventFor(types.first, date).map((e) => [e]);
    }
    return prayerEventFor(types.first, date).bind((first) =>
        _generateEventsForTypes(types.skip(1).toList(), date)
            .map((rest) => [first, ...rest]));
  }

  /// Generator for current time relative to a prayer schedule
  /// Generates times that are before, during, or after the time window
  Generator<DateTime> currentTimeRelativeToSchedule(
      PrayerSchedule schedule, PrayerType type, int windowMinutes) {
    final prayerTime = schedule.getTimeForPrayer(type);
    final windowEnd = schedule.getTimeWindowEnd(type, windowMinutes);
    final date = schedule.date;

    return choose([
      // Before prayer time (pending - waiting)
      DateTime(date.year, date.month, date.day, 0, 0),
      // At prayer time (pending - within window)
      prayerTime,
      // During window (pending - within window)
      prayerTime.add(Duration(minutes: windowMinutes ~/ 2)),
      // At window end (pending - at boundary)
      windowEnd,
      // After window (missed)
      windowEnd.add(const Duration(minutes: 1)),
      // Well after window (missed)
      windowEnd.add(const Duration(hours: 2)),
    ]);
  }
}

void main() {
  group('PrayerStatusService Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 4: Prayer Status Calculation**
    /// **Validates: Requirements 2.4, 2.5**
    ///
    /// *For any* prayer time, time window duration, current time, and list of
    /// prayer events for that day, the calculated prayer status SHALL be exactly
    /// one of: pending (prayer time has arrived, window not expired, not logged),
    /// completed (prayer logged), or missed (window expired, not logged).
    Glados3(any.prayerSchedule, any.prayerType, any.timeWindowMinutes).test(
      'Property 4: Prayer Status Calculation - status is exactly one of pending, completed, or missed',
      (schedule, prayerType, windowMinutes) {
        // Test with no events (should be pending or missed depending on time)
        final noEvents = <PrayerEvent>[];
        final prayerTime = schedule.getTimeForPrayer(prayerType);
        final windowEnd = schedule.getTimeWindowEnd(prayerType, windowMinutes);

        // Test case 1: Current time before window end -> pending
        final beforeWindowEnd = windowEnd.subtract(const Duration(minutes: 1));
        final statusBeforeEnd = PrayerStatusService.calculateStatus(
          prayerType: prayerType,
          schedule: schedule,
          events: noEvents,
          currentTime: beforeWindowEnd,
          timeWindowMinutes: windowMinutes,
        );
        expect(statusBeforeEnd, equals(PrayerStatus.pending),
            reason: 'Should be pending when current time is before window end');

        // Test case 2: Current time after window end -> missed
        final afterWindowEnd = windowEnd.add(const Duration(minutes: 1));
        final statusAfterEnd = PrayerStatusService.calculateStatus(
          prayerType: prayerType,
          schedule: schedule,
          events: noEvents,
          currentTime: afterWindowEnd,
          timeWindowMinutes: windowMinutes,
        );
        expect(statusAfterEnd, equals(PrayerStatus.missed),
            reason: 'Should be missed when current time is after window end');

        // Test case 3: With completed event -> completed regardless of time
        final completedEvent = PrayerEvent(
          prayerType: prayerType,
          eventDate: schedule.date,
          eventTimestamp: prayerTime,
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final statusWithEvent = PrayerStatusService.calculateStatus(
          prayerType: prayerType,
          schedule: schedule,
          events: [completedEvent],
          currentTime: afterWindowEnd,
          timeWindowMinutes: windowMinutes,
        );
        expect(statusWithEvent, equals(PrayerStatus.completed),
            reason: 'Should be completed when event exists');

        // Verify status is always one of the three valid values
        expect(
          [statusBeforeEnd, statusAfterEnd, statusWithEvent],
          everyElement(isIn([
            PrayerStatus.pending,
            PrayerStatus.completed,
            PrayerStatus.missed,
          ])),
        );
      },
    );

    /// Additional property: Status is mutually exclusive
    /// For any given prayer, the status can only be one value at a time
    Glados2(any.prayerSchedule, any.prayerType).test(
      'Prayer status is mutually exclusive - exactly one status at any time',
      (schedule, prayerType) {
        final now = DateTime.now();
        final events = <PrayerEvent>[];

        final status = PrayerStatusService.calculateStatus(
          prayerType: prayerType,
          schedule: schedule,
          events: events,
          currentTime: now,
        );

        // Status must be exactly one of the three values
        final isPending = status == PrayerStatus.pending;
        final isCompleted = status == PrayerStatus.completed;
        final isMissed = status == PrayerStatus.missed;

        // Exactly one must be true
        final trueCount = [isPending, isCompleted, isMissed]
            .where((b) => b)
            .length;
        expect(trueCount, equals(1),
            reason: 'Exactly one status should be true');
      },
    );

    /// Property: Completed status takes precedence
    /// If a prayer event exists, status is always completed regardless of time
    Glados2(any.prayerSchedule, any.prayerType).test(
      'Completed status takes precedence over time-based status',
      (schedule, prayerType) {
        final event = PrayerEvent(
          prayerType: prayerType,
          eventDate: schedule.date,
          eventTimestamp: schedule.getTimeForPrayer(prayerType),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Test at various times - should always be completed
        final times = [
          schedule.getTimeForPrayer(prayerType)
              .subtract(const Duration(hours: 1)),
          schedule.getTimeForPrayer(prayerType),
          schedule.getTimeWindowEnd(prayerType, 30),
          schedule.getTimeWindowEnd(prayerType, 30)
              .add(const Duration(hours: 5)),
        ];

        for (final time in times) {
          final status = PrayerStatusService.calculateStatus(
            prayerType: prayerType,
            schedule: schedule,
            events: [event],
            currentTime: time,
          );
          expect(status, equals(PrayerStatus.completed),
              reason: 'Should be completed at time $time when event exists');
        }
      },
    );
  });

  group('PrayerStatusService Future Time Validation Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 5: Future Time Validation**
    /// **Validates: Requirements 2.6**
    ///
    /// *For any* prayer event with an actual prayer time in the future relative
    /// to the current timestamp, the validation function SHALL reject the event
    /// and return an error.
    Glados(any.intInRange(1, 1000)).test(
      'Property 5: Future Time Validation - future times are rejected',
      (minutesInFuture) {
        final currentTime = DateTime.now();
        final futureTime = currentTime.add(Duration(minutes: minutesInFuture));

        final result = PrayerStatusService.validatePrayerTime(
          actualPrayerTime: futureTime,
          currentTime: currentTime,
        );

        expect(result.isValid, isFalse,
            reason: 'Future time should be rejected');
        expect(result.errorMessage, isNotNull,
            reason: 'Error message should be provided');
        expect(result.errorMessage, contains('future'),
            reason: 'Error message should mention future time');
      },
    );

    /// Property: Past times are accepted
    /// For any prayer time in the past, validation should succeed
    Glados(any.intInRange(1, 10000)).test(
      'Past times are accepted by validation',
      (minutesInPast) {
        final currentTime = DateTime.now();
        final pastTime = currentTime.subtract(Duration(minutes: minutesInPast));

        final result = PrayerStatusService.validatePrayerTime(
          actualPrayerTime: pastTime,
          currentTime: currentTime,
        );

        expect(result.isValid, isTrue,
            reason: 'Past time should be accepted');
        expect(result.errorMessage, isNull,
            reason: 'No error message for valid time');
      },
    );

    /// Property: Current time (exact match) is accepted
    test('Current time (exact match) is accepted', () {
      final currentTime = DateTime.now();

      final result = PrayerStatusService.validatePrayerTime(
        actualPrayerTime: currentTime,
        currentTime: currentTime,
      );

      expect(result.isValid, isTrue,
          reason: 'Current time should be accepted');
    });
  });

  group('PrayerStatusService Unit Tests', () {
    late PrayerSchedule testSchedule;

    setUp(() {
      final date = DateTime(2024, 1, 15);
      testSchedule = PrayerSchedule(
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
    });

    test('calculateStatus returns pending when before window end', () {
      final status = PrayerStatusService.calculateStatus(
        prayerType: PrayerType.fajr,
        schedule: testSchedule,
        events: [],
        currentTime: DateTime(2024, 1, 15, 5, 45), // 15 min after fajr
      );
      expect(status, equals(PrayerStatus.pending));
    });

    test('calculateStatus returns missed when after window end', () {
      final status = PrayerStatusService.calculateStatus(
        prayerType: PrayerType.fajr,
        schedule: testSchedule,
        events: [],
        currentTime: DateTime(2024, 1, 15, 6, 15), // 45 min after fajr
      );
      expect(status, equals(PrayerStatus.missed));
    });

    test('calculateStatus returns completed when event exists', () {
      final event = PrayerEvent(
        prayerType: PrayerType.fajr,
        eventDate: testSchedule.date,
        eventTimestamp: DateTime(2024, 1, 15, 5, 35),
        prayedInJamaah: true,
        withinTimeWindow: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = PrayerStatusService.calculateStatus(
        prayerType: PrayerType.fajr,
        schedule: testSchedule,
        events: [event],
        currentTime: DateTime(2024, 1, 15, 12, 0),
      );
      expect(status, equals(PrayerStatus.completed));
    });

    test('calculateAllStatuses returns status for all five prayers', () {
      final statuses = PrayerStatusService.calculateAllStatuses(
        schedule: testSchedule,
        events: [],
        currentTime: DateTime(2024, 1, 15, 13, 0), // After dhuhr window
      );

      expect(statuses.length, equals(5));
      expect(statuses[PrayerType.fajr], equals(PrayerStatus.missed));
      expect(statuses[PrayerType.dhuhr], equals(PrayerStatus.missed));
      expect(statuses[PrayerType.asr], equals(PrayerStatus.pending));
      expect(statuses[PrayerType.maghrib], equals(PrayerStatus.pending));
      expect(statuses[PrayerType.isha], equals(PrayerStatus.pending));
    });

    test('isWithinTimeWindow returns true when within window', () {
      final result = PrayerStatusService.isWithinTimeWindow(
        actualPrayerTime: DateTime(2024, 1, 15, 5, 45),
        scheduledPrayerTime: DateTime(2024, 1, 15, 5, 30),
        timeWindowMinutes: 30,
      );
      expect(result, isTrue);
    });

    test('isWithinTimeWindow returns false when outside window', () {
      final result = PrayerStatusService.isWithinTimeWindow(
        actualPrayerTime: DateTime(2024, 1, 15, 6, 15),
        scheduledPrayerTime: DateTime(2024, 1, 15, 5, 30),
        timeWindowMinutes: 30,
      );
      expect(result, isFalse);
    });

    test('getNextPendingPrayer returns correct next prayer', () {
      final nextPrayer = PrayerStatusService.getNextPendingPrayer(
        schedule: testSchedule,
        events: [],
        currentTime: DateTime(2024, 1, 15, 13, 0),
      );
      expect(nextPrayer, equals(PrayerType.asr));
    });

    test('getNextPendingPrayer returns null when all prayers done', () {
      final events = PrayerType.values.map((type) => PrayerEvent(
            prayerType: type,
            eventDate: testSchedule.date,
            eventTimestamp: testSchedule.getTimeForPrayer(type),
            prayedInJamaah: false,
            withinTimeWindow: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )).toList();

      final nextPrayer = PrayerStatusService.getNextPendingPrayer(
        schedule: testSchedule,
        events: events,
        currentTime: DateTime(2024, 1, 15, 20, 0),
      );
      expect(nextPrayer, isNull);
    });

    test('countCompletedPrayers returns correct count', () {
      final events = [
        PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: testSchedule.date,
          eventTimestamp: DateTime(2024, 1, 15, 5, 35),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PrayerEvent(
          prayerType: PrayerType.dhuhr,
          eventDate: testSchedule.date,
          eventTimestamp: DateTime(2024, 1, 15, 12, 20),
          prayedInJamaah: true,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final count = PrayerStatusService.countCompletedPrayers(events);
      expect(count, equals(2));
    });
  });

  group('Next Prayer Identification Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 12: Next Prayer Identification**
    /// **Validates: Requirements 6.3, 7.2**
    ///
    /// *For any* prayer schedule and current time, the next pending prayer SHALL be
    /// the prayer with the earliest start time that is after the current time and
    /// has not been completed.
    Glados2(any.prayerSchedule, any.timeWindowMinutes).test(
      'Property 12: Next Prayer Identification - returns earliest pending prayer',
      (schedule, windowMinutes) {
        // Test at various times throughout the day
        final testTimes = [
          // Before any prayer
          DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 0, 0),
          // After Fajr, before Dhuhr
          DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 10, 0),
          // After Dhuhr, before Asr
          DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 14, 0),
          // After Asr, before Maghrib
          DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 17, 0),
          // After Maghrib, before Isha
          DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 18, 30),
          // After all prayers
          DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 23, 0),
        ];

        for (final currentTime in testTimes) {
          final nextPrayer = PrayerStatusService.getNextPendingPrayer(
            schedule: schedule,
            events: [], // No completed prayers
            currentTime: currentTime,
            timeWindowMinutes: windowMinutes,
          );

          if (nextPrayer != null) {
            // Verify the next prayer is pending (not missed)
            final status = PrayerStatusService.calculateStatus(
              prayerType: nextPrayer,
              schedule: schedule,
              events: [],
              currentTime: currentTime,
              timeWindowMinutes: windowMinutes,
            );
            expect(status, equals(PrayerStatus.pending),
                reason: 'Next prayer should be pending at time $currentTime');

            // Verify no earlier prayer is pending
            for (final type in PrayerType.values) {
              if (type == nextPrayer) continue;
              
              final otherTime = schedule.getTimeForPrayer(type);
              final nextTime = schedule.getTimeForPrayer(nextPrayer);
              
              if (otherTime.isBefore(nextTime)) {
                final otherStatus = PrayerStatusService.calculateStatus(
                  prayerType: type,
                  schedule: schedule,
                  events: [],
                  currentTime: currentTime,
                  timeWindowMinutes: windowMinutes,
                );
                expect(otherStatus, isNot(equals(PrayerStatus.pending)),
                    reason: 'Earlier prayer ${type.englishName} should not be pending');
              }
            }
          }
        }
      },
    );

    /// Property: Completed prayers are skipped when finding next prayer
    Glados(any.prayerSchedule).test(
      'Property 12: Next Prayer Identification - skips completed prayers',
      (schedule) {
        // Complete Fajr
        final fajrEvent = PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: schedule.date,
          eventTimestamp: schedule.fajrTime,
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Current time is before Dhuhr window ends
        final currentTime = DateTime(
          schedule.date.year,
          schedule.date.month,
          schedule.date.day,
          schedule.dhuhrTime.hour,
          schedule.dhuhrTime.minute,
        );

        final nextPrayer = PrayerStatusService.getNextPendingPrayer(
          schedule: schedule,
          events: [fajrEvent],
          currentTime: currentTime,
        );

        // Should not return Fajr since it's completed
        expect(nextPrayer, isNot(equals(PrayerType.fajr)),
            reason: 'Should skip completed Fajr prayer');
      },
    );

    /// Property: Returns null when all prayers are completed or missed
    Glados(any.prayerSchedule).test(
      'Property 12: Next Prayer Identification - returns null when no pending prayers',
      (schedule) {
        // Complete all prayers
        final allEvents = PrayerType.values.map((type) => PrayerEvent(
          prayerType: type,
          eventDate: schedule.date,
          eventTimestamp: schedule.getTimeForPrayer(type),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).toList();

        final nextPrayer = PrayerStatusService.getNextPendingPrayer(
          schedule: schedule,
          events: allEvents,
          currentTime: DateTime.now(),
        );

        expect(nextPrayer, isNull,
            reason: 'Should return null when all prayers are completed');
      },
    );
  });
}
