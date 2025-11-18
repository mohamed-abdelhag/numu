/// Base exception class for category-related errors
abstract class CategoryException implements Exception {
  final String message;
  final Object? originalError;

  const CategoryException(this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return 'CategoryException: $message\nCaused by: $originalError';
    }
    return 'CategoryException: $message';
  }
}

/// Exception thrown when a category is not found
class CategoryNotFoundException extends CategoryException {
  final int categoryId;

  const CategoryNotFoundException(this.categoryId)
      : super('Category with ID $categoryId not found');

  @override
  String toString() => 'CategoryNotFoundException: Category with ID $categoryId not found';
}

/// Exception thrown when a category database operation fails
class CategoryDatabaseException extends CategoryException {
  const CategoryDatabaseException(super.message, {super.originalError});
}

/// Exception thrown when category validation fails
class CategoryValidationException extends CategoryException {
  const CategoryValidationException(super.message);
}
