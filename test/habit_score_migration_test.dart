import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Habit Score Database Migration Tests', () {
    late Database testDb;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    tearDown(() async {
      if (testDb.isOpen) {
        await testDb.close();
      }
    });

    test('habit_scores table is created with correct schema', () async {
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create habits table first (for foreign key)
            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');

            // Create habit_scores table
            await db.execute('''
              CREATE TABLE habit_scores (
                habit_id INTEGER PRIMARY KEY,
                score REAL NOT NULL DEFAULT 0.0,
                calculated_at TEXT NOT NULL,
                last_event_date TEXT,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      // Verify table exists
      final tables = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='habit_scores'",
      );
      expect(tables.length, equals(1));

      // Verify columns exist by inserting and retrieving data
      await testDb.insert('habits', {
        'name': 'Test Habit',
        'created_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('habit_scores', {
        'habit_id': 1,
        'score': 0.75,
        'calculated_at': DateTime.now().toIso8601String(),
        'last_event_date': DateTime.now().toIso8601String(),
      });

      final scores = await testDb.query('habit_scores');
      expect(scores.length, equals(1));
      expect(scores.first['habit_id'], equals(1));
      expect(scores.first['score'], equals(0.75));
      expect(scores.first['calculated_at'], isNotNull);
      expect(scores.first['last_event_date'], isNotNull);
    });

    test('habit_scores allows null last_event_date', () async {
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');

            await db.execute('''
              CREATE TABLE habit_scores (
                habit_id INTEGER PRIMARY KEY,
                score REAL NOT NULL DEFAULT 0.0,
                calculated_at TEXT NOT NULL,
                last_event_date TEXT,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      await testDb.insert('habits', {
        'name': 'Test Habit',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert score without last_event_date
      await testDb.insert('habit_scores', {
        'habit_id': 1,
        'score': 0.0,
        'calculated_at': DateTime.now().toIso8601String(),
      });

      final scores = await testDb.query('habit_scores');
      expect(scores.length, equals(1));
      expect(scores.first['last_event_date'], isNull);
    });

    test('habit_scores cascade deletes when habit is deleted', () async {
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Enable foreign keys
            await db.execute('PRAGMA foreign_keys = ON');

            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');

            await db.execute('''
              CREATE TABLE habit_scores (
                habit_id INTEGER PRIMARY KEY,
                score REAL NOT NULL DEFAULT 0.0,
                calculated_at TEXT NOT NULL,
                last_event_date TEXT,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      // Enable foreign keys for this connection
      await testDb.execute('PRAGMA foreign_keys = ON');

      // Create habit and score
      await testDb.insert('habits', {
        'name': 'Test Habit',
        'created_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('habit_scores', {
        'habit_id': 1,
        'score': 0.5,
        'calculated_at': DateTime.now().toIso8601String(),
      });

      // Verify score exists
      var scores = await testDb.query('habit_scores');
      expect(scores.length, equals(1));

      // Delete habit
      await testDb.delete('habits', where: 'habit_id = ?', whereArgs: [1]);

      // Verify score is cascade deleted
      scores = await testDb.query('habit_scores');
      expect(scores.length, equals(0));
    });
  });
}
