import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/prayer_event.dart';
import 'package:numu/features/islamic/providers/prayer_provider.dart';
import 'package:numu/features/islamic/services/prayer_status_service.dart';

/// Custom generators for completion count tests
extension CompletionCountGenerators on Any {
  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) =>
          intInRange(1, 28).map((day) => DateTime(year, month, day))));

  /// Generator for a prayer event for a specific prayer type and date
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

  /// Generator for a subset of prayer types (0 to 5 types)
  Generator<List<PrayerType>> get prayerTypeSubset {
    return choose([
      <PrayerType>[],
      [PrayerType.fajr],
      [PrayerType.dhuhr],
      [PrayerType.asr],
      [PrayerType.maghrib],
      [PrayerType.isha],
      [PrayerType.fajr, PrayerType.dhuhr],
      [PrayerType.fajr, PrayerType.asr],
      [PrayerType.dhuhr, PrayerType.maghrib],
      [PrayerType.fajr, PrayerType.dhuhr, PrayerType.asr],
      [PrayerType.fajr, PrayerType.dhuhr, PrayerType.asr, PrayerType.maghrib],
      PrayerType.values.toList(),
    ]);
  }

  /// Generator for a list of prayer events for specific prayer types
  Generator<List<PrayerEvent>> prayerEventsForTypes(List<PrayerType> types, DateTime date) {
    if (types.isEmpty) {
      return always(<PrayerEvent>[]);
    }
    if (types.length == 1) {
      return prayerEventFor(types.first, date).map((e) => [e]);
    }
    return prayerEventFor(types.first, date).bind((first) =>
        prayerEventsForTypes(types.skip(1).toList(), date)
            .map((rest) => [first, ...rest]));
  }
}

void main() {
  group('Prayer Completion Count Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 13: Completion Count Accuracy**
    /// **Validates: Requirements 6.5**
    ///
    /// *For any* list of prayer events for a given day, the completion count SHALL
    /// equal the number of distinct prayer types that have at least one completed event.
    Glados2(any.prayerTypeSubset, any.dateOnly).test(
      'Property 13: Completion Count Accuracy - count equals distinct completed prayer types',
      (completedTypes, date) {
        // Generate events for the selected prayer types
        final events = <PrayerEvent>[];
        final now = DateTime.now();
        
        for (final type in completedTypes) {
          events.add(PrayerEvent(
            prayerType: type,
            eventDate: date,
            eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
            prayedInJamaah: false,
            withinTimeWindow: true,
            createdAt: now,
            updatedAt: now,
          ));
        }

        // Calculate completion count using the service
        final count = PrayerStatusService.countCompletedPrayers(events);

        // The count should equal the number of distinct prayer types
        expect(count, equals(completedTypes.toSet().length),
            reason: 'Completion count should equal number of distinct completed prayer types');
      },
    );

    /// Property: Duplicate events for same prayer type count as one
    Glados2(any.prayerType, any.dateOnly).test(
      'Property 13: Completion Count Accuracy - duplicate events for same type count as one',
      (prayerType, date) {
        final now = DateTime.now();
        
        // Create multiple events for the same prayer type
        final events = [
          PrayerEvent(
            prayerType: prayerType,
            eventDate: date,
            eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
            prayedInJamaah: false,
            withinTimeWindow: true,
            createdAt: now,
            updatedAt: now,
          ),
          PrayerEvent(
            prayerType: prayerType,
            eventDate: date,
            eventTimestamp: DateTime(date.year, date.month, date.day, 12, 30),
            prayedInJamaah: true,
            withinTimeWindow: true,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final count = PrayerStatusService.countCompletedPrayers(events);

        // Should count as 1, not 2
        expect(count, equals(1),
            reason: 'Multiple events for same prayer type should count as one');
      },
    );

    /// Property: Empty event list returns zero count
    test('Property 13: Completion Count Accuracy - empty list returns zero', () {
      final count = PrayerStatusService.countCompletedPrayers([]);
      expect(count, equals(0),
          reason: 'Empty event list should return zero count');
    });

    /// Property: All five prayers completed returns count of 5
    Glados(any.dateOnly).test(
      'Property 13: Completion Count Accuracy - all five prayers returns count of 5',
      (date) {
        final now = DateTime.now();
        
        // Create events for all five prayer types
        final events = PrayerType.values.map((type) => PrayerEvent(
          prayerType: type,
          eventDate: date,
          eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        )).toList();

        final count = PrayerStatusService.countCompletedPrayers(events);

        expect(count, equals(5),
            reason: 'All five prayers completed should return count of 5');
      },
    );

    /// Property: Count is bounded between 0 and 5
    Glados2(any.prayerTypeSubset, any.dateOnly).test(
      'Property 13: Completion Count Accuracy - count is bounded between 0 and 5',
      (completedTypes, date) {
        final now = DateTime.now();
        
        final events = completedTypes.map((type) => PrayerEvent(
          prayerType: type,
          eventDate: date,
          eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        )).toList();

        final count = PrayerStatusService.countCompletedPrayers(events);

        expect(count, greaterThanOrEqualTo(0),
            reason: 'Count should be at least 0');
        expect(count, lessThanOrEqualTo(5),
            reason: 'Count should be at most 5');
      },
    );

    /// Property: countCompletedPrayers function matches PrayerStatusService
    Glados2(any.prayerTypeSubset, any.dateOnly).test(
      'Property 13: countCompletedPrayers utility matches PrayerStatusService',
      (completedTypes, date) {
        final now = DateTime.now();
        
        final events = completedTypes.map((type) => PrayerEvent(
          prayerType: type,
          eventDate: date,
          eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        )).toList();

        // Test both the utility function and the service method
        final utilityCount = countCompletedPrayers(events);
        final serviceCount = PrayerStatusService.countCompletedPrayers(events);

        expect(utilityCount, equals(serviceCount),
            reason: 'Utility function should match service method');
      },
    );
  });

  group('Prayer Completion Count Unit Tests', () {
    test('countCompletedPrayers with single prayer returns 1', () {
      final now = DateTime.now();
      final events = [
        PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 5, 30),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(countCompletedPrayers(events), equals(1));
    });

    test('countCompletedPrayers with three prayers returns 3', () {
      final now = DateTime.now();
      final events = [
        PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 5, 30),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        ),
        PrayerEvent(
          prayerType: PrayerType.dhuhr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 12, 15),
          prayedInJamaah: true,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        ),
        PrayerEvent(
          prayerType: PrayerType.asr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 15, 30),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(countCompletedPrayers(events), equals(3));
    });

    test('countCompletedPrayers ignores Jamaah and withinTimeWindow flags', () {
      final now = DateTime.now();
      final events = [
        PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 5, 30),
          prayedInJamaah: true,
          withinTimeWindow: false, // Outside window
          createdAt: now,
          updatedAt: now,
        ),
        PrayerEvent(
          prayerType: PrayerType.dhuhr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 12, 15),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Both should count regardless of flags
      expect(countCompletedPrayers(events), equals(2));
    });
  });
}
