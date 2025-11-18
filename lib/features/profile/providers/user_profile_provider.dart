import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_profile.dart' as model;
import '../repositories/user_profile_repository.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'user_profile_provider.g.dart';

/// Provider for DatabaseService instance
@riverpod
DatabaseService databaseService(Ref ref) {
  return DatabaseService.instance;
}

/// Provider for UserProfileRepository
@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  final db = ref.watch(databaseServiceProvider);
  return UserProfileRepository(db);
}

/// Provider for managing user profile state
/// Handles loading, creating, and updating user profile
@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  late final UserProfileRepository _repository;

  @override
  Future<model.UserProfile?> build() async {
    _repository = ref.read(userProfileRepositoryProvider);
    
    try {
      final profile = await _repository.getProfile();
      CoreLoggingUtility.info(
        'UserProfileProvider',
        'build',
        profile != null 
          ? 'Successfully loaded user profile: ${profile.name}'
          : 'No user profile found',
      );
      return profile;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'UserProfileProvider',
        'build',
        'Failed to load user profile: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Create a new user profile
  Future<void> createProfile(model.UserProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final createdProfile = await _repository.createProfile(profile);
        CoreLoggingUtility.info(
          'UserProfileProvider',
          'createProfile',
          'Successfully created user profile: ${createdProfile.name}',
        );
        return createdProfile;
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'UserProfileProvider',
          'createProfile',
          'Failed to create user profile: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Update an existing user profile
  Future<void> updateProfile(model.UserProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.updateProfile(profile);
        CoreLoggingUtility.info(
          'UserProfileProvider',
          'updateProfile',
          'Successfully updated user profile: ${profile.name}',
        );
        // Return the updated profile
        return profile;
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'UserProfileProvider',
          'updateProfile',
          'Failed to update user profile: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Delete the user profile
  Future<void> deleteProfile(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.deleteProfile(id);
        CoreLoggingUtility.info(
          'UserProfileProvider',
          'deleteProfile',
          'Successfully deleted user profile with ID: $id',
        );
        return null;
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'UserProfileProvider',
          'deleteProfile',
          'Failed to delete user profile: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }
}
