import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Timed to Binary Habit Migration Tests', () {
    late Database testDb;
    late String testDbPath;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      testDbPath = 'test_timed_migration_${DateTime.now().millisecondsSinceEpoch}.db';
    });

    tearDown(() async {
      try {
        await testDb.close();
        await databaseFactory.deleteDatabase(testDbPath);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Migration converts timed habits to binary with time window enabled', () async {
      // Step 1: Create a v7 database with timed habits
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: (db, version) async {
            // Create v7 habits table schema
            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category_id INTEGER,
                icon TEXT NOT NULL,
                color TEXT NOT NULL,
                tracking_type TEXT NOT NULL,
                goal_type TEXT NOT NULL,
                target_value REAL,
                unit TEXT,
                frequency TEXT NOT NULL,
                custom_period_days INTEGER,
                period_start_date TEXT,
                active_days_mode TEXT NOT NULL,
                active_weekdays TEXT,
                require_mode TEXT NOT NULL,
                time_window_enabled INTEGER NOT NULL DEFAULT 0,
                time_window_start TEXT,
                time_window_end TEXT,
                time_window_mode TEXT,
                quality_layer_enabled INTEGER NOT NULL DEFAULT 0,
                quality_layer_label TEXT,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_template INTEGER NOT NULL DEFAULT 0,
                sort_order INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT
              )
            ''');

            // Insert test timed habits with various configurations
            await db.insert('habits', {
              'name': 'Morning Meditation',
              'description': 'Meditate for 10 minutes',
              'icon': 'self_improvement',
              'color': '#4CAF50',
              'tracking_type': 'timed',
              'goal_type': 'none',
              'frequency': 'daily',
              'active_days_mode': 'all',
              'require_mode': 'all',
              'time_window_enabled': 1,
              'time_window_start': '06:00',
              'time_window_end': '09:00',
              'time_window_mode': 'require',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            await db.insert('habits', {
              'name': 'Evening Walk',
              'description': 'Walk for 30 minutes',
              'icon': 'directions_walk',
              'color': '#2196F3',
              'tracking_type': 'timed',
              'goal_type': 'none',
              'frequency': 'daily',
              'active_days_mode': 'all',
              'require_mode': 'all',
              'time_window_enabled': 1,
              'time_window_start': '18:00',
              'time_window_end': '21:00',
              'time_window_mode': 'optional',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            // Insert a binary habit to ensure it's not affected
            await db.insert('habits', {
              'name': 'Drink Water',
              'description': 'Stay hydrated',
              'icon': 'local_drink',
              'color': '#03A9F4',
              'tracking_type': 'binary',
              'goal_type': 'none',
              'frequency': 'daily',
              'active_days_mode': 'all',
              'require_mode': 'all',
              'time_window_enabled': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            // Insert a value habit to ensure it's not affected
            await db.insert('habits', {
              'name': 'Read Pages',
              'description': 'Read daily',
              'icon': 'menu_book',
              'color': '#FF9800',
              'tracking_type': 'value',
              'goal_type': 'minimum',
              'target_value': 10.0,
              'unit': 'pages',
              'frequency': 'daily',
              'active_days_mode': 'all',
              'require_mode': 'all',
              'time_window_enabled': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          },
        ),
      );

      // Verify v7 data exists with timed tracking type
      final v7Habits = await testDb.query('habits');
      expect(v7Habits.length, 4);
      
      final timedHabits = v7Habits.where((h) => h['tracking_type'] == 'timed').toList();
      expect(timedHabits.length, 2);
      expect(timedHabits[0]['name'], 'Morning Meditation');
      expect(timedHabits[0]['time_window_enabled'], 1);
      expect(timedHabits[0]['time_window_start'], '06:00');
      expect(timedHabits[0]['time_window_end'], '09:00');
      expect(timedHabits[0]['time_window_mode'], 'require');
      
      expect(timedHabits[1]['name'], 'Evening Walk');
      expect(timedHabits[1]['time_window_enabled'], 1);
      expect(timedHabits[1]['time_window_start'], '18:00');
      expect(timedHabits[1]['time_window_end'], '21:00');
      expect(timedHabits[1]['time_window_mode'], 'optional');

      await testDb.close();

      // Step 2: Reopen database with v8 schema (triggers migration)
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 8) {
              // Apply the migration logic to convert timed habits to binary
              await db.execute('''
                UPDATE habits 
                SET tracking_type = 'binary',
                    time_window_enabled = 1
                WHERE tracking_type = 'timed'
              ''');
            }
          },
        ),
      );

      // Step 3: Verify v8 data after migration
      final v8Habits = await testDb.query('habits');
      expect(v8Habits.length, 4);

      // Verify no habits remain with timed tracking type
      final remainingTimedHabits = v8Habits.where((h) => h['tracking_type'] == 'timed').toList();
      expect(remainingTimedHabits.length, 0, reason: 'No habits should have timed tracking type after migration');

      // Verify timed habits were converted to binary
      final convertedHabits = v8Habits.where((h) => 
        h['name'] == 'Morning Meditation' || h['name'] == 'Evening Walk'
      ).toList();
      expect(convertedHabits.length, 2);

      for (final habit in convertedHabits) {
        expect(habit['tracking_type'], 'binary', 
          reason: 'Timed habits should be converted to binary');
        expect(habit['time_window_enabled'], 1, 
          reason: 'Time window should remain enabled after migration');
      }

      // Verify time window configuration is preserved for Morning Meditation
      final morningMeditation = v8Habits.firstWhere((h) => h['name'] == 'Morning Meditation');
      expect(morningMeditation['tracking_type'], 'binary');
      expect(morningMeditation['time_window_enabled'], 1);
      expect(morningMeditation['time_window_start'], '06:00');
      expect(morningMeditation['time_window_end'], '09:00');
      expect(morningMeditation['time_window_mode'], 'require');

      // Verify time window configuration is preserved for Evening Walk
      final eveningWalk = v8Habits.firstWhere((h) => h['name'] == 'Evening Walk');
      expect(eveningWalk['tracking_type'], 'binary');
      expect(eveningWalk['time_window_enabled'], 1);
      expect(eveningWalk['time_window_start'], '18:00');
      expect(eveningWalk['time_window_end'], '21:00');
      expect(eveningWalk['time_window_mode'], 'optional');

      // Verify binary habit was not affected
      final drinkWater = v8Habits.firstWhere((h) => h['name'] == 'Drink Water');
      expect(drinkWater['tracking_type'], 'binary');
      expect(drinkWater['time_window_enabled'], 0);

      // Verify value habit was not affected
      final readPages = v8Habits.firstWhere((h) => h['name'] == 'Read Pages');
      expect(readPages['tracking_type'], 'value');
      expect(readPages['goal_type'], 'minimum');
      expect(readPages['target_value'], 10.0);
      expect(readPages['unit'], 'pages');
      expect(readPages['time_window_enabled'], 0);
    });

    test('Migration handles timed habits without time window configuration', () async {
      // Step 1: Create a v7 database with timed habit that has no time window
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category_id INTEGER,
                icon TEXT NOT NULL,
                color TEXT NOT NULL,
                tracking_type TEXT NOT NULL,
                goal_type TEXT NOT NULL,
                target_value REAL,
                unit TEXT,
                frequency TEXT NOT NULL,
                custom_period_days INTEGER,
                period_start_date TEXT,
                active_days_mode TEXT NOT NULL,
                active_weekdays TEXT,
                require_mode TEXT NOT NULL,
                time_window_enabled INTEGER NOT NULL DEFAULT 0,
                time_window_start TEXT,
                time_window_end TEXT,
                time_window_mode TEXT,
                quality_layer_enabled INTEGER NOT NULL DEFAULT 0,
                quality_layer_label TEXT,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_template INTEGER NOT NULL DEFAULT 0,
                sort_order INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT
              )
            ''');

            // Insert timed habit with time_window_enabled = 0
            await db.insert('habits', {
              'name': 'Yoga Session',
              'description': 'Practice yoga',
              'icon': 'self_improvement',
              'color': '#9C27B0',
              'tracking_type': 'timed',
              'goal_type': 'none',
              'frequency': 'daily',
              'active_days_mode': 'all',
              'require_mode': 'all',
              'time_window_enabled': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          },
        ),
      );

      // Verify initial state
      final v7Habits = await testDb.query('habits');
      expect(v7Habits.length, 1);
      expect(v7Habits[0]['tracking_type'], 'timed');
      expect(v7Habits[0]['time_window_enabled'], 0);

      await testDb.close();

      // Step 2: Run migration
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 8) {
              await db.execute('''
                UPDATE habits 
                SET tracking_type = 'binary',
                    time_window_enabled = 1
                WHERE tracking_type = 'timed'
              ''');
            }
          },
        ),
      );

      // Step 3: Verify migration result
      final v8Habits = await testDb.query('habits');
      expect(v8Habits.length, 1);
      expect(v8Habits[0]['tracking_type'], 'binary');
      expect(v8Habits[0]['time_window_enabled'], 1, 
        reason: 'Migration should enable time window even if it was disabled');
    });

    test('Migration handles empty database', () async {
      // Step 1: Create empty v7 database
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category_id INTEGER,
                icon TEXT NOT NULL,
                color TEXT NOT NULL,
                tracking_type TEXT NOT NULL,
                goal_type TEXT NOT NULL,
                target_value REAL,
                unit TEXT,
                frequency TEXT NOT NULL,
                custom_period_days INTEGER,
                period_start_date TEXT,
                active_days_mode TEXT NOT NULL,
                active_weekdays TEXT,
                require_mode TEXT NOT NULL,
                time_window_enabled INTEGER NOT NULL DEFAULT 0,
                time_window_start TEXT,
                time_window_end TEXT,
                time_window_mode TEXT,
                quality_layer_enabled INTEGER NOT NULL DEFAULT 0,
                quality_layer_label TEXT,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_template INTEGER NOT NULL DEFAULT 0,
                sort_order INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT
              )
            ''');
          },
        ),
      );

      // Verify empty database
      final v7Habits = await testDb.query('habits');
      expect(v7Habits.length, 0);

      await testDb.close();

      // Step 2: Run migration on empty database
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 8) {
              await db.execute('''
                UPDATE habits 
                SET tracking_type = 'binary',
                    time_window_enabled = 1
                WHERE tracking_type = 'timed'
              ''');
            }
          },
        ),
      );

      // Step 3: Verify database is still empty and migration didn't cause errors
      final v8Habits = await testDb.query('habits');
      expect(v8Habits.length, 0);
    });
  });
}
