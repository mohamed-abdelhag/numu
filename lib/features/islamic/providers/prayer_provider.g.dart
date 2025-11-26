// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing prayer events and status for today.
///
/// **Validates: Requirements 2.1, 6.1, 6.5**

@ProviderFor(PrayerNotifier)
const prayerProvider = PrayerNotifierProvider._();

/// Provider for managing prayer events and status for today.
///
/// **Validates: Requirements 2.1, 6.1, 6.5**
final class PrayerNotifierProvider
    extends $AsyncNotifierProvider<PrayerNotifier, PrayerState> {
  /// Provider for managing prayer events and status for today.
  ///
  /// **Validates: Requirements 2.1, 6.1, 6.5**
  const PrayerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerNotifierHash();

  @$internal
  @override
  PrayerNotifier create() => PrayerNotifier();
}

String _$prayerNotifierHash() => r'bbe2f966a2e9095f12a3057a706c5f2456482205';

/// Provider for managing prayer events and status for today.
///
/// **Validates: Requirements 2.1, 6.1, 6.5**

abstract class _$PrayerNotifier extends $AsyncNotifier<PrayerState> {
  FutureOr<PrayerState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<PrayerState>, PrayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrayerState>, PrayerState>,
              AsyncValue<PrayerState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for getting the completion count for today.
///
/// **Validates: Requirements 6.5**

@ProviderFor(prayerCompletionCount)
const prayerCompletionCountProvider = PrayerCompletionCountProvider._();

/// Provider for getting the completion count for today.
///
/// **Validates: Requirements 6.5**

final class PrayerCompletionCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for getting the completion count for today.
  ///
  /// **Validates: Requirements 6.5**
  const PrayerCompletionCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerCompletionCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerCompletionCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return prayerCompletionCount(ref);
  }
}

String _$prayerCompletionCountHash() =>
    r'8bb819560432d28a9008cc5ee902fc6c5eec001a';

/// Provider for getting the status of a specific prayer.

@ProviderFor(prayerStatus)
const prayerStatusProvider = PrayerStatusFamily._();

/// Provider for getting the status of a specific prayer.

final class PrayerStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrayerStatus?>,
          PrayerStatus?,
          FutureOr<PrayerStatus?>
        >
    with $FutureModifier<PrayerStatus?>, $FutureProvider<PrayerStatus?> {
  /// Provider for getting the status of a specific prayer.
  const PrayerStatusProvider._({
    required PrayerStatusFamily super.from,
    required PrayerType super.argument,
  }) : super(
         retry: null,
         name: r'prayerStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$prayerStatusHash();

  @override
  String toString() {
    return r'prayerStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PrayerStatus?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrayerStatus?> create(Ref ref) {
    final argument = this.argument as PrayerType;
    return prayerStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PrayerStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prayerStatusHash() => r'1c25ad195fea9a33ffbf950672b391ed949f591a';

/// Provider for getting the status of a specific prayer.

final class PrayerStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PrayerStatus?>, PrayerType> {
  const PrayerStatusFamily._()
    : super(
        retry: null,
        name: r'prayerStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting the status of a specific prayer.

  PrayerStatusProvider call(PrayerType type) =>
      PrayerStatusProvider._(argument: type, from: this);

  @override
  String toString() => r'prayerStatusProvider';
}

/// Provider for checking if a specific prayer is completed.

@ProviderFor(isPrayerCompleted)
const isPrayerCompletedProvider = IsPrayerCompletedFamily._();

/// Provider for checking if a specific prayer is completed.

final class IsPrayerCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider for checking if a specific prayer is completed.
  const IsPrayerCompletedProvider._({
    required IsPrayerCompletedFamily super.from,
    required PrayerType super.argument,
  }) : super(
         retry: null,
         name: r'isPrayerCompletedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isPrayerCompletedHash();

  @override
  String toString() {
    return r'isPrayerCompletedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as PrayerType;
    return isPrayerCompleted(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsPrayerCompletedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isPrayerCompletedHash() => r'583064778e8a9c127d9415931ba346114ce66a08';

/// Provider for checking if a specific prayer is completed.

final class IsPrayerCompletedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, PrayerType> {
  const IsPrayerCompletedFamily._()
    : super(
        retry: null,
        name: r'isPrayerCompletedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for checking if a specific prayer is completed.

  IsPrayerCompletedProvider call(PrayerType type) =>
      IsPrayerCompletedProvider._(argument: type, from: this);

  @override
  String toString() => r'isPrayerCompletedProvider';
}
