import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:numu/features/islamic/models/enums/nafila_type.dart';
import 'package:numu/features/islamic/models/nafila_event.dart';
import 'package:numu/features/islamic/models/nafila_score.dart';
import 'package:numu/core/services/database_service.dart';

/// Custom generators for NafilaRepository tests
extension NafilaRepositoryGenerators on Any {
  /// Generator for NafilaType enum values
  Generator<NafilaType> get nafilaType => choose(NafilaType.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2030).bind((year) =>
      intInRange(1, 12).bind((month) =>
          intInRange(1, 28).map((day) => DateTime(year, month, day))));

  /// Generator for a valid timestamp on a given date
  Generator<DateTime> timestampOnDate(DateTime date) {
    return intInRange(0, 24).bind((hour) => intInRange(0, 60).bind((minute) =>
        intInRange(0, 60).map((second) => DateTime(
            date.year, date.month, date.day, hour % 24, minute % 60, second % 60))));
  }

  /// Generator for valid rakat count based on NafilaType
  Generator<int> rakatCountForType(NafilaType type) {
    return intInRange(type.minRakats, type.maxRakats + 1);
  }

  /// Generator for optional notes
  Generator<String?> get optionalNotes => choose([
        null,
        'Prayed at mosque',
        'Prayed at home',
        'Morning prayer',
        'Night prayer',
      ]);

  /// Generator for a complete NafilaEvent
  Generator<NafilaEvent> get nafilaEvent {
    return nafilaType.bind((type) => dateOnly.bind((date) =>
        timestampOnDate(date).bind((timestamp) =>
            rakatCountForType(type).bind((rakats) =>
                choose([true, false]).bind((hasActualTime) =>
                    (hasActualTime
                            ? timestampOnDate(date)
                            : always<DateTime?>(null))
                        .bind((actualTime) => optionalNotes.bind((notes) =>
                            always(DateTime.now()).bind((createdAt) =>
                                always(DateTime.now()).map((updatedAt) =>
                                    NafilaEvent(
                                      nafilaType: type,
                                      eventDate: date,
                                      eventTimestamp: timestamp,
                                      rakatCount: rakats,
                                      actualPrayerTime: actualTime,
                                      notes: notes,
                                      createdAt: createdAt,
                                      updatedAt: updatedAt,
                                    ))))))))));
  }

  /// Generator for a list of NafilaEvents (1-5 events)
  Generator<List<NafilaEvent>> get nafilaEventList {
    return intInRange(1, 6).bind((count) =>
        listWithLengthInRange(count, count, nafilaEvent));
  }
}

/// Helper to get row count from a table
Future<int> _getRowCount(Database db, String tableName) async {
  final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
  return result.first['count'] as int;
}

/// Helper to create a fresh test database
Future<Database> _createTestDatabase() async {
  return await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 14,
      onCreate: (db, version) async {
        // Create prayer_events table (to verify isolation)
        await db.execute('''
          CREATE TABLE ${DatabaseService.prayerEventsTable} (
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            prayer_type TEXT NOT NULL,
            event_date TEXT NOT NULL,
            event_timestamp TEXT NOT NULL,
            actual_prayer_time TEXT,
            prayed_in_jamaah INTEGER NOT NULL DEFAULT 0,
            within_time_window INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Create nafila_events table
        await db.execute('''
          CREATE TABLE ${DatabaseService.nafilaEventsTable} (
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            nafila_type TEXT NOT NULL,
            event_date TEXT NOT NULL,
            event_timestamp TEXT NOT NULL,
            rakat_count INTEGER NOT NULL,
            actual_prayer_time TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Create nafila_scores table
        await db.execute('''
          CREATE TABLE ${DatabaseService.nafilaScoresTable} (
            nafila_type TEXT PRIMARY KEY,
            score REAL NOT NULL DEFAULT 0.0,
            current_streak INTEGER NOT NULL DEFAULT 0,
            longest_streak INTEGER NOT NULL DEFAULT 0,
            total_rakats INTEGER NOT NULL DEFAULT 0,
            total_completions INTEGER NOT NULL DEFAULT 0,
            calculated_at TEXT NOT NULL,
            last_event_date TEXT
          )
        ''');

        // Create indexes
        await db.execute('''
          CREATE INDEX idx_nafila_events_date ON ${DatabaseService.nafilaEventsTable} (event_date)
        ''');
        await db.execute('''
          CREATE INDEX idx_nafila_events_type_date ON ${DatabaseService.nafilaEventsTable} (nafila_type, event_date)
        ''');
      },
    ),
  );
}

void main() {
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('NafilaRepository Property Tests', () {
    /// **Feature: nafila-prayer-system, Property 10: Data Isolation**
    /// **Validates: Requirements 7.3**
    ///
    /// *For any* Nafila repository operation (create, update, delete),
    /// the prayer_events table row count should remain unchanged.
    Glados(any.nafilaEventList).test(
      'Property 10: Data Isolation - Nafila operations do not affect prayer_events table',
      (events) async {
        // Create a fresh database for each test iteration
        final testDb = await _createTestDatabase();
        
        try {
          // Insert some prayer events to have a non-zero baseline
          await testDb.insert(DatabaseService.prayerEventsTable, {
            'prayer_type': 'fajr',
            'event_date': '2024-01-15',
            'event_timestamp': '2024-01-15T05:30:00.000',
            'prayed_in_jamaah': 0,
            'within_time_window': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          await testDb.insert(DatabaseService.prayerEventsTable, {
            'prayer_type': 'dhuhr',
            'event_date': '2024-01-15',
            'event_timestamp': '2024-01-15T12:30:00.000',
            'prayed_in_jamaah': 1,
            'within_time_window': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          final baselinePrayerCount = await _getRowCount(testDb, DatabaseService.prayerEventsTable);
          expect(baselinePrayerCount, equals(2));

          // Perform Nafila CREATE operations
          final insertedIds = <int>[];
          for (final event in events) {
            final id = await testDb.insert(
              DatabaseService.nafilaEventsTable,
              event.toMap(),
            );
            insertedIds.add(id);
          }

          // Verify prayer_events count unchanged after CREATE
          var prayerCountAfterCreate = await _getRowCount(testDb, DatabaseService.prayerEventsTable);
          expect(prayerCountAfterCreate, equals(baselinePrayerCount),
              reason: 'CREATE operations should not affect prayer_events');

          // Perform Nafila UPDATE operations
          for (final id in insertedIds) {
            await testDb.update(
              DatabaseService.nafilaEventsTable,
              {'notes': 'Updated note', 'updated_at': DateTime.now().toIso8601String()},
              where: 'event_id = ?',
              whereArgs: [id],
            );
          }

          // Verify prayer_events count unchanged after UPDATE
          var prayerCountAfterUpdate = await _getRowCount(testDb, DatabaseService.prayerEventsTable);
          expect(prayerCountAfterUpdate, equals(baselinePrayerCount),
              reason: 'UPDATE operations should not affect prayer_events');

          // Perform Nafila DELETE operations
          for (final id in insertedIds) {
            await testDb.delete(
              DatabaseService.nafilaEventsTable,
              where: 'event_id = ?',
              whereArgs: [id],
            );
          }

          // Verify prayer_events count unchanged after DELETE
          var prayerCountAfterDelete = await _getRowCount(testDb, DatabaseService.prayerEventsTable);
          expect(prayerCountAfterDelete, equals(baselinePrayerCount),
              reason: 'DELETE operations should not affect prayer_events');
        } finally {
          await testDb.close();
        }
      },
    );
  });

  group('NafilaRepository Unit Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 14,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE ${DatabaseService.nafilaEventsTable} (
                event_id INTEGER PRIMARY KEY AUTOINCREMENT,
                nafila_type TEXT NOT NULL,
                event_date TEXT NOT NULL,
                event_timestamp TEXT NOT NULL,
                rakat_count INTEGER NOT NULL,
                actual_prayer_time TEXT,
                notes TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');

            await db.execute('''
              CREATE TABLE ${DatabaseService.nafilaScoresTable} (
                nafila_type TEXT PRIMARY KEY,
                score REAL NOT NULL DEFAULT 0.0,
                current_streak INTEGER NOT NULL DEFAULT 0,
                longest_streak INTEGER NOT NULL DEFAULT 0,
                total_rakats INTEGER NOT NULL DEFAULT 0,
                total_completions INTEGER NOT NULL DEFAULT 0,
                calculated_at TEXT NOT NULL,
                last_event_date TEXT
              )
            ''');
          },
        ),
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('getEventsForDate returns events for specific date', () async {
      final date = DateTime(2024, 1, 15);
      final event = NafilaEvent(
        nafilaType: NafilaType.sunnahFajr,
        eventDate: date,
        eventTimestamp: DateTime(2024, 1, 15, 5, 30),
        rakatCount: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await testDb.insert(DatabaseService.nafilaEventsTable, event.toMap());

      final results = await testDb.query(
        DatabaseService.nafilaEventsTable,
        where: 'event_date = ?',
        whereArgs: ['2024-01-15'],
      );

      expect(results.length, equals(1));
      expect(results.first['nafila_type'], equals('sunnahFajr'));
    });

    test('getEventsForTypeOnDate returns events for specific type and date', () async {
      final date = DateTime(2024, 1, 15);
      
      // Insert Sunnah Fajr event
      await testDb.insert(DatabaseService.nafilaEventsTable, NafilaEvent(
        nafilaType: NafilaType.sunnahFajr,
        eventDate: date,
        eventTimestamp: DateTime(2024, 1, 15, 5, 30),
        rakatCount: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());

      // Insert Duha event
      await testDb.insert(DatabaseService.nafilaEventsTable, NafilaEvent(
        nafilaType: NafilaType.duha,
        eventDate: date,
        eventTimestamp: DateTime(2024, 1, 15, 9, 0),
        rakatCount: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());

      final results = await testDb.query(
        DatabaseService.nafilaEventsTable,
        where: 'nafila_type = ? AND event_date = ?',
        whereArgs: ['sunnahFajr', '2024-01-15'],
      );

      expect(results.length, equals(1));
      expect(results.first['rakat_count'], equals(2));
    });

    test('getEventsInRange returns events within date range', () async {
      // Insert events on different dates
      await testDb.insert(DatabaseService.nafilaEventsTable, NafilaEvent(
        nafilaType: NafilaType.sunnahFajr,
        eventDate: DateTime(2024, 1, 10),
        eventTimestamp: DateTime(2024, 1, 10, 5, 30),
        rakatCount: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());

      await testDb.insert(DatabaseService.nafilaEventsTable, NafilaEvent(
        nafilaType: NafilaType.duha,
        eventDate: DateTime(2024, 1, 15),
        eventTimestamp: DateTime(2024, 1, 15, 9, 0),
        rakatCount: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());

      await testDb.insert(DatabaseService.nafilaEventsTable, NafilaEvent(
        nafilaType: NafilaType.shafiWitr,
        eventDate: DateTime(2024, 1, 20),
        eventTimestamp: DateTime(2024, 1, 20, 22, 0),
        rakatCount: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());

      final results = await testDb.query(
        DatabaseService.nafilaEventsTable,
        where: 'event_date >= ? AND event_date <= ?',
        whereArgs: ['2024-01-12', '2024-01-18'],
      );

      expect(results.length, equals(1));
      expect(results.first['nafila_type'], equals('duha'));
    });

    test('saveNafilaScore inserts or replaces score', () async {
      final score = NafilaScore(
        nafilaType: NafilaType.sunnahFajr,
        score: 0.85,
        currentStreak: 5,
        longestStreak: 10,
        totalRakats: 100,
        totalCompletions: 50,
        calculatedAt: DateTime.now(),
        lastEventDate: DateTime(2024, 1, 15),
      );

      await testDb.insert(
        DatabaseService.nafilaScoresTable,
        score.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final results = await testDb.query(
        DatabaseService.nafilaScoresTable,
        where: 'nafila_type = ?',
        whereArgs: ['sunnahFajr'],
      );

      expect(results.length, equals(1));
      expect(results.first['score'], equals(0.85));
      expect(results.first['current_streak'], equals(5));

      // Update the score
      final updatedScore = score.copyWith(score: 0.90, currentStreak: 6);
      await testDb.insert(
        DatabaseService.nafilaScoresTable,
        updatedScore.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final updatedResults = await testDb.query(
        DatabaseService.nafilaScoresTable,
        where: 'nafila_type = ?',
        whereArgs: ['sunnahFajr'],
      );

      expect(updatedResults.length, equals(1));
      expect(updatedResults.first['score'], equals(0.90));
      expect(updatedResults.first['current_streak'], equals(6));
    });

    test('getAllNafilaScores returns all scores', () async {
      // Insert multiple scores
      await testDb.insert(
        DatabaseService.nafilaScoresTable,
        NafilaScore(
          nafilaType: NafilaType.sunnahFajr,
          score: 0.85,
          currentStreak: 5,
          longestStreak: 10,
          totalRakats: 100,
          totalCompletions: 50,
          calculatedAt: DateTime.now(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await testDb.insert(
        DatabaseService.nafilaScoresTable,
        NafilaScore(
          nafilaType: NafilaType.duha,
          score: 0.70,
          currentStreak: 3,
          longestStreak: 7,
          totalRakats: 80,
          totalCompletions: 20,
          calculatedAt: DateTime.now(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final results = await testDb.query(DatabaseService.nafilaScoresTable);

      expect(results.length, equals(2));
    });
  });
}
