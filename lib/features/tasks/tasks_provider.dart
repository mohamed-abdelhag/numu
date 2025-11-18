import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/tasks/tasks_repository.dart';



part 'tasks_provider.g.dart';

@riverpod
class TasksNotifier extends _$TasksNotifier {
  final _repository = TasksRepository();

  @override
  Future<List<Task>> build() async {
    return await _repository.getTasks();
  }

  Future<void> addTask(String text, [int? categoryId]) async {
    if (text.trim().isEmpty) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final newTask = Task(text: text, categoryId: categoryId);
      await _repository.createTask(newTask);
      return await _repository.getTasks();
    });
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.updateTask(task);
      return await _repository.getTasks();
    });
  }

  Future<void> toggleTask(Task task) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await _repository.updateTask(updated);
      return await _repository.getTasks();
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.deleteTask(id);
      return await _repository.getTasks();
    });
  }
}