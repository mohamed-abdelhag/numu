import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database Migration Tests', () {
    late Database testDb;
    late String testDbPath;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      testDbPath = 'test_migration_${DateTime.now().millisecondsSinceEpoch}.db';
    });

    tearDown(() async {
      try {
        await testDb.close();
        await databaseFactory.deleteDatabase(testDbPath);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Migration from v6 to v7 preserves existing task data', () async {
      // Step 1: Create a v6 database with sample data
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 6,
          onCreate: (db, version) async {
            // Create v6 schema
            await db.execute('''
              CREATE TABLE tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                category_id INTEGER
              )
            ''');

            // Insert test data
            await db.insert('tasks', {
              'text': 'Test Task 1',
              'isCompleted': 0,
              'category_id': null,
            });

            await db.insert('tasks', {
              'text': 'Test Task 2',
              'isCompleted': 1,
              'category_id': 1,
            });
          },
        ),
      );

      // Verify v6 data exists
      final v6Tasks = await testDb.query('tasks');
      expect(v6Tasks.length, 2);
      expect(v6Tasks[0]['text'], 'Test Task 1');
      expect(v6Tasks[1]['text'], 'Test Task 2');

      await testDb.close();

      // Step 2: Reopen database with v7 schema (triggers migration)
      testDb = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 7,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 7) {
              // Apply the same migration logic as in DatabaseService
              await db.execute('''
                CREATE TABLE tasks_new (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  title TEXT NOT NULL,
                  description TEXT,
                  due_date TEXT,
                  isCompleted INTEGER NOT NULL DEFAULT 0,
                  category_id INTEGER,
                  created_at TEXT NOT NULL DEFAULT (datetime('now')),
                  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
                )
              ''');

              await db.execute('''
                INSERT INTO tasks_new (id, title, isCompleted, category_id, created_at, updated_at)
                SELECT id, text, isCompleted, category_id, datetime('now'), datetime('now')
                FROM tasks
              ''');

              await db.execute('DROP TABLE tasks');
              await db.execute('ALTER TABLE tasks_new RENAME TO tasks');

              await db.execute('''
                CREATE INDEX idx_tasks_due_date ON tasks (due_date)
              ''');

              await db.execute('''
                CREATE INDEX idx_tasks_category_id ON tasks (category_id)
              ''');
            }
          },
        ),
      );

      // Step 3: Verify v7 data after migration
      final v7Tasks = await testDb.query('tasks');
      expect(v7Tasks.length, 2);

      // Verify 'text' was renamed to 'title'
      expect(v7Tasks[0]['title'], 'Test Task 1');
      expect(v7Tasks[1]['title'], 'Test Task 2');

      // Verify new columns exist
      expect(v7Tasks[0].containsKey('description'), true);
      expect(v7Tasks[0].containsKey('due_date'), true);
      expect(v7Tasks[0].containsKey('created_at'), true);
      expect(v7Tasks[0].containsKey('updated_at'), true);

      // Verify new columns are nullable/have defaults
      expect(v7Tasks[0]['description'], null);
      expect(v7Tasks[0]['due_date'], null);
      expect(v7Tasks[0]['created_at'], isNotNull);
      expect(v7Tasks[0]['updated_at'], isNotNull);

      // Verify existing data preserved
      expect(v7Tasks[0]['isCompleted'], 0);
      expect(v7Tasks[1]['isCompleted'], 1);
      expect(v7Tasks[1]['category_id'], 1);

      // Verify indexes were created
      final indexes = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='tasks'",
      );
      final indexNames = indexes.map((i) => i['name']).toList();
      expect(indexNames.contains('idx_tasks_due_date'), true);
      expect(indexNames.contains('idx_tasks_category_id'), true);
    });

    test('Fresh v7 database creates correct schema', () async {
      // Create a fresh v7 database
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: (db, version) async {
            // Create v7 schema
            await db.execute('''
              CREATE TABLE tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                due_date TEXT,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                category_id INTEGER,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
              )
            ''');

            await db.execute('''
              CREATE INDEX idx_tasks_due_date ON tasks (due_date)
            ''');

            await db.execute('''
              CREATE INDEX idx_tasks_category_id ON tasks (category_id)
            ''');
          },
        ),
      );

      // Insert test data
      await testDb.insert('tasks', {
        'title': 'New Task',
        'description': 'Task description',
        'due_date': '2025-11-20',
        'isCompleted': 0,
        'category_id': null,
      });

      // Verify data
      final tasks = await testDb.query('tasks');
      expect(tasks.length, 1);
      expect(tasks[0]['title'], 'New Task');
      expect(tasks[0]['description'], 'Task description');
      expect(tasks[0]['due_date'], '2025-11-20');
      expect(tasks[0]['created_at'], isNotNull);
      expect(tasks[0]['updated_at'], isNotNull);
    });
  });
}
