# Technology Stack

## Framework & Language

- **Flutter**: Cross-platform mobile framework (iOS & Android)
- **Dart**: Programming language (SDK ^3.9.2)

## State Management

- **Riverpod**: State management solution
  - `flutter_riverpod` for widgets
  - `riverpod_annotation` for code generation
  - `riverpod_generator` for generating provider code
- **Pattern**: Use `@riverpod` annotation with code generation
- **Providers**: AsyncNotifier pattern for async state management

## Database & Storage

- **sqflite**: Local SQLite database for structured data (habits, events, streaks)
- **shared_preferences**: Key-value storage for settings and preferences
- **sqflite_common_ffi**: FFI-based SQLite for desktop/testing

## Navigation

- **go_router**: Declarative routing with type-safe navigation

## UI & Presentation

- **Material Design**: Primary design system
- **flutter_markdown**: Markdown rendering for help/tutorial content
- **Custom Themes**: Multiple color themes with light/dark mode support

## Notifications & Reminders

- **flutter_local_notifications**: Local notification system
- **timezone**: Timezone handling for scheduled reminders
- **permission_handler**: Runtime permission management

## Logging

- **flutter_logs**: Structured logging utility
- **Custom**: `CoreLoggingUtility` wrapper for consistent logging

## Code Quality

- **flutter_lints**: Linting rules (version 5.0.0)
- **analysis_options.yaml**: Static analysis configuration

## Build & Development

- **build_runner**: Code generation tool for Riverpod and other generators

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run code generation (for Riverpod providers)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage
```

### Analysis & Linting
```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios

# Build for release
flutter build apk --release
flutter build ios --release
```

## Platform-Specific Notes

### iOS
- Xcode configuration required for notifications
- See `DOCs/reminders/ios_xcode_configuration.md`
- Real device testing guide: `DOCs/reminders/real_device_testing.md`

### Android
- Gradle-based build system (Kotlin DSL)
- Notification channels configured in native code
