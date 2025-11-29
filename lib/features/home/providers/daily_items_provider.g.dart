// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DailyItemsNotifier)
const dailyItemsProvider = DailyItemsNotifierProvider._();

final class DailyItemsNotifierProvider
    extends $AsyncNotifierProvider<DailyItemsNotifier, DailyItemsState> {
  const DailyItemsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyItemsNotifierHash();

  @$internal
  @override
  DailyItemsNotifier create() => DailyItemsNotifier();
}

String _$dailyItemsNotifierHash() =>
    r'e53d5d9a991c7af04b4e68936bbfef8ad476498c';

abstract class _$DailyItemsNotifier extends $AsyncNotifier<DailyItemsState> {
  FutureOr<DailyItemsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<DailyItemsState>, DailyItemsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DailyItemsState>, DailyItemsState>,
              AsyncValue<DailyItemsState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for filtered and sorted daily items based on user preferences

@ProviderFor(filteredDailyItems)
const filteredDailyItemsProvider = FilteredDailyItemsProvider._();

/// Provider for filtered and sorted daily items based on user preferences

final class FilteredDailyItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyItemsState>,
          DailyItemsState,
          FutureOr<DailyItemsState>
        >
    with $FutureModifier<DailyItemsState>, $FutureProvider<DailyItemsState> {
  /// Provider for filtered and sorted daily items based on user preferences
  const FilteredDailyItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredDailyItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredDailyItemsHash();

  @$internal
  @override
  $FutureProviderElement<DailyItemsState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyItemsState> create(Ref ref) {
    return filteredDailyItems(ref);
  }
}

String _$filteredDailyItemsHash() =>
    r'c708cfc6c9ca005a461a677a0df3f7f180337872';
