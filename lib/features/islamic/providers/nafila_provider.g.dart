// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nafila_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing Nafila prayer events and status for today.
///
/// **Validates: Requirements 1.2, 2.1, 2.2**

@ProviderFor(NafilaNotifier)
const nafilaProvider = NafilaNotifierProvider._();

/// Provider for managing Nafila prayer events and status for today.
///
/// **Validates: Requirements 1.2, 2.1, 2.2**
final class NafilaNotifierProvider
    extends $AsyncNotifierProvider<NafilaNotifier, NafilaState> {
  /// Provider for managing Nafila prayer events and status for today.
  ///
  /// **Validates: Requirements 1.2, 2.1, 2.2**
  const NafilaNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nafilaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nafilaNotifierHash();

  @$internal
  @override
  NafilaNotifier create() => NafilaNotifier();
}

String _$nafilaNotifierHash() => r'60270469324d6f95709e23b44acc0d1c63c61d8b';

/// Provider for managing Nafila prayer events and status for today.
///
/// **Validates: Requirements 1.2, 2.1, 2.2**

abstract class _$NafilaNotifier extends $AsyncNotifier<NafilaState> {
  FutureOr<NafilaState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<NafilaState>, NafilaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NafilaState>, NafilaState>,
              AsyncValue<NafilaState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for checking if a specific Nafila type is completed today.

@ProviderFor(isNafilaCompleted)
const isNafilaCompletedProvider = IsNafilaCompletedFamily._();

/// Provider for checking if a specific Nafila type is completed today.

final class IsNafilaCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider for checking if a specific Nafila type is completed today.
  const IsNafilaCompletedProvider._({
    required IsNafilaCompletedFamily super.from,
    required NafilaType super.argument,
  }) : super(
         retry: null,
         name: r'isNafilaCompletedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isNafilaCompletedHash();

  @override
  String toString() {
    return r'isNafilaCompletedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as NafilaType;
    return isNafilaCompleted(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsNafilaCompletedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isNafilaCompletedHash() => r'4342e97bf3e15b2afa70757ac76d25ee82e23460';

/// Provider for checking if a specific Nafila type is completed today.

final class IsNafilaCompletedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, NafilaType> {
  const IsNafilaCompletedFamily._()
    : super(
        retry: null,
        name: r'isNafilaCompletedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for checking if a specific Nafila type is completed today.

  IsNafilaCompletedProvider call(NafilaType type) =>
      IsNafilaCompletedProvider._(argument: type, from: this);

  @override
  String toString() => r'isNafilaCompletedProvider';
}

/// Provider for getting today's events for a specific Nafila type.

@ProviderFor(nafilaEventsForType)
const nafilaEventsForTypeProvider = NafilaEventsForTypeFamily._();

/// Provider for getting today's events for a specific Nafila type.

final class NafilaEventsForTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NafilaEvent>>,
          List<NafilaEvent>,
          FutureOr<List<NafilaEvent>>
        >
    with
        $FutureModifier<List<NafilaEvent>>,
        $FutureProvider<List<NafilaEvent>> {
  /// Provider for getting today's events for a specific Nafila type.
  const NafilaEventsForTypeProvider._({
    required NafilaEventsForTypeFamily super.from,
    required NafilaType super.argument,
  }) : super(
         retry: null,
         name: r'nafilaEventsForTypeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nafilaEventsForTypeHash();

  @override
  String toString() {
    return r'nafilaEventsForTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<NafilaEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NafilaEvent>> create(Ref ref) {
    final argument = this.argument as NafilaType;
    return nafilaEventsForType(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NafilaEventsForTypeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nafilaEventsForTypeHash() =>
    r'cf0cd40a112cc8fcdb2cf54536a4c443daf7c5c5';

/// Provider for getting today's events for a specific Nafila type.

final class NafilaEventsForTypeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<NafilaEvent>>, NafilaType> {
  const NafilaEventsForTypeFamily._()
    : super(
        retry: null,
        name: r'nafilaEventsForTypeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting today's events for a specific Nafila type.

  NafilaEventsForTypeProvider call(NafilaType type) =>
      NafilaEventsForTypeProvider._(argument: type, from: this);

  @override
  String toString() => r'nafilaEventsForTypeProvider';
}

/// Provider for getting total rakats for a specific Nafila type today.

@ProviderFor(nafilaRakatsForType)
const nafilaRakatsForTypeProvider = NafilaRakatsForTypeFamily._();

/// Provider for getting total rakats for a specific Nafila type today.

final class NafilaRakatsForTypeProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for getting total rakats for a specific Nafila type today.
  const NafilaRakatsForTypeProvider._({
    required NafilaRakatsForTypeFamily super.from,
    required NafilaType super.argument,
  }) : super(
         retry: null,
         name: r'nafilaRakatsForTypeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nafilaRakatsForTypeHash();

  @override
  String toString() {
    return r'nafilaRakatsForTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as NafilaType;
    return nafilaRakatsForType(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NafilaRakatsForTypeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nafilaRakatsForTypeHash() =>
    r'bfb235cd3b8354ec898fd254c11e90ae181a7397';

/// Provider for getting total rakats for a specific Nafila type today.

final class NafilaRakatsForTypeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, NafilaType> {
  const NafilaRakatsForTypeFamily._()
    : super(
        retry: null,
        name: r'nafilaRakatsForTypeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting total rakats for a specific Nafila type today.

  NafilaRakatsForTypeProvider call(NafilaType type) =>
      NafilaRakatsForTypeProvider._(argument: type, from: this);

  @override
  String toString() => r'nafilaRakatsForTypeProvider';
}
