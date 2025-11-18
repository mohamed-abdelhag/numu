import '../models/category.dart';
import '../models/habit.dart';
import '../models/exceptions/category_exception.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../tasks/task.dart';

class CategoryRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Get all categories ordered by sort_order
  Future<List<Category>> getCategories() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'categories',
        orderBy: 'sort_order ASC, name ASC',
      );
      return maps.map((map) => Category.fromMap(map)).toList();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getCategories',
        'Failed to fetch categories: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to load categories',
        originalError: e,
      );
    }
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        CoreLoggingUtility.warning(
          'CategoryRepository',
          'getCategoryById',
          'Category with ID $id not found',
        );
        return null;
      }
      
      return Category.fromMap(maps.first);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getCategoryById',
        'Failed to fetch category with ID $id: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to load category',
        originalError: e,
      );
    }
  }

  /// Create a new category
  Future<Category> createCategory(Category category) async {
    try {
      // Validate category data
      _validateCategory(category);
      
      final db = await _dbService.database;
      final id = await db.insert('categories', category.toMap());
      
      CoreLoggingUtility.info(
        'CategoryRepository',
        'createCategory',
        'Successfully created category with ID $id: ${category.name}',
      );
      
      return category.copyWith(id: id);
    } catch (e, stackTrace) {
      if (e is CategoryValidationException) {
        rethrow;
      }
      CoreLoggingUtility.error(
        'CategoryRepository',
        'createCategory',
        'Failed to create category: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to create category',
        originalError: e,
      );
    }
  }

  /// Update an existing category
  Future<Category> updateCategory(Category category) async {
    try {
      if (category.id == null) {
        throw const CategoryValidationException(
          'Category ID cannot be null for update operation',
        );
      }
      
      // Validate category data
      _validateCategory(category);
      
      final db = await _dbService.database;
      
      // Check if category exists
      final existing = await getCategoryById(category.id!);
      if (existing == null) {
        throw CategoryNotFoundException(category.id!);
      }
      
      final rowsAffected = await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      
      if (rowsAffected == 0) {
        throw CategoryNotFoundException(category.id!);
      }
      
      CoreLoggingUtility.info(
        'CategoryRepository',
        'updateCategory',
        'Successfully updated category with ID ${category.id}: ${category.name}',
      );
      
      return category;
    } catch (e, stackTrace) {
      if (e is CategoryValidationException || e is CategoryNotFoundException) {
        rethrow;
      }
      CoreLoggingUtility.error(
        'CategoryRepository',
        'updateCategory',
        'Failed to update category: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to update category',
        originalError: e,
      );
    }
  }

  /// Delete a category and unassign it from all habits and tasks
  Future<void> deleteCategory(int id) async {
    try {
      final db = await _dbService.database;
      
      // Check if category exists
      final existing = await getCategoryById(id);
      if (existing == null) {
        throw CategoryNotFoundException(id);
      }
      
      // Use transaction to ensure atomicity
      await db.transaction((txn) async {
        // Unassign category from all habits
        final habitsUpdated = await txn.update(
          'habits',
          {'category_id': null},
          where: 'category_id = ?',
          whereArgs: [id],
        );
        
        // Unassign category from all tasks
        final tasksUpdated = await txn.update(
          'tasks',
          {'category_id': null},
          where: 'category_id = ?',
          whereArgs: [id],
        );
        
        // Delete the category
        final rowsDeleted = await txn.delete(
          'categories',
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (rowsDeleted == 0) {
          throw CategoryNotFoundException(id);
        }
        
        CoreLoggingUtility.info(
          'CategoryRepository',
          'deleteCategory',
          'Successfully deleted category with ID $id (unassigned from $habitsUpdated habits and $tasksUpdated tasks)',
        );
      });
    } catch (e, stackTrace) {
      if (e is CategoryNotFoundException) {
        rethrow;
      }
      CoreLoggingUtility.error(
        'CategoryRepository',
        'deleteCategory',
        'Failed to delete category with ID $id: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to delete category',
        originalError: e,
      );
    }
  }

  /// Get all habits assigned to a specific category
  Future<List<Habit>> getHabitsByCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'habits',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'sort_order ASC, name ASC',
      );
      
      return maps.map((map) => Habit.fromMap(map)).toList();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getHabitsByCategory',
        'Failed to fetch habits for category $categoryId: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to load habits for category',
        originalError: e,
      );
    }
  }

  /// Get all tasks assigned to a specific category
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'tasks',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getTasksByCategory',
        'Failed to fetch tasks for category $categoryId: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to load tasks for category',
        originalError: e,
      );
    }
  }

  /// Get the count of habits assigned to a specific category
  Future<int> getHabitCountForCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM habits WHERE category_id = ?',
        [categoryId],
      );
      
      return result.first['count'] as int;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getHabitCountForCategory',
        'Failed to count habits for category $categoryId: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to count habits for category',
        originalError: e,
      );
    }
  }

  /// Get the count of tasks assigned to a specific category
  Future<int> getTaskCountForCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE category_id = ?',
        [categoryId],
      );
      
      return result.first['count'] as int;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getTaskCountForCategory',
        'Failed to count tasks for category $categoryId: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to count tasks for category',
        originalError: e,
      );
    }
  }

  /// Toggle the sidebar pin status of a category
  Future<void> toggleCategorySidebarPin(int categoryId) async {
    try {
      final db = await _dbService.database;
      
      // Get current pin status
      final category = await getCategoryById(categoryId);
      if (category == null) {
        throw CategoryNotFoundException(categoryId);
      }
      
      // Toggle the pin status
      final newPinStatus = category.isPinnedToSidebar ? 0 : 1;
      await db.update(
        'categories',
        {'is_pinned_to_sidebar': newPinStatus},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      
      CoreLoggingUtility.info(
        'CategoryRepository',
        'toggleCategorySidebarPin',
        'Successfully toggled pin status for category $categoryId to ${newPinStatus == 1 ? "pinned" : "unpinned"}',
      );
    } catch (e, stackTrace) {
      if (e is CategoryNotFoundException) {
        rethrow;
      }
      CoreLoggingUtility.error(
        'CategoryRepository',
        'toggleCategorySidebarPin',
        'Failed to toggle pin status for category $categoryId: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to update pin status',
        originalError: e,
      );
    }
  }

  /// Get all categories that are pinned to the sidebar
  Future<List<Category>> getPinnedCategories() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'categories',
        where: 'is_pinned_to_sidebar = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC, name ASC',
      );
      
      return maps.map((map) => Category.fromMap(map)).toList();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'getPinnedCategories',
        'Failed to fetch pinned categories: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to load pinned categories',
        originalError: e,
      );
    }
  }

  /// Seed default system categories on first run
  Future<void> seedDefaultCategories() async {
    try {
      final db = await _dbService.database;
      
      // Check if categories already exist
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final existingCount = count.first['count'] as int;
      
      if (existingCount > 0) {
        return; // Categories already seeded
      }

      // Default system categories
      final defaultCategories = [
        Category(
          name: 'Health',
          description: 'Health and fitness related habits',
          icon: '❤️',
          color: '0xFFE57373',
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Productivity',
          description: 'Work and productivity habits',
          icon: '🎯',
          color: '0xFF64B5F6',
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Learning',
          description: 'Education and skill development',
          icon: '📚',
          color: '0xFFBA68C8',
          isSystem: true,
          sortOrder: 3,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Wellness',
          description: 'Mental health and self-care',
          icon: '🧘',
          color: '0xFF4DB6AC',
          isSystem: true,
          sortOrder: 4,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Social',
          description: 'Relationships and social activities',
          icon: '👥',
          color: '0xFF81C784',
          isSystem: true,
          sortOrder: 5,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Creative',
          description: 'Creative and artistic pursuits',
          icon: '🎨',
          color: '0xFFFFD54F',
          isSystem: true,
          sortOrder: 6,
          createdAt: DateTime.now(),
        ),
      ];

      // Insert all default categories
      for (final category in defaultCategories) {
        await db.insert('categories', category.toMap());
      }
      
      CoreLoggingUtility.info(
        'CategoryRepository',
        'seedDefaultCategories',
        'Successfully seeded ${defaultCategories.length} default categories',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryRepository',
        'seedDefaultCategories',
        'Failed to seed default categories: $e\n$stackTrace',
      );
      throw CategoryDatabaseException(
        'Failed to initialize default categories',
        originalError: e,
      );
    }
  }

  /// Validate category data before database operations
  void _validateCategory(Category category) {
    // Validate name
    if (category.name.trim().isEmpty) {
      throw const CategoryValidationException('Category name cannot be empty');
    }
    
    if (category.name.trim().length > 50) {
      throw const CategoryValidationException(
        'Category name must be 50 characters or less',
      );
    }
    
    // Validate description
    if (category.description != null && category.description!.trim().length > 200) {
      throw const CategoryValidationException(
        'Category description must be 200 characters or less',
      );
    }
    
    // Validate icon
    if (category.icon == null || category.icon!.isEmpty) {
      throw const CategoryValidationException('Category icon is required');
    }
    
    // Validate color format
    if (!_isValidColorFormat(category.color)) {
      throw const CategoryValidationException(
        'Invalid color format. Expected format: 0xFFRRGGBB',
      );
    }
  }

  /// Check if color string is in valid format
  bool _isValidColorFormat(String color) {
    // Expected format: 0xFFRRGGBB (10 characters)
    if (color.length != 10) return false;
    if (!color.startsWith('0x')) return false;
    
    // Try to parse as hex
    try {
      int.parse(color.substring(2), radix: 16);
      return true;
    } catch (e) {
      return false;
    }
  }
}
