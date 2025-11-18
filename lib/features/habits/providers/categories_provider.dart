import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../models/exceptions/category_exception.dart';
import '../repositories/category_repository.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/utils/core_logging_utility.dart';
import 'habits_provider.dart';
import '../../tasks/tasks_provider.dart';

part 'categories_provider.g.dart';

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  late final CategoryRepository _repository;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  Future<List<Category>> build() async {
    _repository = CategoryRepository();
    
    try {
      // Seed default categories on first load
      await _repository.seedDefaultCategories();
      
      return await _repository.getCategories();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoriesProvider',
        'build',
        'Failed to initialize categories: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.createCategory(category);
        _retryCount = 0; // Reset retry count on success
        
        CoreLoggingUtility.info(
          'CategoriesProvider',
          'addCategory',
          'Successfully added category: ${category.name}',
        );
        
        return await _repository.getCategories();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'CategoriesProvider',
          'addCategory',
          'Failed to add category: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.updateCategory(category);
        _retryCount = 0; // Reset retry count on success
        
        CoreLoggingUtility.info(
          'CategoriesProvider',
          'updateCategory',
          'Successfully updated category: ${category.name}',
        );
        
        return await _repository.getCategories();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'CategoriesProvider',
          'updateCategory',
          'Failed to update category: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.deleteCategory(categoryId);
        _retryCount = 0; // Reset retry count on success
        
        // Refresh navigation to remove category item if it was pinned
        ref.read(navigationProvider.notifier).refresh();
        
        // Refresh habits and tasks providers to reflect unassigned categories
        ref.invalidate(habitsProvider);
        ref.invalidate(tasksProvider);
        
        CoreLoggingUtility.info(
          'CategoriesProvider',
          'deleteCategory',
          'Successfully deleted category with ID: $categoryId',
        );
        
        return await _repository.getCategories();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'CategoriesProvider',
          'deleteCategory',
          'Failed to delete category: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  Future<void> toggleSidebarPin(int categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.toggleCategorySidebarPin(categoryId);
        _retryCount = 0; // Reset retry count on success
        
        // Refresh navigation to add/remove category item from sidebar
        ref.read(navigationProvider.notifier).refresh();
        
        CoreLoggingUtility.info(
          'CategoriesProvider',
          'toggleSidebarPin',
          'Successfully toggled sidebar pin for category: $categoryId',
        );
        
        return await _repository.getCategories();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'CategoriesProvider',
          'toggleSidebarPin',
          'Failed to toggle sidebar pin: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        _retryCount = 0; // Reset retry count on manual refresh
        return await _repository.getCategories();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'CategoriesProvider',
          'refresh',
          'Failed to refresh categories: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Retry failed operation with exponential backoff
  Future<void> retryOperation() async {
    if (_retryCount >= _maxRetries) {
      CoreLoggingUtility.warning(
        'CategoriesProvider',
        'retryOperation',
        'Max retry attempts reached ($_maxRetries)',
      );
      throw const CategoryDatabaseException(
        'Maximum retry attempts reached. Please try again later.',
      );
    }

    _retryCount++;
    CoreLoggingUtility.info(
      'CategoriesProvider',
      'retryOperation',
      'Retrying operation (attempt $_retryCount of $_maxRetries)',
    );

    // Exponential backoff: wait 1s, 2s, 4s
    await Future.delayed(Duration(seconds: 1 << (_retryCount - 1)));
    
    await refresh();
  }
}
