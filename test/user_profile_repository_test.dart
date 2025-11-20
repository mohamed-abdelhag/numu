import 'package:flutter_test/flutter_test.dart';
import 'package:numu/core/services/database_service.dart';
import 'package:numu/features/settings/models/user_profile.dart';
import 'package:numu/features/settings/repositories/user_profile_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileRepository with start_of_week', () {
    late DatabaseService dbService;
    late UserProfileRepository repository;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      dbService = DatabaseService.instance;
      repository = UserProfileRepository(dbService);
    });

    tearDown(() async {
      try {
        final db = await dbService.database;
        await db.delete('user_profile');
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Create profile with default start_of_week', () async {
      final profile = UserProfile(
        name: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createProfile(profile);
      expect(created.id, isNotNull);
      expect(created.startOfWeek, 1); // Default to Monday

      final fetched = await repository.getProfile();
      expect(fetched, isNotNull);
      expect(fetched!.startOfWeek, 1);
    });

    test('Create profile with custom start_of_week', () async {
      final profile = UserProfile(
        name: 'Test User',
        email: 'test@example.com',
        startOfWeek: 7, // Sunday
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createProfile(profile);
      expect(created.startOfWeek, 7);

      final fetched = await repository.getProfile();
      expect(fetched!.startOfWeek, 7);
    });

    test('Update profile start_of_week', () async {
      // Create initial profile
      final profile = UserProfile(
        name: 'Test User',
        email: 'test@example.com',
        startOfWeek: 1, // Monday
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createProfile(profile);

      // Update to Sunday
      final updated = created.copyWith(startOfWeek: 7);
      await repository.updateProfile(updated);

      final fetched = await repository.getProfile();
      expect(fetched!.startOfWeek, 7);
    });

    test('Profile toMap and fromMap handle start_of_week', () async {
      final profile = UserProfile(
        name: 'Test User',
        email: 'test@example.com',
        startOfWeek: 3, // Wednesday
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = profile.toMap();
      expect(map['start_of_week'], 3);

      final fromMap = UserProfile.fromMap(map);
      expect(fromMap.startOfWeek, 3);
    });

    test('Profile fromMap defaults to Monday when start_of_week is null', () async {
      final map = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'profile_picture_path': null,
        // start_of_week is missing
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profile = UserProfile.fromMap(map);
      expect(profile.startOfWeek, 1); // Should default to Monday
    });
  });
}
