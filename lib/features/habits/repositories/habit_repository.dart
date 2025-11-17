import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_streak.dart';
import '../models/enums/streak_type.dart';

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
      throw Exception('Failed to fetch active habits: $e');
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
      throw Exception('Failed to fetch habit by ID: $e');
    }
  }

  /// Create a new habit with validation
  Future<Habit> createHabit(Habit habit) async {
    try {
      // Validate habit name
      if (habit.name.trim().isEmpty) {
        throw ArgumentError('Habit name cannot be empty');
      }

      final db = await _dbService.database;
      final id = await db.insert(
        DatabaseService.habitsTable,
        habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return habit.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  /// Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    try {
      if (habit.id == null) {
        throw ArgumentError('Cannot update habit without an ID');
      }

      // Validate habit name
      if (habit.name.trim().isEmpty) {
        throw ArgumentError('Habit name cannot be empty');
      }

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
    } catch (e) {
      throw Exception('Failed to update habit: $e');
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
      throw Exception('Failed to archive habit: $e');
    }
  }

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  /// Log a habit event
  Future<HabitEvent> logEvent(HabitEvent event) async {
    try {
      final db = await _dbService.database;
      final id = await db.insert(
        'habit_events',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return event.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to log event: $e');
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
      throw Exception('Failed to fetch events for date: $e');
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
      throw Exception('Failed to fetch events for habit: $e');
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
      throw Exception('Failed to fetch streak for habit: $e');
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
      throw Exception('Failed to save streak: $e');
    }
  }
}
