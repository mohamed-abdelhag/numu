import 'package:numu/features/tasks/task.dart';
import 'package:numu/core/services/database_service.dart';

// Repository pattern - one repository per entity
class TasksRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Task>> getTasks({
    bool? isCompleted,
    int? categoryId,
    DateTime? dueBefore,
    DateTime? dueAfter,
  }) async {
    try {
      final db = await _dbService.database;
      
      // Build WHERE clause dynamically based on filters
      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];
      
      if (isCompleted != null) {
        whereClauses.add('isCompleted = ?');
        whereArgs.add(isCompleted ? 1 : 0);
      }
      
      if (categoryId != null) {
        whereClauses.add('category_id = ?');
        whereArgs.add(categoryId);
      }
      
      if (dueBefore != null) {
        whereClauses.add('due_date < ?');
        whereArgs.add(dueBefore.toIso8601String());
      }
      
      if (dueAfter != null) {
        whereClauses.add('due_date > ?');
        whereArgs.add(dueAfter.toIso8601String());
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<Task?> getTaskById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return Task.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to fetch task with id $id: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      // Validate task title
      if (task.title.trim().isEmpty) {
        throw ArgumentError('Task title cannot be empty');
      }
      
      final db = await _dbService.database;
      // Ensure createdAt and updatedAt are set
      final taskToCreate = task.copyWith(
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );
      final id = await db.insert(
        DatabaseService.tasksTable,
        taskToCreate.toMap(),
      );
      return taskToCreate.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      // Validate task has an ID
      if (task.id == null) {
        throw ArgumentError('Cannot update task without an ID');
      }
      
      // Validate task title
      if (task.title.trim().isEmpty) {
        throw ArgumentError('Task title cannot be empty');
      }
      
      final db = await _dbService.database;
      // Update the updatedAt timestamp
      final taskToUpdate = task.copyWith(updatedAt: DateTime.now());
      final count = await db.update(
        DatabaseService.tasksTable,
        taskToUpdate.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      
      if (count == 0) {
        throw Exception('Task with id ${task.id} not found');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final db = await _dbService.database;
      final count = await db.delete(
        DatabaseService.tasksTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw Exception('Task with id $id not found');
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> updateTaskCategory(int taskId, int? categoryId) async {
    try {
      final db = await _dbService.database;
      final count = await db.update(
        DatabaseService.tasksTable,
        {'category_id': categoryId},
        where: 'id = ?',
        whereArgs: [taskId],
      );
      
      if (count == 0) {
        throw Exception('Task with id $taskId not found');
      }
    } catch (e) {
      throw Exception('Failed to update task category: $e');
    }
  }

  Future<List<Task>> getTasksByCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks for category $categoryId: $e');
    }
  }

  Future<void> unassignCategoryFromTasks(int categoryId) async {
    try {
      final db = await _dbService.database;
      await db.update(
        DatabaseService.tasksTable,
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    } catch (e) {
      throw Exception('Failed to unassign category from tasks: $e');
    }
  }

  Future<List<Task>> getOverdueTasks() async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'due_date < ? AND isCompleted = ?',
        whereArgs: [today.toIso8601String(), 0],
        orderBy: 'due_date ASC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch overdue tasks: $e');
    }
  }

  Future<List<Task>> getTasksDueToday() async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'due_date >= ? AND due_date < ?',
        whereArgs: [today.toIso8601String(), tomorrow.toIso8601String()],
        orderBy: 'due_date ASC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks due today: $e');
    }
  }

  Future<List<Task>> getTasksDueSoon() async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final threeDaysFromNow = today.add(const Duration(days: 3));
      
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'due_date >= ? AND due_date <= ? AND isCompleted = ?',
        whereArgs: [today.toIso8601String(), threeDaysFromNow.toIso8601String(), 0],
        orderBy: 'due_date ASC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks due soon: $e');
    }
  }
}
