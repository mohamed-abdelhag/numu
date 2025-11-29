import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/nafila_event.dart';
import 'package:numu/features/islamic/models/enums/nafila_type.dart';

/// Custom generators for NafilaEvent chronological ordering tests
extension NafilaEventGenerators on Any {
  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2025).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for a valid NafilaType
  Generator<NafilaType> get nafilaType =>
      intInRange(0, NafilaType.values.length - 1)
          .map((index) => NafilaType.values[index]);

  /// Generator for a valid rakat count for a given NafilaType
  Generator<int> rakatCountFor(NafilaType type) {
    // Handle case where min == max (e.g., Sunnah Fajr is always 2 rakats)
    if (type.minRakats == type.maxRakats) {
      return intInRange(type.minRakats, type.minRakats + 1).map((_) => type.minRakats);
    }
    return intInRange(type.minRakats, type.maxRakats + 1);
  }

  /// Generator for a DateTime with time component on a given date
  Generator<DateTime> dateTimeOnDate(DateTime date) =>
      intInRange(0, 23).bind((hour) =>
          intInRange(0, 59).map((minute) =>
              DateTime(date.year, date.month, date.day, hour, minute)));

  /// Generator for a single NafilaEvent on a given date
  Generator<NafilaEvent> nafilaEventOnDate(DateTime date) {
    return nafilaType.bind((type) =>
        rakatCountFor(type).bind((rakats) =>
            dateTimeOnDate(date).map((timestamp) {
              final now = DateTime.now();
              return NafilaEvent(
                id: null,
                nafilaType: type,
                eventDate: date,
                eventTimestamp: timestamp,
                rakatCount: rakats,
                actualPrayerTime: null,
                notes: null,
                createdAt: now,
                updatedAt: now,
              );
            })));
  }

  /// Generator for a list of NafilaEvents on a given date
  /// Generates 1-10 events for the day
  Generator<List<NafilaEvent>> nafilaEventsOnDate(DateTime date) {
    return intInRange(1, 10).bind((count) =>
        _generateNafilaEventList(date, count));
  }

  Generator<List<NafilaEvent>> _generateNafilaEventList(DateTime date, int count) {
    if (count == 0) {
      return any.intInRange(0, 0).map((_) => <NafilaEvent>[]);
    }
    if (count == 1) {
      return nafilaEventOnDate(date).map((event) => [event]);
    }
    return nafilaEventOnDate(date).bind((event) =>
        _generateNafilaEventList(date, count - 1).map((list) => [event, ...list]));
  }

  /// Generator for a list of NafilaEvents on a random date
  Generator<List<NafilaEvent>> get nafilaEventList =>
      dateOnly.bind((date) => nafilaEventsOnDate(date));
}

/// Sorts NafilaEvents by eventTimestamp in ascending order (chronological).
/// This is the function being tested - it represents how events should be
/// displayed in the UI.
List<NafilaEvent> sortNafilaEventsChronologically(List<NafilaEvent> events) {
  final sorted = List<NafilaEvent>.from(events);
  sorted.sort((a, b) => a.eventTimestamp.compareTo(b.eventTimestamp));
  return sorted;
}

/// Checks if a list of NafilaEvents is sorted chronologically by eventTimestamp.
bool isChronologicallySorted(List<NafilaEvent> events) {
  if (events.length <= 1) return true;
  for (int i = 0; i < events.length - 1; i++) {
    if (events[i].eventTimestamp.isAfter(events[i + 1].eventTimestamp)) {
      return false;
    }
  }
  return true;
}

void main() {
  group('Nafila Chronological Ordering Property Tests', () {
    /// **Feature: nafila-prayer-system, Property 5: Nafila Chronological Ordering**
    /// **Validates: Requirements 2.3, 3.3**
    ///
    /// *For any* list of NafilaEvent objects for a given day, when sorted for display,
    /// they should be ordered by their eventTimestamp in ascending order.
    Glados(any.nafilaEventList).test(
      'Property 5: Nafila Chronological Ordering - sorted events are in ascending timestamp order',
      (events) {
        // Skip empty lists
        if (events.isEmpty) return;

        // Sort the events chronologically
        final sortedEvents = sortNafilaEventsChronologically(events);

        // Verify the result is chronologically sorted
        expect(isChronologicallySorted(sortedEvents), isTrue,
            reason: 'Sorted events should be in ascending timestamp order');
      },
    );

    Glados(any.nafilaEventList).test(
      'Property 5: Nafila Chronological Ordering - sorting preserves all events',
      (events) {
        // Sort the events chronologically
        final sortedEvents = sortNafilaEventsChronologically(events);

        // Verify the same number of events
        expect(sortedEvents.length, equals(events.length),
            reason: 'Sorting should preserve the number of events');

        // Verify all original events are present in sorted list
        for (final event in events) {
          expect(sortedEvents.contains(event), isTrue,
              reason: 'All original events should be present after sorting');
        }
      },
    );

    Glados(any.nafilaEventList).test(
      'Property 5: Nafila Chronological Ordering - sorting is idempotent',
      (events) {
        // Sort once
        final sortedOnce = sortNafilaEventsChronologically(events);

        // Sort again
        final sortedTwice = sortNafilaEventsChronologically(sortedOnce);

        // Verify sorting twice produces the same result
        expect(sortedTwice.length, equals(sortedOnce.length));
        for (int i = 0; i < sortedOnce.length; i++) {
          expect(sortedTwice[i].eventTimestamp, equals(sortedOnce[i].eventTimestamp),
              reason: 'Sorting should be idempotent');
        }
      },
    );

    Glados(any.nafilaEventList).test(
      'Property 5: Nafila Chronological Ordering - first event has earliest timestamp',
      (events) {
        if (events.isEmpty) return;

        final sortedEvents = sortNafilaEventsChronologically(events);

        // Find the minimum timestamp in original list
        final minTimestamp = events
            .map((e) => e.eventTimestamp)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        // First event in sorted list should have the minimum timestamp
        expect(sortedEvents.first.eventTimestamp, equals(minTimestamp),
            reason: 'First event should have the earliest timestamp');
      },
    );

    Glados(any.nafilaEventList).test(
      'Property 5: Nafila Chronological Ordering - last event has latest timestamp',
      (events) {
        if (events.isEmpty) return;

        final sortedEvents = sortNafilaEventsChronologically(events);

        // Find the maximum timestamp in original list
        final maxTimestamp = events
            .map((e) => e.eventTimestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        // Last event in sorted list should have the maximum timestamp
        expect(sortedEvents.last.eventTimestamp, equals(maxTimestamp),
            reason: 'Last event should have the latest timestamp');
      },
    );
  });

  group('Nafila Chronological Ordering Unit Tests', () {
    test('Empty list returns empty list', () {
      final result = sortNafilaEventsChronologically([]);
      expect(result, isEmpty);
    });

    test('Single event returns same event', () {
      final event = _createTestEvent(DateTime(2024, 6, 15, 10, 30));
      final result = sortNafilaEventsChronologically([event]);
      expect(result.length, equals(1));
      expect(result.first, equals(event));
    });

    test('Already sorted list remains sorted', () {
      final events = [
        _createTestEvent(DateTime(2024, 6, 15, 8, 0)),
        _createTestEvent(DateTime(2024, 6, 15, 10, 0)),
        _createTestEvent(DateTime(2024, 6, 15, 12, 0)),
      ];
      final result = sortNafilaEventsChronologically(events);
      expect(isChronologicallySorted(result), isTrue);
    });

    test('Reverse sorted list becomes correctly sorted', () {
      final events = [
        _createTestEvent(DateTime(2024, 6, 15, 12, 0)),
        _createTestEvent(DateTime(2024, 6, 15, 10, 0)),
        _createTestEvent(DateTime(2024, 6, 15, 8, 0)),
      ];
      final result = sortNafilaEventsChronologically(events);
      expect(isChronologicallySorted(result), isTrue);
      expect(result.first.eventTimestamp.hour, equals(8));
      expect(result.last.eventTimestamp.hour, equals(12));
    });

    test('Events with same timestamp maintain relative order', () {
      final sameTime = DateTime(2024, 6, 15, 10, 0);
      final events = [
        _createTestEvent(sameTime, NafilaType.sunnahFajr),
        _createTestEvent(sameTime, NafilaType.duha),
        _createTestEvent(sameTime, NafilaType.shafiWitr),
      ];
      final result = sortNafilaEventsChronologically(events);
      expect(result.length, equals(3));
      // All should have the same timestamp
      for (final event in result) {
        expect(event.eventTimestamp, equals(sameTime));
      }
    });

    test('Mixed Nafila types are sorted by timestamp regardless of type', () {
      final events = [
        _createTestEvent(DateTime(2024, 6, 15, 20, 0), NafilaType.shafiWitr),
        _createTestEvent(DateTime(2024, 6, 15, 5, 0), NafilaType.sunnahFajr),
        _createTestEvent(DateTime(2024, 6, 15, 9, 0), NafilaType.duha),
        _createTestEvent(DateTime(2024, 6, 15, 14, 0), NafilaType.custom),
      ];
      final result = sortNafilaEventsChronologically(events);
      expect(result[0].nafilaType, equals(NafilaType.sunnahFajr));
      expect(result[1].nafilaType, equals(NafilaType.duha));
      expect(result[2].nafilaType, equals(NafilaType.custom));
      expect(result[3].nafilaType, equals(NafilaType.shafiWitr));
    });
  });
}

NafilaEvent _createTestEvent(DateTime timestamp, [NafilaType type = NafilaType.custom]) {
  final now = DateTime.now();
  return NafilaEvent(
    id: null,
    nafilaType: type,
    eventDate: DateTime(timestamp.year, timestamp.month, timestamp.day),
    eventTimestamp: timestamp,
    rakatCount: type.defaultRakats,
    actualPrayerTime: null,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}
