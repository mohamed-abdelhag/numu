// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing Islamic Prayer System settings.
/// Handles enabled state, calculation method, time window, and reminder configuration.
///
/// **Validates: Requirements 8.1, 8.2, 8.3, 9.1, 9.2**

@ProviderFor(PrayerSettingsNotifier)
const prayerSettingsProvider = PrayerSettingsNotifierProvider._();

/// Provider for managing Islamic Prayer System settings.
/// Handles enabled state, calculation method, time window, and reminder configuration.
///
/// **Validates: Requirements 8.1, 8.2, 8.3, 9.1, 9.2**
final class PrayerSettingsNotifierProvider
    extends $AsyncNotifierProvider<PrayerSettingsNotifier, PrayerSettings> {
  /// Provider for managing Islamic Prayer System settings.
  /// Handles enabled state, calculation method, time window, and reminder configuration.
  ///
  /// **Validates: Requirements 8.1, 8.2, 8.3, 9.1, 9.2**
  const PrayerSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerSettingsNotifierHash();

  @$internal
  @override
  PrayerSettingsNotifier create() => PrayerSettingsNotifier();
}

String _$prayerSettingsNotifierHash() =>
    r'2ed4218187c14ff4f9fe52bec1f6fcd986a84704';

/// Provider for managing Islamic Prayer System settings.
/// Handles enabled state, calculation method, time window, and reminder configuration.
///
/// **Validates: Requirements 8.1, 8.2, 8.3, 9.1, 9.2**

abstract class _$PrayerSettingsNotifier extends $AsyncNotifier<PrayerSettings> {
  FutureOr<PrayerSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<PrayerSettings>, PrayerSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrayerSettings>, PrayerSettings>,
              AsyncValue<PrayerSettings>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Convenience provider for checking if the Islamic Prayer System is enabled.
///
/// **Validates: Requirements 8.1, 8.2, 9.2**

@ProviderFor(isPrayerSystemEnabled)
const isPrayerSystemEnabledProvider = IsPrayerSystemEnabledProvider._();

/// Convenience provider for checking if the Islamic Prayer System is enabled.
///
/// **Validates: Requirements 8.1, 8.2, 9.2**

final class IsPrayerSystemEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Convenience provider for checking if the Islamic Prayer System is enabled.
  ///
  /// **Validates: Requirements 8.1, 8.2, 9.2**
  const IsPrayerSystemEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isPrayerSystemEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isPrayerSystemEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isPrayerSystemEnabled(ref);
  }
}

String _$isPrayerSystemEnabledHash() =>
    r'f5d2b5466ded486d8916530bf246f4c385703886';
