import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_streak.dart';
import '../models/habit_period_progress.dart';
import '../models/enums/streak_type.dart';
import '../models/exceptions/habit_exception.dart';

/// Repository layer for habit data access
/// Handles all database operations related to habits and events
class HabitRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  // ============================================================================
  // HABIT CRUD OPERATIONS
  // ============================================================================

  /// Fetch all active habits ordered by sort_order
  Future<List<Habit>> getActiveHabits() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.habitsTable,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC, created_at DESC',
      );

      return maps.map((map) => Habit.fromMap(map)).toList();
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch active habits', originalError: e);
    }
  }

  /// Retrieve a single habit by ID
  Future<Habit?> getHabitById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.habitsTable,
        where: 'habit_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return Habit.fromMap(maps.first);
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch habit by ID', originalError: e);
    }
  }

  /// Create a new habit with validation
  Future<Habit> createHabit(Habit habit) async {
    // Validate habit using model validation
    try {
      habit.validate();
    } on ArgumentError catch (e) {
      throw HabitValidationException(e.message);
    }

    try {
      final db = await _dbService.database;
      final id = await db.insert(
        DatabaseService.habitsTable,
        habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return habit.copyWith(id: id);
    } on HabitValidationException {
      rethrow;
    } catch (e) {
      throw HabitDatabaseException('Failed to create habit', originalError: e);
    }
  }

  /// Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    if (habit.id == null) {
      throw HabitValidationException('Cannot update habit without an ID');
    }

    // Validate habit using model validation
    try {
      habit.validate();
    } on ArgumentError catch (e) {
      throw HabitValidationException(e.message);
    }

    try {
      final db = await _dbService.database;
      final updatedHabit = habit.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        DatabaseService.habitsTable,
        updatedHabit.toMap(),
        where: 'habit_id = ?',
        whereArgs: [habit.id],
      );
    } on HabitValidationException {
      rethrow;
    } catch (e) {
      throw HabitDatabaseException('Failed to update habit', originalError: e);
    }
  }

  /// Archive a habit by setting archived_at timestamp
  Future<void> archiveHabit(int id) async {
    try {
      final db = await _dbService.database;
      await db.update(
        DatabaseService.habitsTable,
        {
          'is_active': 0,
          'archived_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'habit_id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw HabitDatabaseException('Failed to archive habit', originalError: e);
    }
  }

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  /// Get all habits assigned to a specific category
  Future<List<Habit>> getHabitsByCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.habitsTable,
        where: 'category_id = ? AND is_active = ?',
        whereArgs: [categoryId, 1],
        orderBy: 'sort_order ASC, created_at DESC',
      );

      return maps.map((map) => Habit.fromMap(map)).toList();
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch habits by category', originalError: e);
    }
  }

  /// Unassign category from all habits (set category_id to NULL)
  /// Used when deleting a category
  Future<void> unassignCategoryFromHabits(int categoryId) async {
    try {
      final db = await _dbService.database;
      await db.update(
        DatabaseService.habitsTable,
        {
          'category_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    } catch (e) {
      throw HabitDatabaseException('Failed to unassign category from habits', originalError: e);
    }
  }

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  /// Log a habit event with duplicate prevention
  /// Checks for existing events on the same date and updates them instead of creating duplicates
  Future<HabitEvent> logEvent(HabitEvent event) async {
    try {
      // Check for existing events on the same date
      final existingEvents = await getEventsForDate(event.habitId, event.eventDate);
      
      if (existingEvents.isNotEmpty) {
        // Update existing event instead of creating duplicate
        final existingEvent = existingEvents.first;
        final updatedEvent = event.copyWith(
          id: existingEvent.id,
          createdAt: existingEvent.createdAt, // Preserve original creation time
          updatedAt: DateTime.now(), // Update modification time
        );
        await updateEvent(updatedEvent);
        return updatedEvent;
      }
      
      // No existing event, create new one
      final db = await _dbService.database;
      final id = await db.insert(
        'habit_events',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return event.copyWith(id: id);
    } catch (e) {
      throw HabitDatabaseException('Failed to log event', originalError: e);
    }
  }

  /// Update an existing habit event
  Future<HabitEvent> updateEvent(HabitEvent event) async {
    if (event.id == null) {
      throw HabitValidationException('Cannot update event without an ID');
    }

    try {
      final db = await _dbService.database;
      final updatedEvent = event.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        'habit_events',
        updatedEvent.toMap(),
        where: 'event_id = ?',
        whereArgs: [event.id],
      );

      return updatedEvent;
    } on HabitValidationException {
      rethrow;
    } catch (e) {
      throw HabitDatabaseException('Failed to update event', originalError: e);
    }
  }

  /// Get events for a specific habit on a specific date
  Future<List<HabitEvent>> getEventsForDate(int habitId, DateTime date) async {
    try {
      final db = await _dbService.database;
      
      // Normalize date to start of day for comparison
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'habit_events',
        where: 'habit_id = ? AND event_date >= ? AND event_date < ?',
        whereArgs: [
          habitId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        orderBy: 'event_timestamp DESC',
      );

      return maps.map((map) => HabitEvent.fromMap(map)).toList();
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch events for date', originalError: e);
    }
  }

  /// Get events for a habit within an optional date range
  Future<List<HabitEvent>> getEventsForHabit(
    int habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbService.database;
      
      String whereClause = 'habit_id = ?';
      List<dynamic> whereArgs = [habitId];

      if (startDate != null) {
        whereClause += ' AND event_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND event_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'habit_events',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'event_date DESC, event_timestamp DESC',
      );

      return maps.map((map) => HabitEvent.fromMap(map)).toList();
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch events for habit', originalError: e);
    }
  }

  // ============================================================================
  // STREAK OPERATIONS
  // ============================================================================

  /// Get streak data for a specific habit and streak type
  Future<HabitStreak?> getStreakForHabit(int habitId, StreakType type) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_streaks',
        where: 'habit_id = ? AND streak_type = ?',
        whereArgs: [habitId, type.toJson()],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return HabitStreak.fromMap(maps.first);
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch streak for habit', originalError: e);
    }
  }

  /// Save or update streak data for a habit
  Future<void> saveStreak(HabitStreak streak) async {
    try {
      final db = await _dbService.database;
      
      // Use INSERT OR REPLACE to handle both create and update
      await db.insert(
        'habit_streaks',
        streak.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw HabitDatabaseException('Failed to save streak', originalError: e);
    }
  }

  // ============================================================================
  // PERIOD PROGRESS OPERATIONS
  // ============================================================================

  /// Get current period progress for a habit
  Future<HabitPeriodProgress?> getCurrentPeriodProgress(int habitId) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now();
      
      // Query for the most recent period that includes today
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_period_progress',
        where: 'habit_id = ? AND period_start_date <= ? AND period_end_date >= ?',
        whereArgs: [
          habitId,
          now.toIso8601String(),
          now.toIso8601String(),
        ],
        orderBy: 'period_start_date DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return HabitPeriodProgress.fromMap(maps.first);
    } catch (e) {
      throw HabitDatabaseException('Failed to fetch current period progress', originalError: e);
    }
  }

  /// Save or update period progress for a habit
  Future<void> savePeriodProgress(HabitPeriodProgress progress) async {
    try {
      final db = await _dbService.database;
      
      // Check if a record exists for this habit and period
      final existing = await db.query(
        'habit_period_progress',
        where: 'habit_id = ? AND period_start_date = ? AND period_end_date = ?',
        whereArgs: [
          progress.habitId,
          progress.periodStartDate.toIso8601String(),
          progress.periodEndDate.toIso8601String(),
        ],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Update existing record
        await db.update(
          'habit_period_progress',
          progress.toMap(),
          where: 'progress_id = ?',
          whereArgs: [existing.first['progress_id']],
        );
      } else {
        // Insert new record
        await db.insert(
          'habit_period_progress',
          progress.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      throw HabitDatabaseException('Failed to save period progress', originalError: e);
    }
  }
}
