import 'package:numu/features/tasks/task.dart';
import 'package:numu/core/services/database_service.dart';

// Repository pattern - one repository per entity
class TasksRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Task>> getTasks() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.tasksTable,
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<Task> createTask(Task task) async {
    final db = await _dbService.database;
    final id = await db.insert(
      DatabaseService.tasksTable,
      task.toMap(),
    );
    return task.copyWith(id: id);
  }

  Future<void> updateTask(Task task) async {
    final db = await _dbService.database;
    await db.update(
      DatabaseService.tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await _dbService.database;
    await db.delete(
      DatabaseService.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTaskCategory(int taskId, int? categoryId) async {
    final db = await _dbService.database;
    await db.update(
      DatabaseService.tasksTable,
      {'category_id': categoryId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<Task>> getTasksByCategory(int categoryId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.tasksTable,
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> unassignCategoryFromTasks(int categoryId) async {
    final db = await _dbService.database;
    await db.update(
      DatabaseService.tasksTable,
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }
}