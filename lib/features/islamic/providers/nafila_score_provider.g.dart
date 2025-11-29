// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nafila_score_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing Nafila prayer scores and statistics display.
///
/// **Validates: Requirements 4.4, 4.5**

@ProviderFor(NafilaScoreNotifier)
const nafilaScoreProvider = NafilaScoreNotifierProvider._();

/// Provider for managing Nafila prayer scores and statistics display.
///
/// **Validates: Requirements 4.4, 4.5**
final class NafilaScoreNotifierProvider
    extends $AsyncNotifierProvider<NafilaScoreNotifier, NafilaScoreState> {
  /// Provider for managing Nafila prayer scores and statistics display.
  ///
  /// **Validates: Requirements 4.4, 4.5**
  const NafilaScoreNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nafilaScoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nafilaScoreNotifierHash();

  @$internal
  @override
  NafilaScoreNotifier create() => NafilaScoreNotifier();
}

String _$nafilaScoreNotifierHash() =>
    r'eca498143947c882fe653334e29963639b670728';

/// Provider for managing Nafila prayer scores and statistics display.
///
/// **Validates: Requirements 4.4, 4.5**

abstract class _$NafilaScoreNotifier extends $AsyncNotifier<NafilaScoreState> {
  FutureOr<NafilaScoreState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<NafilaScoreState>, NafilaScoreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NafilaScoreState>, NafilaScoreState>,
              AsyncValue<NafilaScoreState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for getting the overall Nafila score percentage.

@ProviderFor(overallNafilaScorePercentage)
const overallNafilaScorePercentageProvider =
    OverallNafilaScorePercentageProvider._();

/// Provider for getting the overall Nafila score percentage.

final class OverallNafilaScorePercentageProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for getting the overall Nafila score percentage.
  const OverallNafilaScorePercentageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overallNafilaScorePercentageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overallNafilaScorePercentageHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return overallNafilaScorePercentage(ref);
  }
}

String _$overallNafilaScorePercentageHash() =>
    r'4e174678b88320f02103143f8b10352322f925ff';

/// Provider for getting the score of a specific Nafila type.

@ProviderFor(nafilaTypeScore)
const nafilaTypeScoreProvider = NafilaTypeScoreFamily._();

/// Provider for getting the score of a specific Nafila type.

final class NafilaTypeScoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<NafilaScore?>,
          NafilaScore?,
          FutureOr<NafilaScore?>
        >
    with $FutureModifier<NafilaScore?>, $FutureProvider<NafilaScore?> {
  /// Provider for getting the score of a specific Nafila type.
  const NafilaTypeScoreProvider._({
    required NafilaTypeScoreFamily super.from,
    required NafilaType super.argument,
  }) : super(
         retry: null,
         name: r'nafilaTypeScoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nafilaTypeScoreHash();

  @override
  String toString() {
    return r'nafilaTypeScoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NafilaScore?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NafilaScore?> create(Ref ref) {
    final argument = this.argument as NafilaType;
    return nafilaTypeScore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NafilaTypeScoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nafilaTypeScoreHash() => r'3034f958eded2c4d2236b21c634a5f70fde16d31';

/// Provider for getting the score of a specific Nafila type.

final class NafilaTypeScoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NafilaScore?>, NafilaType> {
  const NafilaTypeScoreFamily._()
    : super(
        retry: null,
        name: r'nafilaTypeScoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting the score of a specific Nafila type.

  NafilaTypeScoreProvider call(NafilaType type) =>
      NafilaTypeScoreProvider._(argument: type, from: this);

  @override
  String toString() => r'nafilaTypeScoreProvider';
}

/// Provider for getting total rakats prayed all time.

@ProviderFor(totalNafilaRakats)
const totalNafilaRakatsProvider = TotalNafilaRakatsProvider._();

/// Provider for getting total rakats prayed all time.

final class TotalNafilaRakatsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for getting total rakats prayed all time.
  const TotalNafilaRakatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalNafilaRakatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalNafilaRakatsHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalNafilaRakats(ref);
  }
}

String _$totalNafilaRakatsHash() => r'd0231bd04917edc9fbd8aa04d1fc3333a7db02b1';
