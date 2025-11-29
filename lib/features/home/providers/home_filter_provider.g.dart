// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing home screen filter and sort preferences

@ProviderFor(HomeFilterNotifier)
const homeFilterProvider = HomeFilterNotifierProvider._();

/// Provider for managing home screen filter and sort preferences
final class HomeFilterNotifierProvider
    extends $NotifierProvider<HomeFilterNotifier, HomeFilterState> {
  /// Provider for managing home screen filter and sort preferences
  const HomeFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeFilterNotifierHash();

  @$internal
  @override
  HomeFilterNotifier create() => HomeFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeFilterState>(value),
    );
  }
}

String _$homeFilterNotifierHash() =>
    r'94d94a986d2656d0dffc5a361be5a951467ccc58';

/// Provider for managing home screen filter and sort preferences

abstract class _$HomeFilterNotifier extends $Notifier<HomeFilterState> {
  HomeFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<HomeFilterState, HomeFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeFilterState, HomeFilterState>,
              HomeFilterState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
