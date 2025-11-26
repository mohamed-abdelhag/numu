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

String _$themeConfigHash() => r'e9d80d7af852d57f4199d64e0288c3066c6a0a82';

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
