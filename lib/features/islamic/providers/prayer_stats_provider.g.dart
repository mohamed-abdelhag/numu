// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing prayer statistics and calendar view data.
///
/// **Validates: Requirements 4.1, 4.2, 4.3**

@ProviderFor(PrayerStatsNotifier)
const prayerStatsProvider = PrayerStatsNotifierProvider._();

/// Provider for managing prayer statistics and calendar view data.
///
/// **Validates: Requirements 4.1, 4.2, 4.3**
final class PrayerStatsNotifierProvider
    extends $AsyncNotifierProvider<PrayerStatsNotifier, PrayerStatsState> {
  /// Provider for managing prayer statistics and calendar view data.
  ///
  /// **Validates: Requirements 4.1, 4.2, 4.3**
  const PrayerStatsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerStatsNotifierHash();

  @$internal
  @override
  PrayerStatsNotifier create() => PrayerStatsNotifier();
}

String _$prayerStatsNotifierHash() =>
    r'c156e02201b8862289e18d2344e43bc9ae889ce8';

/// Provider for managing prayer statistics and calendar view data.
///
/// **Validates: Requirements 4.1, 4.2, 4.3**

abstract class _$PrayerStatsNotifier extends $AsyncNotifier<PrayerStatsState> {
  FutureOr<PrayerStatsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<PrayerStatsState>, PrayerStatsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrayerStatsState>, PrayerStatsState>,
              AsyncValue<PrayerStatsState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for getting stats for a specific date.

@ProviderFor(prayerDayStats)
const prayerDayStatsProvider = PrayerDayStatsFamily._();

/// Provider for getting stats for a specific date.

final class PrayerDayStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrayerDayStats?>,
          PrayerDayStats?,
          FutureOr<PrayerDayStats?>
        >
    with $FutureModifier<PrayerDayStats?>, $FutureProvider<PrayerDayStats?> {
  /// Provider for getting stats for a specific date.
  const PrayerDayStatsProvider._({
    required PrayerDayStatsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'prayerDayStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$prayerDayStatsHash();

  @override
  String toString() {
    return r'prayerDayStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PrayerDayStats?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrayerDayStats?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return prayerDayStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PrayerDayStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prayerDayStatsHash() => r'ef40282b877d1518c0e0b0c8fa63d90dbc948e5e';

/// Provider for getting stats for a specific date.

final class PrayerDayStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PrayerDayStats?>, DateTime> {
  const PrayerDayStatsFamily._()
    : super(
        retry: null,
        name: r'prayerDayStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting stats for a specific date.

  PrayerDayStatsProvider call(DateTime date) =>
      PrayerDayStatsProvider._(argument: date, from: this);

  @override
  String toString() => r'prayerDayStatsProvider';
}

/// Provider for getting the obligatory completion rate for the selected month.

@ProviderFor(obligatoryCompletionRate)
const obligatoryCompletionRateProvider = ObligatoryCompletionRateProvider._();

/// Provider for getting the obligatory completion rate for the selected month.

final class ObligatoryCompletionRateProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provider for getting the obligatory completion rate for the selected month.
  const ObligatoryCompletionRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obligatoryCompletionRateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obligatoryCompletionRateHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return obligatoryCompletionRate(ref);
  }
}

String _$obligatoryCompletionRateHash() =>
    r'7a62f8a69708b407f13f1e65ebeee1cfb7d5d63b';

/// Provider for getting the Nafila completion rate for the selected month.

@ProviderFor(nafilaCompletionRate)
const nafilaCompletionRateProvider = NafilaCompletionRateProvider._();

/// Provider for getting the Nafila completion rate for the selected month.

final class NafilaCompletionRateProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provider for getting the Nafila completion rate for the selected month.
  const NafilaCompletionRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nafilaCompletionRateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nafilaCompletionRateHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return nafilaCompletionRate(ref);
  }
}

String _$nafilaCompletionRateHash() =>
    r'ed04a2d4e45dc143eeb5c862cb5127ad55eb8c8c';
