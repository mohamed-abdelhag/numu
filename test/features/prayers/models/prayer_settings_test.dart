import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/prayer_settings.dart';

/// Custom generators for PrayerSettings tests
extension PrayerSettingsGenerators on Any {
  /// Generator for valid time window minutes (positive integer, reasonable range)
  Generator<int> get timeWindowMinutes => intInRange(1, 120);

  /// Generator for CalculationMethod enum values
  Generator<CalculationMethod> get calculationMethod =>
      choose(CalculationMethod.values);

  /// Generator for valid latitude values (-90 to 90)
  Generator<double> get latitude => doubleInRange(-90.0, 90.0);

  /// Generator for valid longitude values (-180 to 180)
  Generator<double> get longitude => doubleInRange(-180.0, 180.0);

  /// Generator for reminder offset minutes (reasonable range)
  Generator<int> get reminderOffset => intInRange(0, 60);

  /// Generator for a complete PrayerSettings
  Generator<PrayerSettings> get prayerSettings {
    return choose([true, false]).bind((isEnabled) =>
        calculationMethod.bind((method) =>
            timeWindowMinutes.bind((windowMinutes) =>
                choose([true, false]).bind((hasLocation) =>
                    (hasLocation ? latitude : always<double?>(null)).bind((lat) =>
                        (hasLocation ? longitude : always<double?>(null)).bind((lng) =>
                            choose([true, false]).bind((showNafilaAtHome) =>
                                _reminderEnabledMap.bind((reminderEnabled) =>
                                    _reminderOffsetMap.bind((reminderOffsets) =>
                                        always(DateTime.now()).bind((createdAt) =>
                                            always(DateTime.now()).map((updatedAt) =>
                                                PrayerSettings(
                                                  isEnabled: isEnabled,
                                                  calculationMethod: method,
                                                  timeWindowMinutes: windowMinutes,
                                                  lastLatitude: lat,
                                                  lastLongitude: lng,
                                                  showNafilaAtHome: showNafilaAtHome,
                                                  reminderEnabled: reminderEnabled,
                                                  reminderOffsetMinutes: reminderOffsets,
                                                  createdAt: createdAt,
                                                  updatedAt: updatedAt,
                                                ))))))))))));
  }

  /// Generator for reminder enabled map
  Generator<Map<PrayerType, bool>> get _reminderEnabledMap {
    return choose([true, false]).bind((fajr) =>
        choose([true, false]).bind((dhuhr) =>
            choose([true, false]).bind((asr) =>
                choose([true, false]).bind((maghrib) =>
                    choose([true, false]).map((isha) => {
                          PrayerType.fajr: fajr,
                          PrayerType.dhuhr: dhuhr,
                          PrayerType.asr: asr,
                          PrayerType.maghrib: maghrib,
                          PrayerType.isha: isha,
                        })))));
  }

  /// Generator for reminder offset map
  Generator<Map<PrayerType, int>> get _reminderOffsetMap {
    return reminderOffset.bind((fajr) =>
        reminderOffset.bind((dhuhr) =>
            reminderOffset.bind((asr) =>
                reminderOffset.bind((maghrib) =>
                    reminderOffset.map((isha) => {
                          PrayerType.fajr: fajr,
                          PrayerType.dhuhr: dhuhr,
                          PrayerType.asr: asr,
                          PrayerType.maghrib: maghrib,
                          PrayerType.isha: isha,
                        })))));
  }
}

void main() {
  group('PrayerSettings Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 17: Time Window Configuration Persistence**
    /// **Validates: Requirements 8.5**
    ///
    /// *For any* valid time window duration (positive integer minutes),
    /// storing the setting and then retrieving it SHALL return the same duration value.
    Glados(any.timeWindowMinutes).test(
      'Property 17: Time Window Configuration Persistence - toMap/fromMap preserves time window',
      (windowMinutes) {
        final settings = PrayerSettings(
          timeWindowMinutes: windowMinutes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Serialize to map (simulating database storage)
        final map = settings.toMap();

        // Deserialize from map (simulating database retrieval)
        final restored = PrayerSettings.fromMap(map);

        // Verify time window is preserved
        expect(restored.timeWindowMinutes, equals(windowMinutes));
      },
    );

    /// Full round-trip test for PrayerSettings
    Glados(any.prayerSettings).test(
      'PrayerSettings full round-trip - toMap/fromMap preserves all fields',
      (settings) {
        // Serialize to map (simulating database storage)
        final map = settings.toMap();

        // Deserialize from map (simulating database retrieval)
        final restored = PrayerSettings.fromMap(map);

        // Verify all fields are preserved
        expect(restored.isEnabled, equals(settings.isEnabled));
        expect(restored.calculationMethod, equals(settings.calculationMethod));
        expect(restored.timeWindowMinutes, equals(settings.timeWindowMinutes));
        expect(restored.lastLatitude, equals(settings.lastLatitude));
        expect(restored.lastLongitude, equals(settings.lastLongitude));
        expect(restored.showNafilaAtHome, equals(settings.showNafilaAtHome));
        expect(restored.createdAt, equals(settings.createdAt));
        expect(restored.updatedAt, equals(settings.updatedAt));

        // Verify reminder settings for each prayer type
        for (final type in PrayerType.values) {
          expect(
            restored.reminderEnabled[type],
            equals(settings.reminderEnabled[type]),
          );
          expect(
            restored.reminderOffsetMinutes[type],
            equals(settings.reminderOffsetMinutes[type]),
          );
        }
      },
    );

    /// **Feature: nafila-prayer-system, Property 9: Settings Persistence Round-Trip**
    /// **Validates: Requirements 6.2**
    ///
    /// *For any* boolean value for the "Show Nafila at Home" setting,
    /// saving and then loading the setting should return the same boolean value.
    Glados(any.choose([true, false])).test(
      'Property 9: Settings Persistence Round-Trip - showNafilaAtHome is preserved',
      (showNafilaAtHome) {
        final settings = PrayerSettings(
          showNafilaAtHome: showNafilaAtHome,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Serialize to map (simulating database storage)
        final map = settings.toMap();

        // Deserialize from map (simulating database retrieval)
        final restored = PrayerSettings.fromMap(map);

        // Verify showNafilaAtHome is preserved
        expect(restored.showNafilaAtHome, equals(showNafilaAtHome));
      },
    );
  });

  group('PrayerSettings Unit Tests', () {
    test('defaults factory creates correct default values', () {
      final settings = PrayerSettings.defaults();

      expect(settings.isEnabled, isFalse);
      expect(settings.calculationMethod, equals(CalculationMethod.muslimWorldLeague));
      expect(settings.timeWindowMinutes, equals(30));
      expect(settings.lastLatitude, isNull);
      expect(settings.lastLongitude, isNull);

      // All reminders should be enabled by default
      for (final type in PrayerType.values) {
        expect(settings.isReminderEnabled(type), isTrue);
        expect(settings.getReminderOffset(type), equals(15));
      }
    });

    test('copyWith creates new instance with updated fields', () {
      final original = PrayerSettings.defaults();

      final updated = original.copyWith(
        isEnabled: true,
        calculationMethod: CalculationMethod.isna,
        timeWindowMinutes: 45,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.calculationMethod, equals(CalculationMethod.isna));
      expect(updated.timeWindowMinutes, equals(45));
      // Original fields should be preserved
      expect(updated.lastLatitude, isNull);
    });

    test('isReminderEnabled returns correct value for each prayer', () {
      final settings = PrayerSettings(
        reminderEnabled: {
          PrayerType.fajr: true,
          PrayerType.dhuhr: false,
          PrayerType.asr: true,
          PrayerType.maghrib: false,
          PrayerType.isha: true,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(settings.isReminderEnabled(PrayerType.fajr), isTrue);
      expect(settings.isReminderEnabled(PrayerType.dhuhr), isFalse);
      expect(settings.isReminderEnabled(PrayerType.asr), isTrue);
      expect(settings.isReminderEnabled(PrayerType.maghrib), isFalse);
      expect(settings.isReminderEnabled(PrayerType.isha), isTrue);
    });

    test('getReminderOffset returns correct value for each prayer', () {
      final settings = PrayerSettings(
        reminderOffsetMinutes: {
          PrayerType.fajr: 10,
          PrayerType.dhuhr: 20,
          PrayerType.asr: 30,
          PrayerType.maghrib: 5,
          PrayerType.isha: 15,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(settings.getReminderOffset(PrayerType.fajr), equals(10));
      expect(settings.getReminderOffset(PrayerType.dhuhr), equals(20));
      expect(settings.getReminderOffset(PrayerType.asr), equals(30));
      expect(settings.getReminderOffset(PrayerType.maghrib), equals(5));
      expect(settings.getReminderOffset(PrayerType.isha), equals(15));
    });

    test('toMap correctly serializes boolean fields as integers', () {
      final settings = PrayerSettings(
        isEnabled: true,
        reminderEnabled: {
          PrayerType.fajr: true,
          PrayerType.dhuhr: false,
          PrayerType.asr: true,
          PrayerType.maghrib: false,
          PrayerType.isha: true,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = settings.toMap();

      expect(map['is_enabled'], equals(1));
      expect(map['reminder_fajr_enabled'], equals(1));
      expect(map['reminder_dhuhr_enabled'], equals(0));
      expect(map['reminder_asr_enabled'], equals(1));
      expect(map['reminder_maghrib_enabled'], equals(0));
      expect(map['reminder_isha_enabled'], equals(1));
    });
  });
}
