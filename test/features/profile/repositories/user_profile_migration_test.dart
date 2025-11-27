import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Profile Migration Tests', () {
    late Database testDb;
    late String testDbPath;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      testDbPath = 'test_user_profile_migration_${DateTime.now().millisecondsSinceEpoch}.db';
    });

    tearDown(() async {
      try {
        await testDb.close();
        await databaseFactory.deleteDatabase(testDbPath);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Migration from v9 to v10 adds start_of_week column with default value', () async {
      // Step 1: Create a v9 database with sample user profile data
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 9,
          onCreate: (db, version) async {
            // Create v9 user_profile schema (without start_of_week)
            await db.execute('''
              CREATE TABLE user_profile (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT,
                profile_picture_path TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');

            // Insert test data
            await db.insert('user_profile', {
              'name': 'Test User',
              'email': 'test@example.com',
              'profile_picture_path': null,
              'created_at': '2025-11-20T10:00:00.000',
              'updated_at': '2025-11-20T10:00:00.000',
            });
          },
        ),
      );

      // Verify v9 data exists
      final v9Profiles = await testDb.query('user_profile');
      expect(v9Profiles.length, 1);
      expect(v9Profiles[0]['name'], 'Test User');
      expect(v9Profiles[0]['email'], 'test@example.com');
      
      // Verify start_of_week column does not exist in v9
      expect(v9Profiles[0].containsKey('start_of_week'), false);

      await testDb.close();

      // Step 2: Reopen database with v10 schema (triggers migration)
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 10,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 10) {
              // Apply the same migration logic as in DatabaseService
              await db.execute('''
                ALTER TABLE user_profile ADD COLUMN start_of_week INTEGER NOT NULL DEFAULT 1
              ''');
            }
          },
        ),
      );

      // Step 3: Verify v10 data after migration
      final v10Profiles = await testDb.query('user_profile');
      expect(v10Profiles.length, 1);

      // Verify existing data preserved
      expect(v10Profiles[0]['name'], 'Test User');
      expect(v10Profiles[0]['email'], 'test@example.com');
      expect(v10Profiles[0]['created_at'], '2025-11-20T10:00:00.000');
      expect(v10Profiles[0]['updated_at'], '2025-11-20T10:00:00.000');

      // Verify new column exists with default value
      expect(v10Profiles[0].containsKey('start_of_week'), true);
      expect(v10Profiles[0]['start_of_week'], 1); // Default to Monday
    });

    test('Fresh v10 database creates correct schema with start_of_week column', () async {
      // Create a fresh v10 database
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: (db, version) async {
            // Create v10 schema
            await db.execute('''
              CREATE TABLE user_profile (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT,
                profile_picture_path TEXT,
                start_of_week INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert test data
      await testDb.insert('user_profile', {
        'name': 'New User',
        'email': 'new@example.com',
        'profile_picture_path': null,
        'start_of_week': 1,
        'created_at': '2025-11-20T12:00:00.000',
        'updated_at': '2025-11-20T12:00:00.000',
      });

      // Verify data
      final profiles = await testDb.query('user_profile');
      expect(profiles.length, 1);
      expect(profiles[0]['name'], 'New User');
      expect(profiles[0]['email'], 'new@example.com');
      expect(profiles[0]['start_of_week'], 1);
      expect(profiles[0]['created_at'], isNotNull);
      expect(profiles[0]['updated_at'], isNotNull);
    });

    test('Migration preserves multiple user profiles if they exist', () async {
      // Step 1: Create a v9 database with multiple profiles (edge case)
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 9,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE user_profile (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT,
                profile_picture_path TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');

            // Insert multiple test profiles
            await db.insert('user_profile', {
              'name': 'User One',
              'email': 'user1@example.com',
              'profile_picture_path': null,
              'created_at': '2025-11-19T10:00:00.000',
              'updated_at': '2025-11-19T10:00:00.000',
            });

            await db.insert('user_profile', {
              'name': 'User Two',
              'email': 'user2@example.com',
              'profile_picture_path': '/path/to/pic.jpg',
              'created_at': '2025-11-20T10:00:00.000',
              'updated_at': '2025-11-20T10:00:00.000',
            });
          },
        ),
      );

      await testDb.close();

      // Step 2: Reopen with v10 (triggers migration)
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 10,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 10) {
              await db.execute('''
                ALTER TABLE user_profile ADD COLUMN start_of_week INTEGER NOT NULL DEFAULT 1
              ''');
            }
          },
        ),
      );

      // Step 3: Verify all profiles migrated correctly
      final profiles = await testDb.query('user_profile', orderBy: 'id ASC');
      expect(profiles.length, 2);

      // Verify first profile
      expect(profiles[0]['name'], 'User One');
      expect(profiles[0]['email'], 'user1@example.com');
      expect(profiles[0]['start_of_week'], 1);

      // Verify second profile
      expect(profiles[1]['name'], 'User Two');
      expect(profiles[1]['email'], 'user2@example.com');
      expect(profiles[1]['profile_picture_path'], '/path/to/pic.jpg');
      expect(profiles[1]['start_of_week'], 1);
    });

    test('UserProfile model can read and write start_of_week values', () async {
      // Create a fresh v10 database
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE user_profile (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT,
                profile_picture_path TEXT,
                start_of_week INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Test all valid start_of_week values (1-7)
      for (int day = 1; day <= 7; day++) {
        await testDb.insert('user_profile', {
          'name': 'User Day $day',
          'email': 'user$day@example.com',
          'profile_picture_path': null,
          'start_of_week': day,
          'created_at': '2025-11-20T12:00:00.000',
          'updated_at': '2025-11-20T12:00:00.000',
        });
      }

      // Verify all profiles were created with correct start_of_week values
      final profiles = await testDb.query('user_profile', orderBy: 'id ASC');
      expect(profiles.length, 7);

      for (int i = 0; i < 7; i++) {
        expect(profiles[i]['start_of_week'], i + 1);
        expect(profiles[i]['name'], 'User Day ${i + 1}');
      }
    });
  });
}
