import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/prayer_day_stats.dart';
import 'package:numu/features/islamic/models/prayer_event.dart';
import 'package:numu/features/islamic/models/nafila_event.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/enums/nafila_type.dart';

/// Custom generators for PrayerStatsProvider tests
extension PrayerStatsGenerators on Any {
  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2025).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for a subset of PrayerType values
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

  /// Generator for a subset of defined NafilaType values
  Generator<List<NafilaType>> get definedNafilaTypeSubset {
    final definedTypes = NafilaType.values.where((t) => t.isDefined).toList();
    return choose([
      <NafilaType>[],
      [NafilaType.sunnahFajr],
      [NafilaType.duha],
      [NafilaType.shafiWitr],
      [NafilaType.sunnahFajr, NafilaType.duha],
      [NafilaType.sunnahFajr, NafilaType.shafiWitr],
      [NafilaType.duha, NafilaType.shafiWitr],
      definedTypes,
    ]);
  }

  /// Generator for rakat count within valid range
  Generator<int> get rakatCount => intInRange(2, 12);
}

/// Helper function to create PrayerDayStats from events
/// This simulates the aggregation logic in PrayerStatsProvider
PrayerDayStats aggregateDayStats({
  required DateTime date,
  required List<PrayerEvent> prayerEvents,
  required List<NafilaEvent> nafilaEvents,
}) {
  // Build obligatory completion map
  final obligatoryCompleted = <PrayerType, bool>{};
  for (final type in PrayerType.values) {
    obligatoryCompleted[type] = prayerEvents.any((e) => e.prayerType == type);
  }

  // Build Nafila completion map (only defined types)
  final nafilaCompleted = <NafilaType, bool>{};
  for (final type in NafilaType.values.where((t) => t.isDefined)) {
    nafilaCompleted[type] = nafilaEvents.any((e) => e.nafilaType == type);
  }

  // Calculate total rakats
  final totalRakats = nafilaEvents.fold(0, (sum, e) => sum + e.rakatCount);

  return PrayerDayStats(
    date: date,
    obligatoryCompleted: obligatoryCompleted,
    nafilaCompleted: nafilaCompleted,
    totalRakatsNafila: totalRakats,
  );
}

void main() {
  group('PrayerStatsProvider Property Tests', () {
    /// **Feature: nafila-prayer-system, Property 6: Calendar Day Stats Aggregation**
    /// **Validates: Requirements 4.2**
    ///
    /// *For any* date with prayer events and Nafila events, the PrayerDayStats should
    /// correctly reflect completion status for all five obligatory prayers and three
    /// defined Sunnah types.
    Glados3(any.dateOnly, any.prayerTypeSubset, any.definedNafilaTypeSubset).test(
      'Property 6: Calendar Day Stats Aggregation - completion status reflects events',
      (date, completedPrayers, completedNafilas) {
        final now = DateTime.now();

        // Create prayer events for completed prayers
        final prayerEvents = completedPrayers.map((type) => PrayerEvent(
              prayerType: type,
              eventDate: date,
              eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
              createdAt: now,
              updatedAt: now,
            )).toList();

        // Create Nafila events for completed Nafilas
        final nafilaEvents = completedNafilas.map((type) => NafilaEvent(
              nafilaType: type,
              eventDate: date,
              eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
              rakatCount: type.defaultRakats,
              createdAt: now,
              updatedAt: now,
            )).toList();

        // Aggregate stats
        final stats = aggregateDayStats(
          date: date,
          prayerEvents: prayerEvents,
          nafilaEvents: nafilaEvents,
        );

        // Verify obligatory prayer completion status
        for (final type in PrayerType.values) {
          final expected = completedPrayers.contains(type);
          expect(stats.isObligatoryCompleted(type), equals(expected),
              reason: '${type.englishName} completion status should match events');
        }

        // Verify Nafila completion status
        for (final type in NafilaType.values.where((t) => t.isDefined)) {
          final expected = completedNafilas.contains(type);
          expect(stats.isNafilaCompleted(type), equals(expected),
              reason: '${type.englishName} completion status should match events');
        }

        // Verify counts
        expect(stats.obligatoryCompletedCount, equals(completedPrayers.toSet().length),
            reason: 'Obligatory completed count should match number of completed prayers');
        expect(stats.definedNafilaCompletedCount, equals(completedNafilas.toSet().length),
            reason: 'Nafila completed count should match number of completed Nafilas');
      },
    );

    Glados2(any.dateOnly, any.intInRange(1, 5)).test(
      'Property 6: Calendar Day Stats Aggregation - total rakats equals sum',
      (date, eventCount) {
        final now = DateTime.now();
        final definedTypes = NafilaType.values.where((t) => t.isDefined).toList();

        // Create Nafila events with varying rakat counts
        final nafilaEvents = <NafilaEvent>[];
        int expectedTotal = 0;

        for (int i = 0; i < eventCount && i < definedTypes.length; i++) {
          final rakats = definedTypes[i].defaultRakats;
          expectedTotal += rakats;
          nafilaEvents.add(NafilaEvent(
            nafilaType: definedTypes[i],
            eventDate: date,
            eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
            rakatCount: rakats,
            createdAt: now,
            updatedAt: now,
          ));
        }

        // Aggregate stats
        final stats = aggregateDayStats(
          date: date,
          prayerEvents: [],
          nafilaEvents: nafilaEvents,
        );

        expect(stats.totalRakatsNafila, equals(expectedTotal),
            reason: 'Total rakats should equal sum of all Nafila rakat counts');
      },
    );

    Glados(any.dateOnly).test(
      'Property 6: Calendar Day Stats Aggregation - empty events produce empty stats',
      (date) {
        final stats = aggregateDayStats(
          date: date,
          prayerEvents: [],
          nafilaEvents: [],
        );

        // All obligatory prayers should be incomplete
        for (final type in PrayerType.values) {
          expect(stats.isObligatoryCompleted(type), isFalse,
              reason: '${type.englishName} should be incomplete with no events');
        }

        // All defined Nafilas should be incomplete
        for (final type in NafilaType.values.where((t) => t.isDefined)) {
          expect(stats.isNafilaCompleted(type), isFalse,
              reason: '${type.englishName} should be incomplete with no events');
        }

        expect(stats.obligatoryCompletedCount, equals(0));
        expect(stats.definedNafilaCompletedCount, equals(0));
        expect(stats.totalRakatsNafila, equals(0));
      },
    );

    Glados(any.dateOnly).test(
      'Property 6: Calendar Day Stats Aggregation - all prayers completed',
      (date) {
        final now = DateTime.now();

        // Create events for all obligatory prayers
        final prayerEvents = PrayerType.values.map((type) => PrayerEvent(
              prayerType: type,
              eventDate: date,
              eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
              createdAt: now,
              updatedAt: now,
            )).toList();

        // Create events for all defined Nafilas
        final nafilaEvents = NafilaType.values
            .where((t) => t.isDefined)
            .map((type) => NafilaEvent(
                  nafilaType: type,
                  eventDate: date,
                  eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
                  rakatCount: type.defaultRakats,
                  createdAt: now,
                  updatedAt: now,
                ))
            .toList();

        final stats = aggregateDayStats(
          date: date,
          prayerEvents: prayerEvents,
          nafilaEvents: nafilaEvents,
        );

        // All obligatory prayers should be complete
        expect(stats.obligatoryCompletedCount, equals(5),
            reason: 'All 5 obligatory prayers should be completed');
        expect(stats.obligatoryPercentage, equals(100),
            reason: 'Obligatory percentage should be 100%');

        // All defined Nafilas should be complete
        expect(stats.definedNafilaCompletedCount, equals(3),
            reason: 'All 3 defined Nafilas should be completed');
        expect(stats.nafilaPercentage, equals(100),
            reason: 'Nafila percentage should be 100%');
      },
    );

    Glados2(any.prayerTypeSubset, any.dateOnly).test(
      'Property 6: Calendar Day Stats Aggregation - percentage calculation is correct',
      (completedPrayers, date) {
        final now = DateTime.now();

        final prayerEvents = completedPrayers.map((type) => PrayerEvent(
              prayerType: type,
              eventDate: date,
              eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
              createdAt: now,
              updatedAt: now,
            )).toList();

        final stats = aggregateDayStats(
          date: date,
          prayerEvents: prayerEvents,
          nafilaEvents: [],
        );

        final expectedPercentage = (completedPrayers.toSet().length / 5 * 100).round();
        expect(stats.obligatoryPercentage, equals(expectedPercentage),
            reason: 'Obligatory percentage should be (completed/5)*100');
      },
    );
  });

  group('PrayerDayStats Unit Tests', () {
    test('empty factory creates stats with all false values', () {
      final date = DateTime(2024, 6, 15);
      final stats = PrayerDayStats.empty(date);

      expect(stats.date, equals(date));
      expect(stats.obligatoryCompletedCount, equals(0));
      expect(stats.definedNafilaCompletedCount, equals(0));
      expect(stats.totalRakatsNafila, equals(0));
    });

    test('copyWith preserves unchanged values', () {
      final original = PrayerDayStats(
        date: DateTime(2024, 6, 15),
        obligatoryCompleted: {PrayerType.fajr: true, PrayerType.dhuhr: false},
        nafilaCompleted: {NafilaType.sunnahFajr: true},
        totalRakatsNafila: 10,
      );

      final copied = original.copyWith(totalRakatsNafila: 20);

      expect(copied.date, equals(original.date));
      expect(copied.obligatoryCompleted, equals(original.obligatoryCompleted));
      expect(copied.nafilaCompleted, equals(original.nafilaCompleted));
      expect(copied.totalRakatsNafila, equals(20));
    });

    test('totalObligatoryPrayers returns 5', () {
      final stats = PrayerDayStats.empty(DateTime(2024, 6, 15));
      expect(stats.totalObligatoryPrayers, equals(5));
    });

    test('totalDefinedNafilaPrayers returns 3', () {
      final stats = PrayerDayStats.empty(DateTime(2024, 6, 15));
      expect(stats.totalDefinedNafilaPrayers, equals(3));
    });
  });
}
