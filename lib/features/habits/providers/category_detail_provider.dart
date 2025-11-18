import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../models/habit.dart';
import '../models/exceptions/category_exception.dart';
import '../repositories/category_repository.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../tasks/task.dart';

part 'category_detail_provider.g.dart';

/// State class to hold all category detail data
class CategoryDetailState {
  final Category category;
  final List<Habit> habits;
  final List<Task> tasks;

  const CategoryDetailState({
    required this.category,
    required this.habits,
    required this.tasks,
  });

  CategoryDetailState copyWith({
    Category? category,
    List<Habit>? habits,
    List<Task>? tasks,
  }) {
    return CategoryDetailState(
      category: category ?? this.category,
      habits: habits ?? this.habits,
      tasks: tasks ?? this.tasks,
    );
  }
}

/// Provider for managing a single category's detail view
/// Loads category data, associated habits, and associated tasks
@riverpod
class CategoryDetailNotifier extends _$CategoryDetailNotifier {
  late final CategoryRepository _repository;

  @override
  Future<CategoryDetailState> build(int categoryId) async {
    _repository = CategoryRepository();

    try {
      final category = await _repository.getCategoryById(categoryId);
      if (category == null) {
        CoreLoggingUtility.warning(
          'CategoryDetailProvider',
          'build',
          'Category with ID $categoryId not found',
        );
        throw CategoryNotFoundException(categoryId);
      }

      final habits = await _repository.getHabitsByCategory(categoryId);
      final tasks = await _repository.getTasksByCategory(categoryId);

      CoreLoggingUtility.info(
        'CategoryDetailProvider',
        'build',
        'Successfully loaded category detail for ID: $categoryId (${habits.length} habits, ${tasks.length} tasks)',
      );

      return CategoryDetailState(
        category: category,
        habits: habits,
        tasks: tasks,
      );
    } catch (e, stackTrace) {
      if (e is CategoryNotFoundException) {
        rethrow;
      }
      CoreLoggingUtility.error(
        'CategoryDetailProvider',
        'build',
        'Failed to load category detail for ID $categoryId: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Refresh the category detail data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final categoryId = state.value?.category.id;
        if (categoryId == null) {
          CoreLoggingUtility.error(
            'CategoryDetailProvider',
            'refresh',
            'No category ID available for refresh',
          );
          throw Exception('No category ID available');
        }

        final category = await _repository.getCategoryById(categoryId);
        if (category == null) {
          CoreLoggingUtility.warning(
            'CategoryDetailProvider',
            'refresh',
            'Category with ID $categoryId not found during refresh',
          );
          throw CategoryNotFoundException(categoryId);
        }

        final habits = await _repository.getHabitsByCategory(categoryId);
        final tasks = await _repository.getTasksByCategory(categoryId);

        CoreLoggingUtility.info(
          'CategoryDetailProvider',
          'refresh',
          'Successfully refreshed category detail for ID: $categoryId (${habits.length} habits, ${tasks.length} tasks)',
        );

        return CategoryDetailState(
          category: category,
          habits: habits,
          tasks: tasks,
        );
      } catch (e, stackTrace) {
        if (e is CategoryNotFoundException) {
          rethrow;
        }
        CoreLoggingUtility.error(
          'CategoryDetailProvider',
          'refresh',
          'Failed to refresh category detail: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }
}
