import 'package:numu/core/services/database_service.dart';
import 'package:numu/features/profile/models/user_profile.dart';

class UserProfileRepository {
  final DatabaseService _db;

  UserProfileRepository(this._db);

  /// Fetch the user profile (singleton - only one profile exists)
  Future<UserProfile?> getProfile() async {
    final database = await _db.database;
    final results = await database.query(
      DatabaseService.userProfileTable,
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(results.first);
  }

  /// Create a new user profile
  /// Ensures only one profile exists by checking first
  Future<UserProfile> createProfile(UserProfile profile) async {
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
  }

  /// Update an existing user profile
  Future<void> updateProfile(UserProfile profile) async {
    final database = await _db.database;

    if (profile.id == null) {
      throw Exception('Cannot update profile without an id');
    }

    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );

    await database.update(
      DatabaseService.userProfileTable,
      updatedProfile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Delete a user profile by id
  Future<void> deleteProfile(int id) async {
    final database = await _db.database;

    await database.delete(
      DatabaseService.userProfileTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
