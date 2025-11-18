/// Base exception class for all habit-related errors
class HabitException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  HabitException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    if (originalError != null) {
      return 'HabitException: $message (Original: $originalError)';
    }
    return 'HabitException: $message';
  }
}

/// Exception thrown when habit validation fails
class HabitValidationException extends HabitException {
  HabitValidationException(String message)
      : super(message, code: 'VALIDATION_ERROR');

  @override
  String toString() => 'HabitValidationException: $message';
}

/// Exception thrown when a habit is not found
class HabitNotFoundException extends HabitException {
  final int habitId;

  HabitNotFoundException(this.habitId)
      : super(
          'Habit with id $habitId not found',
          code: 'NOT_FOUND',
        );

  @override
  String toString() => 'HabitNotFoundException: Habit with id $habitId not found';
}

/// Exception thrown when database operations fail
class HabitDatabaseException extends HabitException {
  HabitDatabaseException(String message, {dynamic originalError})
      : super(
          message,
          code: 'DATABASE_ERROR',
          originalError: originalError,
        );

  @override
  String toString() {
    if (originalError != null) {
      return 'HabitDatabaseException: $message (Original: $originalError)';
    }
    return 'HabitDatabaseException: $message';
  }
}
