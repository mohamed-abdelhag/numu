import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/prayer_status.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';

/// Custom generators for prayer enum tests
extension PrayerEnumGenerators on Any {
  /// Generator for CalculationMethod enum values
  Generator<CalculationMethod> get calculationMethod =>
      choose(CalculationMethod.values);

  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for PrayerStatus enum values
  Generator<PrayerStatus> get prayerStatus => choose(PrayerStatus.values);
}

void main() {
  group('Prayer Enum Serialization Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 16: Calculation Method Persistence**
    /// **Validates: Requirements 8.4**
    ///
    /// *For any* valid calculation method selected by the user, storing the setting
    /// and then retrieving it SHALL return the same calculation method.
    Glados(any.calculationMethod).test(
      'Property 16: Calculation Method Persistence - toJson/fromJson round-trip preserves value',
      (method) {
        // Serialize to JSON
        final json = method.toJson();

        // Deserialize from JSON
        final restored = CalculationMethod.fromJson(json);

        // Verify round-trip preserves the value
        expect(restored, equals(method));
      },
    );

    /// Additional property test for PrayerType enum round-trip
    /// This validates that prayer types can be persisted correctly
    Glados(any.prayerType).test(
      'PrayerType toJson/fromJson round-trip preserves value',
      (prayerType) {
        // Serialize to JSON
        final json = prayerType.toJson();

        // Deserialize from JSON
        final restored = PrayerType.fromJson(json);

        // Verify round-trip preserves the value
        expect(restored, equals(prayerType));
      },
    );

    /// Additional property test for PrayerStatus enum round-trip
    /// This validates that prayer statuses can be persisted correctly
    Glados(any.prayerStatus).test(
      'PrayerStatus toJson/fromJson round-trip preserves value',
      (status) {
        // Serialize to JSON
        final json = status.toJson();

        // Deserialize from JSON
        final restored = PrayerStatus.fromJson(json);

        // Verify round-trip preserves the value
        expect(restored, equals(status));
      },
    );
  });

  group('Prayer Enum Properties Tests', () {
    test('CalculationMethod has correct display names', () {
      expect(CalculationMethod.muslimWorldLeague.displayName,
          equals('Muslim World League'));
      expect(CalculationMethod.isna.displayName, equals('ISNA (North America)'));
      expect(CalculationMethod.egyptian.displayName,
          equals('Egyptian General Authority'));
      expect(
          CalculationMethod.ummAlQura.displayName, equals('Umm Al-Qura (Makkah)'));
      expect(CalculationMethod.karachi.displayName,
          equals('University of Karachi'));
      expect(CalculationMethod.tehran.displayName,
          equals('Institute of Geophysics, Tehran'));
      expect(CalculationMethod.gulf.displayName, equals('Gulf Region'));
    });

    test('CalculationMethod apiValue matches index', () {
      for (final method in CalculationMethod.values) {
        expect(method.apiValue, equals(method.index));
      }
    });

    test('PrayerType has correct Arabic names', () {
      expect(PrayerType.fajr.arabicName, equals('الفجر'));
      expect(PrayerType.dhuhr.arabicName, equals('الظهر'));
      expect(PrayerType.asr.arabicName, equals('العصر'));
      expect(PrayerType.maghrib.arabicName, equals('المغرب'));
      expect(PrayerType.isha.arabicName, equals('العشاء'));
    });

    test('PrayerType has correct English names', () {
      expect(PrayerType.fajr.englishName, equals('Fajr'));
      expect(PrayerType.dhuhr.englishName, equals('Dhuhr'));
      expect(PrayerType.asr.englishName, equals('Asr'));
      expect(PrayerType.maghrib.englishName, equals('Maghrib'));
      expect(PrayerType.isha.englishName, equals('Isha'));
    });

    test('PrayerType sortOrder matches index', () {
      for (final type in PrayerType.values) {
        expect(type.sortOrder, equals(type.index));
      }
    });

    test('PrayerType values are in chronological order', () {
      expect(PrayerType.fajr.sortOrder, lessThan(PrayerType.dhuhr.sortOrder));
      expect(PrayerType.dhuhr.sortOrder, lessThan(PrayerType.asr.sortOrder));
      expect(PrayerType.asr.sortOrder, lessThan(PrayerType.maghrib.sortOrder));
      expect(PrayerType.maghrib.sortOrder, lessThan(PrayerType.isha.sortOrder));
    });
  });
}
