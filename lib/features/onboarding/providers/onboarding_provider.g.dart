// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for SharedPreferences instance

@ProviderFor(sharedPreferences)
const sharedPreferencesProvider = SharedPreferencesProvider._();

/// Provider for SharedPreferences instance

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  /// Provider for SharedPreferences instance
  const SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'dc403fbb1d968c7d5ab4ae1721a29ffe173701c7';

/// Provider for OnboardingRepository

@ProviderFor(onboardingRepository)
const onboardingRepositoryProvider = OnboardingRepositoryProvider._();

/// Provider for OnboardingRepository

final class OnboardingRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<OnboardingRepository>,
          OnboardingRepository,
          FutureOr<OnboardingRepository>
        >
    with
        $FutureModifier<OnboardingRepository>,
        $FutureProvider<OnboardingRepository> {
  /// Provider for OnboardingRepository
  const OnboardingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<OnboardingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OnboardingRepository> create(Ref ref) {
    return onboardingRepository(ref);
  }
}

String _$onboardingRepositoryHash() =>
    r'42d7fc634480ec8093c0cc715eb9ce2ff089fc0a';

/// Provider for checking onboarding completion status
/// Returns true if onboarding has been completed, false otherwise
/// Fails gracefully by returning false if SharedPreferences is unavailable

@ProviderFor(onboardingCompleted)
const onboardingCompletedProvider = OnboardingCompletedProvider._();

/// Provider for checking onboarding completion status
/// Returns true if onboarding has been completed, false otherwise
/// Fails gracefully by returning false if SharedPreferences is unavailable

final class OnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider for checking onboarding completion status
  /// Returns true if onboarding has been completed, false otherwise
  /// Fails gracefully by returning false if SharedPreferences is unavailable
  const OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return onboardingCompleted(ref);
  }
}

String _$onboardingCompletedHash() =>
    r'1d8b296e877a684599425ac4ac35f8227581b1ed';

/// Provider for full onboarding state including completion date
/// Fails gracefully by returning incomplete state if SharedPreferences is unavailable

@ProviderFor(onboardingState)
const onboardingStateProvider = OnboardingStateProvider._();

/// Provider for full onboarding state including completion date
/// Fails gracefully by returning incomplete state if SharedPreferences is unavailable

final class OnboardingStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<OnboardingState>,
          OnboardingState,
          FutureOr<OnboardingState>
        >
    with $FutureModifier<OnboardingState>, $FutureProvider<OnboardingState> {
  /// Provider for full onboarding state including completion date
  /// Fails gracefully by returning incomplete state if SharedPreferences is unavailable
  const OnboardingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStateHash();

  @$internal
  @override
  $FutureProviderElement<OnboardingState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OnboardingState> create(Ref ref) {
    return onboardingState(ref);
  }
}

String _$onboardingStateHash() => r'aa26a210ab4b5755b0da8c6842cfb924ae946b55';

/// Notifier for managing onboarding state changes

@ProviderFor(OnboardingNotifier)
const onboardingProvider = OnboardingNotifierProvider._();

/// Notifier for managing onboarding state changes
final class OnboardingNotifierProvider
    extends $AsyncNotifierProvider<OnboardingNotifier, OnboardingState> {
  /// Notifier for managing onboarding state changes
  const OnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingNotifierHash();

  @$internal
  @override
  OnboardingNotifier create() => OnboardingNotifier();
}

String _$onboardingNotifierHash() =>
    r'6056ad79c5b0650ec75c5f4f2cd6461120e99417';

/// Notifier for managing onboarding state changes

abstract class _$OnboardingNotifier extends $AsyncNotifier<OnboardingState> {
  FutureOr<OnboardingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<OnboardingState>, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingState>, OnboardingState>,
              AsyncValue<OnboardingState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
