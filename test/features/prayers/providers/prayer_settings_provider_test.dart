import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/prayer_settings.dart';
import 'package:numu/features/islamic/models/enums/calculation_method.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';

void main() {
  group('PrayerSettings Provider Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 18: Enabled State Propagation**
    /// **Validates: Requirements 9.2**
    ///
    /// *For any* change to the Islamic Prayer System enabled state (from profile,
    /// settings, or onboarding), the state change SHALL be immediately reflected
    /// in all dependent providers and UI components.
    ///
    /// This test verifies that when the enabled state is changed via copyWith,
    /// the new settings object correctly reflects the change while preserving
    /// other settings. This is the foundation for provider state propagation.
    Glados(any.choose([true, false])).test(
      'Property 18: Enabled State Propagation - copyWith correctly updates enabled state',
      (newEnabledState) {
        // Create initial settings with opposite enabled state
        final initialSettings = PrayerSettings(
          isEnabled: !newEnabledState,
          calculationMethod: CalculationMethod.muslimWorldLeague,
          timeWindowMinutes: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Update enabled state using copyWith (simulating provider update)
        final updatedSettings = initialSettings.copyWith(
          isEnabled: newEnabledState,
          updatedAt: DateTime.now(),
        );

        // Verify enabled state changed correctly
        expect(updatedSettings.isEnabled, equals(newEnabledState));
        
        // Verify other settings are preserved
        expect(updatedSettings.calculationMethod, equals(initialSettings.calculationMethod));
        expect(updatedSettings.timeWindowMinutes, equals(initialSettings.timeWindowMinutes));
      },
    );


    /// Test that enabled state round-trips through serialization
    Glados(any.choose([true, false])).test(
      'Property 18: Enabled State Propagation - enabled state survives serialization',
      (enabled) {
        final settings = PrayerSettings(
          isEnabled: enabled,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Serialize and deserialize (simulating database persistence)
        final map = settings.toMap();
        final restored = PrayerSettings.fromMap(map);

        // Verify enabled state is preserved
        expect(restored.isEnabled, equals(enabled));
      },
    );

    /// Test that multiple enabled state changes are correctly tracked
    Glados2(any.choose([true, false]), any.choose([true, false])).test(
      'Property 18: Enabled State Propagation - sequential state changes are tracked',
      (firstState, secondState) {
        final initial = PrayerSettings(
          isEnabled: !firstState,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // First state change
        final afterFirst = initial.copyWith(isEnabled: firstState);
        expect(afterFirst.isEnabled, equals(firstState));

        // Second state change
        final afterSecond = afterFirst.copyWith(isEnabled: secondState);
        expect(afterSecond.isEnabled, equals(secondState));
      },
    );

    /// Test that enabled state change preserves all other settings
    Glados(any.choose([true, false])).test(
      'Property 18: Enabled State Propagation - state change preserves all settings',
      (enabled) {
        // Create settings with all fields populated
        final settings = PrayerSettings(
          isEnabled: !enabled,
          calculationMethod: CalculationMethod.isna,
          timeWindowMinutes: 45,
          lastLatitude: 21.4225,
          lastLongitude: 39.8262,
          reminderEnabled: {
            PrayerType.fajr: true,
            PrayerType.dhuhr: false,
            PrayerType.asr: true,
            PrayerType.maghrib: false,
            PrayerType.isha: true,
          },
          reminderOffsetMinutes: {
            PrayerType.fajr: 10,
            PrayerType.dhuhr: 20,
            PrayerType.asr: 15,
            PrayerType.maghrib: 5,
            PrayerType.isha: 25,
          },
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        // Change only the enabled state
        final updated = settings.copyWith(isEnabled: enabled);

        // Verify enabled state changed
        expect(updated.isEnabled, equals(enabled));

        // Verify all other settings are preserved
        expect(updated.calculationMethod, equals(settings.calculationMethod));
        expect(updated.timeWindowMinutes, equals(settings.timeWindowMinutes));
        expect(updated.lastLatitude, equals(settings.lastLatitude));
        expect(updated.lastLongitude, equals(settings.lastLongitude));
        expect(updated.createdAt, equals(settings.createdAt));
        
        // Verify reminder settings preserved
        for (final type in PrayerType.values) {
          expect(
            updated.reminderEnabled[type],
            equals(settings.reminderEnabled[type]),
          );
          expect(
            updated.reminderOffsetMinutes[type],
            equals(settings.reminderOffsetMinutes[type]),
          );
        }
      },
    );
  });
}
