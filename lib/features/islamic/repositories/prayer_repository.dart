import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_event.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_score.dart';
import '../models/enums/prayer_type.dart';

/// Repository layer for prayer data access.
/// Handles all database operations related to prayer events, schedules, and scores.
///
/// **Validates: Requirements 3.1, 3.2, 3.3**
class PrayerRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  // ============================================================================
  // PRAYER EVENT OPERATIONS
  // ============================================================================

  /// Log a prayer event.
  /// If an event already exists for the same prayer type and date, it updates the existing event.
  ///
  /// **Validates: Requirements 2.1, 2.2, 2.3**
  Future<PrayerEvent> logPrayerEvent(PrayerEvent event) async {
    try {
      CoreLoggingUtility.info(
        'PrayerRepository',
        'logPrayerEvent',
        'Logging event for ${event.prayerType.englishName} on ${event.eventDate}',
      );

      // Check for existing event on the same date for the same prayer type
      final existingEvents = await getEventsForPrayerOnDate(
        event.prayerType,
        event.eventDate,
      );

      if (existingEvents.isNotEmpty) {
        // Update existing event
        final existingEvent = existingEvents.first;
        final updatedEvent = event.copyWith(
          id: existingEvent.id,
          createdAt: existingEvent.createdAt,
          updatedAt: DateTime.now(),
        );
        await updatePrayerEvent(updatedEvent);
        return updatedEvent;
      }

      // Create new event
      final db = await _dbService.database;
      final id = await db.insert(
        DatabaseService.prayerEventsTable,
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'logPrayerEvent',
        'Created prayer event with ID $id',
      );

      return event.copyWith(id: id);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'logPrayerEvent',
        'Failed to log prayer event: $e',
      );
      rethrow;
    }
  }


  /// Update an existing prayer event.
  Future<PrayerEvent> updatePrayerEvent(PrayerEvent event) async {
    if (event.id == null) {
      throw ArgumentError('Cannot update prayer event without an ID');
    }

    try {
      final db = await _dbService.database;
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());

      await db.update(
        DatabaseService.prayerEventsTable,
        updatedEvent.toMap(),
        where: 'event_id = ?',
        whereArgs: [event.id],
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'updatePrayerEvent',
        'Updated prayer event ID ${event.id}',
      );

      return updatedEvent;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'updatePrayerEvent',
        'Failed to update prayer event: $e',
      );
      rethrow;
    }
  }

  /// Delete a prayer event by ID.
  Future<void> deletePrayerEvent(int eventId) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        DatabaseService.prayerEventsTable,
        where: 'event_id = ?',
        whereArgs: [eventId],
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'deletePrayerEvent',
        'Deleted prayer event ID $eventId',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'deletePrayerEvent',
        'Failed to delete prayer event: $e',
      );
      rethrow;
    }
  }

  /// Get all prayer events for a specific date.
  Future<List<PrayerEvent>> getEventsForDate(DateTime date) async {
    try {
      final db = await _dbService.database;
      final dateStr = _formatDateOnly(date);

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerEventsTable,
        where: 'event_date = ?',
        whereArgs: [dateStr],
        orderBy: 'event_timestamp ASC',
      );

      return maps.map((map) => PrayerEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'getEventsForDate',
        'Failed to fetch events for date: $e',
      );
      rethrow;
    }
  }

  /// Get prayer events for a specific prayer type on a specific date.
  Future<List<PrayerEvent>> getEventsForPrayerOnDate(
    PrayerType type,
    DateTime date,
  ) async {
    try {
      final db = await _dbService.database;
      final dateStr = _formatDateOnly(date);

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerEventsTable,
        where: 'prayer_type = ? AND event_date = ?',
        whereArgs: [type.toJson(), dateStr],
        orderBy: 'event_timestamp DESC',
      );

      return maps.map((map) => PrayerEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'getEventsForPrayerOnDate',
        'Failed to fetch events for prayer on date: $e',
      );
      rethrow;
    }
  }

  /// Get prayer events for a specific prayer type within an optional date range.
  Future<List<PrayerEvent>> getEventsForPrayer(
    PrayerType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbService.database;

      String whereClause = 'prayer_type = ?';
      List<dynamic> whereArgs = [type.toJson()];

      if (startDate != null) {
        whereClause += ' AND event_date >= ?';
        whereArgs.add(_formatDateOnly(startDate));
      }

      if (endDate != null) {
        whereClause += ' AND event_date <= ?';
        whereArgs.add(_formatDateOnly(endDate));
      }

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerEventsTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'event_date DESC, event_timestamp DESC',
      );

      return maps.map((map) => PrayerEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'getEventsForPrayer',
        'Failed to fetch events for prayer: $e',
      );
      rethrow;
    }
  }

  // ============================================================================
  // PRAYER SCHEDULE OPERATIONS
  // ============================================================================

  /// Save a prayer schedule for a specific date.
  /// Uses INSERT OR REPLACE to handle both create and update.
  ///
  /// **Validates: Requirements 1.2, 3.3**
  Future<PrayerSchedule> savePrayerSchedule(PrayerSchedule schedule) async {
    try {
      final db = await _dbService.database;

      // Check if schedule exists for this date
      final existing = await getPrayerSchedule(schedule.date);

      if (existing != null) {
        // Update existing schedule
        await db.update(
          DatabaseService.prayerSchedulesTable,
          schedule.toMap(),
          where: 'date = ?',
          whereArgs: [_formatDateOnly(schedule.date)],
        );

        CoreLoggingUtility.info(
          'PrayerRepository',
          'savePrayerSchedule',
          'Updated prayer schedule for ${schedule.date}',
        );

        return schedule.copyWith(id: existing.id);
      }

      // Insert new schedule
      final id = await db.insert(
        DatabaseService.prayerSchedulesTable,
        schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'savePrayerSchedule',
        'Created prayer schedule with ID $id for ${schedule.date}',
      );

      return schedule.copyWith(id: id);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'savePrayerSchedule',
        'Failed to save prayer schedule: $e',
      );
      rethrow;
    }
  }

  /// Get the prayer schedule for a specific date.
  Future<PrayerSchedule?> getPrayerSchedule(DateTime date) async {
    try {
      final db = await _dbService.database;
      final dateStr = _formatDateOnly(date);

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerSchedulesTable,
        where: 'date = ?',
        whereArgs: [dateStr],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return PrayerSchedule.fromMap(maps.first);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'getPrayerSchedule',
        'Failed to fetch prayer schedule: $e',
      );
      rethrow;
    }
  }

  /// Delete old prayer schedules before a specific date.
  /// Used for cache cleanup.
  Future<void> deleteOldSchedules(DateTime beforeDate) async {
    try {
      final db = await _dbService.database;
      final dateStr = _formatDateOnly(beforeDate);

      final count = await db.delete(
        DatabaseService.prayerSchedulesTable,
        where: 'date < ?',
        whereArgs: [dateStr],
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'deleteOldSchedules',
        'Deleted $count old prayer schedules before $dateStr',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'deleteOldSchedules',
        'Failed to delete old schedules: $e',
      );
      rethrow;
    }
  }


  // ============================================================================
  // PRAYER SCORE OPERATIONS
  // ============================================================================

  /// Save or update a prayer score.
  /// Uses INSERT OR REPLACE since prayer_type is the primary key.
  ///
  /// **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5**
  Future<void> savePrayerScore(PrayerScore score) async {
    try {
      final db = await _dbService.database;

      await db.insert(
        DatabaseService.prayerScoresTable,
        score.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'savePrayerScore',
        'Saved score ${score.score} for ${score.prayerType.englishName}',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'savePrayerScore',
        'Failed to save prayer score: $e',
      );
      rethrow;
    }
  }

  /// Get the cached score for a specific prayer type.
  Future<PrayerScore?> getPrayerScore(PrayerType type) async {
    try {
      final db = await _dbService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerScoresTable,
        where: 'prayer_type = ?',
        whereArgs: [type.toJson()],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return PrayerScore.fromMap(maps.first);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'getPrayerScore',
        'Failed to fetch prayer score: $e',
      );
      rethrow;
    }
  }

  /// Get all cached prayer scores.
  Future<Map<PrayerType, PrayerScore>> getAllPrayerScores() async {
    try {
      final db = await _dbService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.prayerScoresTable,
      );

      final scores = <PrayerType, PrayerScore>{};
      for (final map in maps) {
        final score = PrayerScore.fromMap(map);
        scores[score.prayerType] = score;
      }

      return scores;
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'getAllPrayerScores',
        'Failed to fetch all prayer scores: $e',
      );
      rethrow;
    }
  }

  /// Delete the cached score for a specific prayer type.
  Future<void> deletePrayerScore(PrayerType type) async {
    try {
      final db = await _dbService.database;

      await db.delete(
        DatabaseService.prayerScoresTable,
        where: 'prayer_type = ?',
        whereArgs: [type.toJson()],
      );

      CoreLoggingUtility.info(
        'PrayerRepository',
        'deletePrayerScore',
        'Deleted score for ${type.englishName}',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerRepository',
        'deletePrayerScore',
        'Failed to delete prayer score: $e',
      );
      rethrow;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Format date as YYYY-MM-DD for database storage.
  static String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
