// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing theme configuration state

@ProviderFor(ThemeConfig)
const themeConfigProvider = ThemeConfigProvider._();

/// Notifier for managing theme configuration state
final class ThemeConfigProvider
    extends $AsyncNotifierProvider<ThemeConfig, ThemeConfigModel> {
  /// Notifier for managing theme configuration state
  const ThemeConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeConfigHash();

  @$internal
  @override
  ThemeConfig create() => ThemeConfig();
}

String _$themeConfigHash() => r'd3dbe2168478d89d345822b47e74d6b5d98bd331';

/// Notifier for managing theme configuration state

abstract class _$ThemeConfig extends $AsyncNotifier<ThemeConfigModel> {
  FutureOr<ThemeConfigModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<ThemeConfigModel>, ThemeConfigModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeConfigModel>, ThemeConfigModel>,
              AsyncValue<ThemeConfigModel>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
