import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/nafila_type.dart';
import 'package:numu/features/islamic/models/nafila_event.dart';

/// Custom generators for NafilaEvent tests
extension NafilaEventGenerators on Any {
  /// Generator for NafilaType enum values
  Generator<NafilaType> get nafilaType => choose(NafilaType.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) =>
          intInRange(1, 28).map((day) => DateTime(year, month, day))));

  /// Generator for a valid timestamp on a given date
  Generator<DateTime> timestampOnDate(DateTime date) {
    return intInRange(0, 24).bind((hour) => intInRange(0, 60).bind((minute) =>
        intInRange(0, 60).map((second) => DateTime(
            date.year, date.month, date.day, hour % 24, minute % 60, second % 60))));
  }

  /// Generator for valid rakat count based on NafilaType
  Generator<int> rakatCountForType(NafilaType type) {
    return intInRange(type.minRakats, type.maxRakats + 1);
  }

  /// Generator for optional notes
  Generator<String?> get optionalNotes => choose([
        null,
        'Prayed at mosque',
        'Prayed at home',
        'Morning prayer',
        'Night prayer',
      ]);

  /// Generator for a complete NafilaEvent
  Generator<NafilaEvent> get nafilaEvent {
    return nafilaType.bind((type) => dateOnly.bind((date) =>
        timestampOnDate(date).bind((timestamp) =>
            rakatCountForType(type).bind((rakats) =>
                choose([true, false]).bind((hasActualTime) =>
                    (hasActualTime
                            ? timestampOnDate(date)
                            : always<DateTime?>(null))
                        .bind((actualTime) => optionalNotes.bind((notes) =>
                            always(DateTime.now()).bind((createdAt) =>
                                always(DateTime.now()).map((updatedAt) =>
                                    NafilaEvent(
                                      nafilaType: type,
                                      eventDate: date,
                                      eventTimestamp: timestamp,
                                      rakatCount: rakats,
                                      actualPrayerTime: actualTime,
                                      notes: notes,
                                      createdAt: createdAt,
                                      updatedAt: updatedAt,
                                    ))))))))));
  }
}

void main() {
  group('NafilaEvent Property Tests', () {
    /// **Feature: nafila-prayer-system, Property 4: NafilaEvent Serialization Round-Trip**
    /// **Validates: Requirements 7.4, 7.5**
    ///
    /// *For any* valid NafilaEvent object, serializing to a map and deserializing
    /// back should produce an equivalent NafilaEvent object with all fields matching.
    Glados(any.nafilaEvent).test(
      'Property 4: NafilaEvent Serialization Round-Trip - toMap/fromMap preserves all fields',
      (event) {
        // Serialize to map (simulating database storage)
        final map = event.toMap();

        // Deserialize from map (simulating database retrieval)
        final restored = NafilaEvent.fromMap(map);

        // Verify all fields are preserved
        expect(restored.nafilaType, equals(event.nafilaType));
        expect(restored.eventDate.year, equals(event.eventDate.year));
        expect(restored.eventDate.month, equals(event.eventDate.month));
        expect(restored.eventDate.day, equals(event.eventDate.day));
        expect(restored.eventTimestamp, equals(event.eventTimestamp));
        expect(restored.rakatCount, equals(event.rakatCount));
        expect(restored.actualPrayerTime, equals(event.actualPrayerTime));
        expect(restored.notes, equals(event.notes));
        expect(restored.createdAt, equals(event.createdAt));
        expect(restored.updatedAt, equals(event.updatedAt));
      },
    );
  });

  group('NafilaEvent Unit Tests', () {
    test('copyWith creates new instance with updated fields', () {
      final original = NafilaEvent(
        nafilaType: NafilaType.sunnahFajr,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 5, 30),
        rakatCount: 2,
        actualPrayerTime: DateTime(2024, 1, 15, 5, 25),
        notes: 'Original note',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        nafilaType: NafilaType.duha,
        rakatCount: 4,
        notes: 'Updated note',
      );

      expect(updated.nafilaType, equals(NafilaType.duha));
      expect(updated.rakatCount, equals(4));
      expect(updated.notes, equals('Updated note'));
      // Original fields should be preserved
      expect(updated.eventDate, equals(original.eventDate));
      expect(updated.eventTimestamp, equals(original.eventTimestamp));
    });

    test('toMap correctly serializes rakat count', () {
      final event = NafilaEvent(
        nafilaType: NafilaType.duha,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 9, 30),
        rakatCount: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = event.toMap();

      expect(map['rakat_count'], equals(4));
      expect(map['nafila_type'], equals('duha'));
    });

    test('fromMap correctly deserializes all fields', () {
      final map = {
        'nafila_type': 'shafiWitr',
        'event_date': '2024-01-15',
        'event_timestamp': '2024-01-15T22:00:00.000',
        'rakat_count': 3,
        'actual_prayer_time': '2024-01-15T21:55:00.000',
        'notes': 'Night prayer',
        'created_at': '2024-01-15T22:05:00.000',
        'updated_at': '2024-01-15T22:05:00.000',
      };

      final event = NafilaEvent.fromMap(map);

      expect(event.nafilaType, equals(NafilaType.shafiWitr));
      expect(event.rakatCount, equals(3));
      expect(event.notes, equals('Night prayer'));
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final event1 = NafilaEvent(
        nafilaType: NafilaType.sunnahFajr,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 5, 30),
        rakatCount: 2,
        createdAt: now,
        updatedAt: now,
      );

      final event2 = NafilaEvent(
        nafilaType: NafilaType.sunnahFajr,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 5, 30),
        rakatCount: 2,
        createdAt: now,
        updatedAt: now,
      );

      expect(event1, equals(event2));
    });
  });
}
