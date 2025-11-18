// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_cards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for TutorialCardsRepository

@ProviderFor(tutorialCardsRepository)
const tutorialCardsRepositoryProvider = TutorialCardsRepositoryProvider._();

/// Provider for TutorialCardsRepository

final class TutorialCardsRepositoryProvider
    extends
        $FunctionalProvider<
          TutorialCardsRepository,
          TutorialCardsRepository,
          TutorialCardsRepository
        >
    with $Provider<TutorialCardsRepository> {
  /// Provider for TutorialCardsRepository
  const TutorialCardsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialCardsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialCardsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TutorialCardsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TutorialCardsRepository create(Ref ref) {
    return tutorialCardsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TutorialCardsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TutorialCardsRepository>(value),
    );
  }
}

String _$tutorialCardsRepositoryHash() =>
    r'231c56955ce496f756d5f1aed0c5db8b337795b1';

/// Provider for fetching all tutorial cards
/// Returns a list of tutorial cards ordered by sort_order

@ProviderFor(tutorialCards)
const tutorialCardsProvider = TutorialCardsProvider._();

/// Provider for fetching all tutorial cards
/// Returns a list of tutorial cards ordered by sort_order

final class TutorialCardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TutorialCardModel>>,
          List<TutorialCardModel>,
          FutureOr<List<TutorialCardModel>>
        >
    with
        $FutureModifier<List<TutorialCardModel>>,
        $FutureProvider<List<TutorialCardModel>> {
  /// Provider for fetching all tutorial cards
  /// Returns a list of tutorial cards ordered by sort_order
  const TutorialCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialCardsHash();

  @$internal
  @override
  $FutureProviderElement<List<TutorialCardModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TutorialCardModel>> create(Ref ref) {
    return tutorialCards(ref);
  }
}

String _$tutorialCardsHash() => r'324917bce64e532db745d46d5fc96c01b156d60a';

/// Provider for fetching a specific tutorial card by ID

@ProviderFor(tutorialCardById)
const tutorialCardByIdProvider = TutorialCardByIdFamily._();

/// Provider for fetching a specific tutorial card by ID

final class TutorialCardByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<TutorialCardModel?>,
          TutorialCardModel?,
          FutureOr<TutorialCardModel?>
        >
    with
        $FutureModifier<TutorialCardModel?>,
        $FutureProvider<TutorialCardModel?> {
  /// Provider for fetching a specific tutorial card by ID
  const TutorialCardByIdProvider._({
    required TutorialCardByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tutorialCardByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tutorialCardByIdHash();

  @override
  String toString() {
    return r'tutorialCardByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TutorialCardModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TutorialCardModel?> create(Ref ref) {
    final argument = this.argument as String;
    return tutorialCardById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TutorialCardByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tutorialCardByIdHash() => r'fde67ebe035ac41700cc135b6cf2ba1a6d7e34f1';

/// Provider for fetching a specific tutorial card by ID

final class TutorialCardByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TutorialCardModel?>, String> {
  const TutorialCardByIdFamily._()
    : super(
        retry: null,
        name: r'tutorialCardByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for fetching a specific tutorial card by ID

  TutorialCardByIdProvider call(String id) =>
      TutorialCardByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'tutorialCardByIdProvider';
}

/// Notifier for managing tutorial cards state
/// Handles CRUD operations with automatic state refresh

@ProviderFor(TutorialCardsNotifier)
const tutorialCardsProvider = TutorialCardsNotifierProvider._();

/// Notifier for managing tutorial cards state
/// Handles CRUD operations with automatic state refresh
final class TutorialCardsNotifierProvider
    extends
        $AsyncNotifierProvider<TutorialCardsNotifier, List<TutorialCardModel>> {
  /// Notifier for managing tutorial cards state
  /// Handles CRUD operations with automatic state refresh
  const TutorialCardsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialCardsNotifierHash();

  @$internal
  @override
  TutorialCardsNotifier create() => TutorialCardsNotifier();
}

String _$tutorialCardsNotifierHash() =>
    r'a10cb5048c3d0704e72525d935ca2688362690ff';

/// Notifier for managing tutorial cards state
/// Handles CRUD operations with automatic state refresh

abstract class _$TutorialCardsNotifier
    extends $AsyncNotifier<List<TutorialCardModel>> {
  FutureOr<List<TutorialCardModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<TutorialCardModel>>,
              List<TutorialCardModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TutorialCardModel>>,
                List<TutorialCardModel>
              >,
              AsyncValue<List<TutorialCardModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
