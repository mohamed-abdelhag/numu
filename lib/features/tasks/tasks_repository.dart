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
}