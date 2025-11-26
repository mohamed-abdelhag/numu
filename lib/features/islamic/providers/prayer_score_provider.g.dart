// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_score_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing prayer scores and statistics display.
///
/// **Validates: Requirements 4.2, 4.3, 6.6**

@ProviderFor(PrayerScoreNotifier)
const prayerScoreProvider = PrayerScoreNotifierProvider._();

/// Provider for managing prayer scores and statistics display.
///
/// **Validates: Requirements 4.2, 4.3, 6.6**
final class PrayerScoreNotifierProvider
    extends $AsyncNotifierProvider<PrayerScoreNotifier, PrayerScoreState> {
  /// Provider for managing prayer scores and statistics display.
  ///
  /// **Validates: Requirements 4.2, 4.3, 6.6**
  const PrayerScoreNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerScoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerScoreNotifierHash();

  @$internal
  @override
  PrayerScoreNotifier create() => PrayerScoreNotifier();
}

String _$prayerScoreNotifierHash() =>
    r'2a3efa693ae9c19ee9e4c63cd44de61be173ff10';

/// Provider for managing prayer scores and statistics display.
///
/// **Validates: Requirements 4.2, 4.3, 6.6**

abstract class _$PrayerScoreNotifier extends $AsyncNotifier<PrayerScoreState> {
  FutureOr<PrayerScoreState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<PrayerScoreState>, PrayerScoreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrayerScoreState>, PrayerScoreState>,
              AsyncValue<PrayerScoreState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for getting the overall prayer score.
///
/// **Validates: Requirements 4.2, 4.3**

@ProviderFor(overallPrayerScore)
const overallPrayerScoreProvider = OverallPrayerScoreProvider._();

/// Provider for getting the overall prayer score.
///
/// **Validates: Requirements 4.2, 4.3**

final class OverallPrayerScoreProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provider for getting the overall prayer score.
  ///
  /// **Validates: Requirements 4.2, 4.3**
  const OverallPrayerScoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overallPrayerScoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overallPrayerScoreHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return overallPrayerScore(ref);
  }
}

String _$overallPrayerScoreHash() =>
    r'd762da3b7ca168492f67c97753a3222f9886ad70';

/// Provider for getting the score of a specific prayer type.

@ProviderFor(prayerTypeScore)
const prayerTypeScoreProvider = PrayerTypeScoreFamily._();

/// Provider for getting the score of a specific prayer type.

final class PrayerTypeScoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrayerScore?>,
          PrayerScore?,
          FutureOr<PrayerScore?>
        >
    with $FutureModifier<PrayerScore?>, $FutureProvider<PrayerScore?> {
  /// Provider for getting the score of a specific prayer type.
  const PrayerTypeScoreProvider._({
    required PrayerTypeScoreFamily super.from,
    required PrayerType super.argument,
  }) : super(
         retry: null,
         name: r'prayerTypeScoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$prayerTypeScoreHash();

  @override
  String toString() {
    return r'prayerTypeScoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PrayerScore?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrayerScore?> create(Ref ref) {
    final argument = this.argument as PrayerType;
    return prayerTypeScore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PrayerTypeScoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prayerTypeScoreHash() => r'c1fded415cfeb907873579758493b5225e9315af';

/// Provider for getting the score of a specific prayer type.

final class PrayerTypeScoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PrayerScore?>, PrayerType> {
  const PrayerTypeScoreFamily._()
    : super(
        retry: null,
        name: r'prayerTypeScoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting the score of a specific prayer type.

  PrayerTypeScoreProvider call(PrayerType type) =>
      PrayerTypeScoreProvider._(argument: type, from: this);

  @override
  String toString() => r'prayerTypeScoreProvider';
}

/// Provider for getting the overall score as a percentage.

@ProviderFor(overallPrayerScorePercentage)
const overallPrayerScorePercentageProvider =
    OverallPrayerScorePercentageProvider._();

/// Provider for getting the overall score as a percentage.

final class OverallPrayerScorePercentageProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for getting the overall score as a percentage.
  const OverallPrayerScorePercentageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overallPrayerScorePercentageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overallPrayerScorePercentageHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return overallPrayerScorePercentage(ref);
  }
}

String _$overallPrayerScorePercentageHash() =>
    r'7ba8196083e05e5327e29b4c3c05dae9b343af22';

/// Provider for getting the average Jamaah rate.

@ProviderFor(averageJamaahRate)
const averageJamaahRateProvider = AverageJamaahRateProvider._();

/// Provider for getting the average Jamaah rate.

final class AverageJamaahRateProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provider for getting the average Jamaah rate.
  const AverageJamaahRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'averageJamaahRateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$averageJamaahRateHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return averageJamaahRate(ref);
  }
}

String _$averageJamaahRateHash() => r'ac2e236efbe2b1c6b33fedb90906100c8791b8a4';
