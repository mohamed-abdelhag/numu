import 'package:flutter_test/flutter_test.dart';
import 'package:numu/features/habits/providers/category_detail_provider.dart';
import 'package:numu/features/habits/models/category.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/tasks/task.dart';

void main() {
  group('CategoryDetailState', () {
    test('should create CategoryDetailState with required fields', () {
      final category = Category(
        id: 1,
        name: 'Test Category',
        color: '0xFF000000',
        createdAt: DateTime.now(),
      );
      
      final habits = <Habit>[];
      final tasks = <Task>[];
      
      final state = CategoryDetailState(
        category: category,
        habits: habits,
        tasks: tasks,
      );
      
      expect(state.category, equals(category));
      expect(state.habits, equals(habits));
      expect(state.tasks, equals(tasks));
    });
    
    test('should create a copy with updated fields', () {
      final category = Category(
        id: 1,
        name: 'Test Category',
        color: '0xFF000000',
        createdAt: DateTime.now(),
      );
      
      final state = CategoryDetailState(
        category: category,
        habits: [],
        tasks: [],
      );
      
      final newCategory = category.copyWith(name: 'Updated Category');
      final updatedState = state.copyWith(category: newCategory);
      
      expect(updatedState.category.name, equals('Updated Category'));
      expect(updatedState.habits, equals(state.habits));
      expect(updatedState.tasks, equals(state.tasks));
    });
  });
}
