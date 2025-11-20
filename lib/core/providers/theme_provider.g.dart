// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for SettingsRepository

@ProviderFor(settingsRepository)
const settingsRepositoryProvider = SettingsRepositoryProvider._();

/// Provider for SettingsRepository

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// Provider for SettingsRepository
  const SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'5bf0fddc028c126230ab02a992642926b8044d37';

/// Notifier for managing theme mode state
/// This provider now reads from ThemeConfigProvider for backward compatibility

@ProviderFor(ThemeNotifier)
const themeProvider = ThemeNotifierProvider._();

/// Notifier for managing theme mode state
/// This provider now reads from ThemeConfigProvider for backward compatibility
final class ThemeNotifierProvider
    extends $AsyncNotifierProvider<ThemeNotifier, ThemeMode> {
  /// Notifier for managing theme mode state
  /// This provider now reads from ThemeConfigProvider for backward compatibility
  const ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();
}

String _$themeNotifierHash() => r'089dab70f2fd810bd63f8086a821656d38b867d4';

/// Notifier for managing theme mode state
/// This provider now reads from ThemeConfigProvider for backward compatibility

abstract class _$ThemeNotifier extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
              AsyncValue<ThemeMode>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for light theme data based on current color scheme

@ProviderFor(lightTheme)
const lightThemeProvider = LightThemeProvider._();

/// Provider for light theme data based on current color scheme

final class LightThemeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemeData>,
          ThemeData,
          FutureOr<ThemeData>
        >
    with $FutureModifier<ThemeData>, $FutureProvider<ThemeData> {
  /// Provider for light theme data based on current color scheme
  const LightThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lightThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lightThemeHash();

  @$internal
  @override
  $FutureProviderElement<ThemeData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ThemeData> create(Ref ref) {
    return lightTheme(ref);
  }
}

String _$lightThemeHash() => r'ad0e5c7531b24bdc488c447f29d6d46906eca190';

/// Provider for dark theme data based on current color scheme

@ProviderFor(darkTheme)
const darkThemeProvider = DarkThemeProvider._();

/// Provider for dark theme data based on current color scheme

final class DarkThemeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemeData>,
          ThemeData,
          FutureOr<ThemeData>
        >
    with $FutureModifier<ThemeData>, $FutureProvider<ThemeData> {
  /// Provider for dark theme data based on current color scheme
  const DarkThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'darkThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$darkThemeHash();

  @$internal
  @override
  $FutureProviderElement<ThemeData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ThemeData> create(Ref ref) {
    return darkTheme(ref);
  }
}

String _$darkThemeHash() => r'9017e2aa44ad9ba69c4e3fb35314e20342fb6e8e';
