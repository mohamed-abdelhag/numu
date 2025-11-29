import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/nafila_event.dart';
import '../models/nafila_score.dart';
import '../models/enums/nafila_type.dart';

/// Repository layer for Nafila (voluntary prayer) data access.
/// Handles all database operations related to Nafila events and scores.
/// Uses separate tables from prayer_events to maintain data isolation.
///
/// **Validates: Requirements 2.2, 7.3**
class NafilaRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  // ============================================================================
  // NAFILA EVENT OPERATIONS
  // ============================================================================

  /// Log a Nafila event.
  /// Creates a new event in the nafila_events table.
  ///
  /// **Validates: Requirements 2.2, 7.3**
  Future<NafilaEvent> logNafilaEvent(NafilaEvent event) async {
    try {
      CoreLoggingUtility.info(
        'NafilaRepository',
        'logNafilaEvent',
        'Logging event for ${event.nafilaType.englishName} on ${event.eventDate}',
      );

      final db = await _dbService.database;
      final id = await db.insert(
        DatabaseService.nafilaEventsTable,
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      CoreLoggingUtility.info(
        'NafilaRepository',
        'logNafilaEvent',
        'Created Nafila event with ID $id',
      );

      return event.copyWith(id: id);
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'logNafilaEvent',
        'Failed to log Nafila event: $e',
      );
      rethrow;
    }
  }

  /// Update an existing Nafila event.
  ///
  /// **Validates: Requirements 2.2**
  Future<NafilaEvent> updateNafilaEvent(NafilaEvent event) async {
    if (event.id == null) {
      throw ArgumentError('Cannot update Nafila event without an ID');
    }

    try {
      final db = await _dbService.database;
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());

      await db.update(
        DatabaseService.nafilaEventsTable,
        updatedEvent.toMap(),
        where: 'event_id = ?',
        whereArgs: [event.id],
      );

      CoreLoggingUtility.info(
        'NafilaRepository',
        'updateNafilaEvent',
        'Updated Nafila event ID ${event.id}',
      );

      return updatedEvent;
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'updateNafilaEvent',
        'Failed to update Nafila event: $e',
      );
      rethrow;
    }
  }

  /// Delete a Nafila event by ID.
  Future<void> deleteNafilaEvent(int eventId) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        DatabaseService.nafilaEventsTable,
        where: 'event_id = ?',
        whereArgs: [eventId],
      );

      CoreLoggingUtility.info(
        'NafilaRepository',
        'deleteNafilaEvent',
        'Deleted Nafila event ID $eventId',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'deleteNafilaEvent',
        'Failed to delete Nafila event: $e',
      );
      rethrow;
    }
  }

  /// Get all Nafila events for a specific date.
  Future<List<NafilaEvent>> getEventsForDate(DateTime date) async {
    try {
      final db = await _dbService.database;
      final dateStr = _formatDateOnly(date);

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.nafilaEventsTable,
        where: 'event_date = ?',
        whereArgs: [dateStr],
        orderBy: 'event_timestamp ASC',
      );

      return maps.map((map) => NafilaEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'getEventsForDate',
        'Failed to fetch Nafila events for date: $e',
      );
      rethrow;
    }
  }

  /// Get Nafila events for a specific type on a specific date.
  Future<List<NafilaEvent>> getEventsForTypeOnDate(
    NafilaType type,
    DateTime date,
  ) async {
    try {
      final db = await _dbService.database;
      final dateStr = _formatDateOnly(date);

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.nafilaEventsTable,
        where: 'nafila_type = ? AND event_date = ?',
        whereArgs: [type.toJson(), dateStr],
        orderBy: 'event_timestamp DESC',
      );

      return maps.map((map) => NafilaEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'getEventsForTypeOnDate',
        'Failed to fetch Nafila events for type on date: $e',
      );
      rethrow;
    }
  }

  /// Get Nafila events within a date range.
  Future<List<NafilaEvent>> getEventsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _dbService.database;
      final startStr = _formatDateOnly(startDate);
      final endStr = _formatDateOnly(endDate);

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.nafilaEventsTable,
        where: 'event_date >= ? AND event_date <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'event_date ASC, event_timestamp ASC',
      );

      return maps.map((map) => NafilaEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'getEventsInRange',
        'Failed to fetch Nafila events in range: $e',
      );
      rethrow;
    }
  }

  /// Get all Nafila events for a specific type.
  ///
  /// **Validates: Requirements 4.4, 4.5**
  Future<List<NafilaEvent>> getEventsForType(NafilaType type) async {
    try {
      final db = await _dbService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.nafilaEventsTable,
        where: 'nafila_type = ?',
        whereArgs: [type.toJson()],
        orderBy: 'event_date ASC, event_timestamp ASC',
      );

      return maps.map((map) => NafilaEvent.fromMap(map)).toList();
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'getEventsForType',
        'Failed to fetch Nafila events for type: $e',
      );
      rethrow;
    }
  }

  // ============================================================================
  // NAFILA SCORE OPERATIONS
  // ============================================================================

  /// Save or update a Nafila score.
  /// Uses INSERT OR REPLACE since nafila_type is the primary key.
  ///
  /// **Validates: Requirements 4.4**
  Future<void> saveNafilaScore(NafilaScore score) async {
    try {
      final db = await _dbService.database;

      await db.insert(
        DatabaseService.nafilaScoresTable,
        score.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      CoreLoggingUtility.info(
        'NafilaRepository',
        'saveNafilaScore',
        'Saved score ${score.score} for ${score.nafilaType.englishName}',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'saveNafilaScore',
        'Failed to save Nafila score: $e',
      );
      rethrow;
    }
  }

  /// Get the cached score for a specific Nafila type.
  Future<NafilaScore?> getNafilaScore(NafilaType type) async {
    try {
      final db = await _dbService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.nafilaScoresTable,
        where: 'nafila_type = ?',
        whereArgs: [type.toJson()],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return NafilaScore.fromMap(maps.first);
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'getNafilaScore',
        'Failed to fetch Nafila score: $e',
      );
      rethrow;
    }
  }

  /// Get all cached Nafila scores.
  Future<Map<NafilaType, NafilaScore>> getAllNafilaScores() async {
    try {
      final db = await _dbService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.nafilaScoresTable,
      );

      final scores = <NafilaType, NafilaScore>{};
      for (final map in maps) {
        final score = NafilaScore.fromMap(map);
        scores[score.nafilaType] = score;
      }

      return scores;
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaRepository',
        'getAllNafilaScores',
        'Failed to fetch all Nafila scores: $e',
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
