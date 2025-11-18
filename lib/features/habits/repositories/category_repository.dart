import '../models/category.dart';
import '../../../core/services/database_service.dart';

class CategoryRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Get all categories ordered by sort_order
  Future<List<Category>> getCategories() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'categories',
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  /// Create a new category
  Future<Category> createCategory(Category category) async {
    final db = await _dbService.database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  /// Seed default system categories on first run
  Future<void> seedDefaultCategories() async {
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
  }
}
