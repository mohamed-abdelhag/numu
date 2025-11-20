import 'package:numu/core/services/database_service.dart';
import 'package:numu/features/settings/models/user_profile.dart';

class UserProfileRepository {
  final DatabaseService _db;

  UserProfileRepository(this._db);

  /// Fetch the user profile (singleton - only one profile exists)
  Future<UserProfile?> getProfile() async {
    try {
      final database = await _db.database;
      final results = await database.query(
        DatabaseService.userProfileTable,
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return UserProfile.fromMap(results.first);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Create a new user profile
  /// Ensures only one profile exists by checking first
  Future<UserProfile> createProfile(UserProfile profile) async {
    try {
      final database = await _db.database;

      // Check if a profile already exists
      final existing = await getProfile();
      if (existing != null) {
        throw Exception('A user profile already exists. Use updateProfile() to modify it.');
      }

      final id = await database.insert(
        DatabaseService.userProfileTable,
        profile.toMap(),
      );

      return profile.copyWith(id: id);
    } catch (e) {
      if (e.toString().contains('already exists')) {
        rethrow;
      }
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Update an existing user profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      final database = await _db.database;

      if (profile.id == null) {
        throw Exception('Cannot update profile without an id');
      }

      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      final rowsAffected = await database.update(
        DatabaseService.userProfileTable,
        updatedProfile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );

      if (rowsAffected == 0) {
        throw Exception('Profile not found with id: ${profile.id}');
      }
    } catch (e) {
      if (e.toString().contains('Cannot update') || e.toString().contains('not found')) {
        rethrow;
      }
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Delete a user profile by id
  Future<void> deleteProfile(int id) async {
    try {
      final database = await _db.database;

      final rowsAffected = await database.delete(
        DatabaseService.userProfileTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw Exception('Profile not found with id: $id');
      }
    } catch (e) {
      if (e.toString().contains('not found')) {
        rethrow;
      }
      throw Exception('Failed to delete user profile: $e');
    }
  }
}
