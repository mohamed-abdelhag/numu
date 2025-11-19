import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../models/reminder.dart';

class ReminderRepository {
  final DatabaseService _databaseService;

  ReminderRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  /// Create a new reminder
  Future<int> createReminder(Reminder reminder) async {
    final db = await _databaseService.database;
    final map = reminder.toMap();
    map.remove('reminder_id'); // Remove id for insert
    return await db.insert(
      DatabaseService.remindersTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a reminder by ID
  Future<Reminder?> getReminderById(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      DatabaseService.remindersTable,
      where: 'reminder_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return Reminder.fromMap(results.first);
  }

  /// Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    final db = await _databaseService.database;
    final results = await db.query(
      DatabaseService.remindersTable,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Reminder.fromMap(map)).toList();
  }

  /// Get only active reminders
  Future<List<Reminder>> getActiveReminders() async {
    final db = await _databaseService.database;
    final results = await db.query(
      DatabaseService.remindersTable,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'next_trigger_time ASC',
    );

    return results.map((map) => Reminder.fromMap(map)).toList();
  }

  /// Get reminders linked to a specific habit
  Future<List<Reminder>> getRemindersByHabitId(int habitId) async {
    final db = await _databaseService.database;
    final results = await db.query(
      DatabaseService.remindersTable,
      where: 'link_type = ? AND link_entity_id = ?',
      whereArgs: ['habit', habitId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Reminder.fromMap(map)).toList();
  }

  /// Get reminders linked to a specific task
  Future<List<Reminder>> getRemindersByTaskId(int taskId) async {
    final db = await _databaseService.database;
    final results = await db.query(
      DatabaseService.remindersTable,
      where: 'link_type = ? AND link_entity_id = ?',
      whereArgs: ['task', taskId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Reminder.fromMap(map)).toList();
  }

  /// Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Cannot update reminder without an id');
    }

    final db = await _databaseService.database;
    final map = reminder.toMap();
    
    await db.update(
      DatabaseService.remindersTable,
      map,
      where: 'reminder_id = ?',
      whereArgs: [reminder.id],
    );
  }

  /// Delete a reminder by ID
  Future<void> deleteReminder(int id) async {
    final db = await _databaseService.database;
    await db.delete(
      DatabaseService.remindersTable,
      where: 'reminder_id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all reminders linked to a specific habit
  Future<void> deleteRemindersByHabitId(int habitId) async {
    final db = await _databaseService.database;
    await db.delete(
      DatabaseService.remindersTable,
      where: 'link_type = ? AND link_entity_id = ?',
      whereArgs: ['habit', habitId],
    );
  }

  /// Delete all reminders linked to a specific task
  Future<void> deleteRemindersByTaskId(int taskId) async {
    final db = await _databaseService.database;
    await db.delete(
      DatabaseService.remindersTable,
      where: 'link_type = ? AND link_entity_id = ?',
      whereArgs: ['task', taskId],
    );
  }

  /// Update the next trigger time for a reminder
  Future<void> updateNextTriggerTime(int id, DateTime nextTime) async {
    final db = await _databaseService.database;
    await db.update(
      DatabaseService.remindersTable,
      {
        'next_trigger_time': nextTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'reminder_id = ?',
      whereArgs: [id],
    );
  }
}
