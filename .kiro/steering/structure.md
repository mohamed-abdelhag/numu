# Project Structure

## Overview

The project follows a feature-first architecture with clear separation between app-level, core, and feature-specific code.

## Directory Structure

```
lib/
├── app/                    # App-level configuration
│   ├── router/            # GoRouter navigation setup
│   ├── theme/             # Theme definitions and color schemes
│   └── app.dart           # Root widget with theme and router setup
│
├── core/                   # Shared functionality across features
│   ├── models/            # Shared data models
│   ├── providers/         # Global providers (navigation, theme)
│   ├── services/          # Core services (database, settings)
│   ├── utils/             # Utilities (logging, helpers)
│   └── widgets/           # Reusable UI components
│       ├── buttons/
│       ├── headers/
│       └── shell/         # App shell (app bar, navigation)
│
└── features/              # Feature modules (self-contained)
    ├── habits/
    │   ├── models/        # Habit domain models and enums
    │   ├── providers/     # Riverpod state management
    │   ├── repositories/  # Data access layer
    │   ├── screens/       # UI screens
    │   ├── services/      # Business logic (streaks, statistics)
    │   └── widgets/       # Feature-specific widgets
    │
    ├── reminders/
    │   ├── models/
    │   ├── providers/
    │   ├── repositories/
    │   ├── screens/
    │   ├── services/      # Notification, alarm, scheduling
    │   └── widgets/
    │
    ├── settings/
    ├── tasks/
    ├── home/
    ├── onboarding/
    └── help/
```

## Architecture Patterns

### Feature Structure
Each feature follows a consistent layered architecture:

1. **Models**: Data structures and enums
   - Immutable classes with `copyWith` methods
   - `fromMap` and `toMap` for serialization
   - Validation logic in model classes

2. **Repositories**: Database access layer
   - Single responsibility per repository
   - CRUD operations
   - Exception handling with custom exceptions

3. **Services**: Business logic layer
   - Calculations (streaks, statistics)
   - Complex operations (scheduling, notifications)
   - Stateless service classes

4. **Providers**: State management
   - Use `@riverpod` annotation with code generation
   - AsyncNotifier pattern for async operations
   - Provider lifecycle management with `_isMounted` checks
   - Invalidate/refresh dependent providers

5. **Screens**: Full-page UI components
   - ConsumerWidget or ConsumerStatefulWidget
   - Handle navigation and user interactions
   - Minimal business logic

6. **Widgets**: Reusable UI components
   - Stateless when possible
   - Accept data via constructor parameters
   - Callbacks for user interactions

### Code Generation
- Riverpod providers use code generation (`.g.dart` files)
- Run `dart run build_runner build` after creating/modifying providers
- Generated files are committed to version control

### Database Layer
- Single `DatabaseService` instance (singleton pattern)
- Repositories interact with database through service
- Migration system for schema changes
- Foreign key constraints enforced

### Logging
- Use `CoreLoggingUtility` for all logging
- Format: `CoreLoggingUtility.info(source, operation, message)`
- Log levels: info, warning, error
- Include context in error logs (stack traces)

## Naming Conventions

### Files
- Snake case: `habit_repository.dart`, `user_profile_provider.dart`
- Screens: `*_screen.dart`
- Providers: `*_provider.dart` (with `.g.dart` generated file)
- Models: Singular noun (e.g., `habit.dart`, `reminder.dart`)

### Classes
- PascalCase: `HabitRepository`, `UserProfileProvider`
- Providers: `*Provider` or `*Notifier`
- Screens: `*Screen`
- Widgets: Descriptive names (e.g., `HabitCard`, `DailyProgressHeader`)

### Variables
- camelCase: `habitId`, `startOfWeek`, `isActive`
- Private: Prefix with underscore `_repository`, `_isMounted`
- Constants: camelCase or UPPER_SNAKE_CASE for compile-time constants

## Testing

### Test Structure
```
test/
├── features/              # Feature-specific tests
│   └── [feature]/
│       ├── screens/
│       └── widgets/
├── integration/           # Integration tests
└── [unit_tests].dart      # Unit tests at root level
```

### Testing Patterns
- Use `sqflite_common_ffi` for database testing
- In-memory databases (`:memory:`) for isolated tests
- setUp/tearDown for test lifecycle
- Integration tests verify cross-feature interactions
- Widget tests for UI components

## Documentation

- Feature documentation in `DOCs/` folder
- Implementation guides for complex features
- Architecture decisions documented in code comments
- README files for major subsystems
