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
    r'd7cf74f1972d047d40a49be952a4a2fcb488aa87';

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
