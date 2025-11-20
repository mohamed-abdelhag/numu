// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for DatabaseService instance

@ProviderFor(databaseService)
const databaseServiceProvider = DatabaseServiceProvider._();

/// Provider for DatabaseService instance

final class DatabaseServiceProvider
    extends
        $FunctionalProvider<DatabaseService, DatabaseService, DatabaseService>
    with $Provider<DatabaseService> {
  /// Provider for DatabaseService instance
  const DatabaseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseServiceHash();

  @$internal
  @override
  $ProviderElement<DatabaseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseService create(Ref ref) {
    return databaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseService>(value),
    );
  }
}

String _$databaseServiceHash() => r'59eee919c01b00fdf56c694367d3db2529a4e2fd';

/// Provider for UserProfileRepository

@ProviderFor(userProfileRepository)
const userProfileRepositoryProvider = UserProfileRepositoryProvider._();

/// Provider for UserProfileRepository

final class UserProfileRepositoryProvider
    extends
        $FunctionalProvider<
          UserProfileRepository,
          UserProfileRepository,
          UserProfileRepository
        >
    with $Provider<UserProfileRepository> {
  /// Provider for UserProfileRepository
  const UserProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileRepository create(Ref ref) {
    return userProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileRepository>(value),
    );
  }
}

String _$userProfileRepositoryHash() =>
    r'856642e60bda517a4a20e2842749d781987b3b6e';

/// Provider for managing user profile state
/// Handles loading, creating, and updating user profile

@ProviderFor(UserProfileNotifier)
const userProfileProvider = UserProfileNotifierProvider._();

/// Provider for managing user profile state
/// Handles loading, creating, and updating user profile
final class UserProfileNotifierProvider
    extends $AsyncNotifierProvider<UserProfileNotifier, model.UserProfile?> {
  /// Provider for managing user profile state
  /// Handles loading, creating, and updating user profile
  const UserProfileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileNotifierHash();

  @$internal
  @override
  UserProfileNotifier create() => UserProfileNotifier();
}

String _$userProfileNotifierHash() =>
    r'd41b7991d6ec6294372c871353cc19a78903280f';

/// Provider for managing user profile state
/// Handles loading, creating, and updating user profile

abstract class _$UserProfileNotifier
    extends $AsyncNotifier<model.UserProfile?> {
  FutureOr<model.UserProfile?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<model.UserProfile?>, model.UserProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<model.UserProfile?>, model.UserProfile?>,
              AsyncValue<model.UserProfile?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
