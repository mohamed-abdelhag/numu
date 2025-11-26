import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/prayer_event.dart';

/// Custom generators for PrayerEvent tests
extension PrayerEventGenerators on Any {
  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for a valid timestamp on a given date
  Generator<DateTime> timestampOnDate(DateTime date) {
    return intInRange(0, 24).bind((hour) =>
        intInRange(0, 60).bind((minute) =>
            intInRange(0, 60).map((second) =>
                DateTime(date.year, date.month, date.day, hour % 24, minute % 60, second % 60))));
  }

  /// Generator for optional notes
  Generator<String?> get optionalNotes => choose([
        null,
        'Prayed at mosque',
        'Prayed at home',
        'Late prayer',
        'Early prayer',
      ]);

  /// Generator for a complete PrayerEvent
  Generator<PrayerEvent> get prayerEvent {
    return prayerType.bind((type) =>
        dateOnly.bind((date) =>
            timestampOnDate(date).bind((timestamp) =>
                choose([true, false]).bind((hasActualTime) =>
                    (hasActualTime ? timestampOnDate(date) : always<DateTime?>(null)).bind((actualTime) =>
                        choose([true, false]).bind((jamaah) =>
                            choose([true, false]).bind((withinWindow) =>
                                optionalNotes.bind((notes) =>
                                    always(DateTime.now()).bind((createdAt) =>
                                        always(DateTime.now()).map((updatedAt) =>
                                            PrayerEvent(
                                              prayerType: type,
                                              eventDate: date,
                                              eventTimestamp: timestamp,
                                              actualPrayerTime: actualTime,
                                              prayedInJamaah: jamaah,
                                              withinTimeWindow: withinWindow,
                                              notes: notes,
                                              createdAt: createdAt,
                                              updatedAt: updatedAt,
                                            )))))))))));
  }
}

void main() {
  group('PrayerEvent Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 2: Prayer Event Round-Trip Persistence**
    /// **Validates: Requirements 2.1, 2.2, 2.3**
    ///
    /// *For any* valid prayer event with prayer type, event date, timestamp,
    /// actual prayer time, Jamaah flag, and time window flag, storing the event
    /// and then retrieving it SHALL produce an equivalent event with all fields preserved.
    Glados(any.prayerEvent).test(
      'Property 2: Prayer Event Round-Trip Persistence - toMap/fromMap preserves all fields',
      (event) {
        // Serialize to map (simulating database storage)
        final map = event.toMap();

        // Deserialize from map (simulating database retrieval)
        final restored = PrayerEvent.fromMap(map);

        // Verify all fields are preserved
        expect(restored.prayerType, equals(event.prayerType));
        expect(restored.eventDate.year, equals(event.eventDate.year));
        expect(restored.eventDate.month, equals(event.eventDate.month));
        expect(restored.eventDate.day, equals(event.eventDate.day));
        expect(restored.eventTimestamp, equals(event.eventTimestamp));
        expect(restored.actualPrayerTime, equals(event.actualPrayerTime));
        expect(restored.prayedInJamaah, equals(event.prayedInJamaah));
        expect(restored.withinTimeWindow, equals(event.withinTimeWindow));
        expect(restored.notes, equals(event.notes));
        expect(restored.createdAt, equals(event.createdAt));
        expect(restored.updatedAt, equals(event.updatedAt));
      },
    );
  });

  group('PrayerEvent Unit Tests', () {
    test('copyWith creates new instance with updated fields', () {
      final original = PrayerEvent(
        prayerType: PrayerType.fajr,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 5, 45),
        actualPrayerTime: DateTime(2024, 1, 15, 5, 40),
        prayedInJamaah: false,
        withinTimeWindow: true,
        notes: 'Original note',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        prayerType: PrayerType.dhuhr,
        prayedInJamaah: true,
        notes: 'Updated note',
      );

      expect(updated.prayerType, equals(PrayerType.dhuhr));
      expect(updated.prayedInJamaah, isTrue);
      expect(updated.notes, equals('Updated note'));
      // Original fields should be preserved
      expect(updated.eventDate, equals(original.eventDate));
      expect(updated.withinTimeWindow, equals(original.withinTimeWindow));
    });

    test('toMap correctly serializes boolean fields as integers', () {
      final event = PrayerEvent(
        prayerType: PrayerType.asr,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 15, 30),
        prayedInJamaah: true,
        withinTimeWindow: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = event.toMap();

      expect(map['prayed_in_jamaah'], equals(1));
      expect(map['within_time_window'], equals(0));
    });

    test('fromMap correctly deserializes integer fields as booleans', () {
      final map = {
        'prayer_type': 'maghrib',
        'event_date': '2024-01-15',
        'event_timestamp': '2024-01-15T18:00:00.000',
        'prayed_in_jamaah': 1,
        'within_time_window': 0,
        'created_at': '2024-01-15T18:05:00.000',
        'updated_at': '2024-01-15T18:05:00.000',
      };

      final event = PrayerEvent.fromMap(map);

      expect(event.prayedInJamaah, isTrue);
      expect(event.withinTimeWindow, isFalse);
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final event1 = PrayerEvent(
        prayerType: PrayerType.isha,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 19, 30),
        prayedInJamaah: true,
        withinTimeWindow: true,
        createdAt: now,
        updatedAt: now,
      );

      final event2 = PrayerEvent(
        prayerType: PrayerType.isha,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 19, 30),
        prayedInJamaah: true,
        withinTimeWindow: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(event1, equals(event2));
    });
  });
}
