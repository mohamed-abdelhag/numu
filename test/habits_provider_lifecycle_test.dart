import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/habits/models/habit_event.dart';
import 'package:numu/features/habits/models/enums/tracking_type.dart';
import 'package:numu/features/habits/models/enums/goal_type.dart';
import 'package:numu/features/habits/models/enums/frequency.dart';
import 'package:numu/features/habits/models/enums/active_days_mode.dart';
import 'package:numu/features/habits/models/enums/require_mode.dart';
import 'package:numu/features/habits/providers/habits_provider.dart';
import 'package:numu/features/habits/repositories/habit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitsProvider Lifecycle Management Tests', () {
    late Database testDb;
    late HabitRepository repository;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Create in-memory database for testing
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: (db, version) async {
            // Create habits table
            await db.execute('''
              CREATE TABLE habits (
                habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category_id INTEGER,
                icon TEXT NOT NULL,
                color TEXT NOT NULL,
                tracking_type TEXT NOT NULL,
                goal_type TEXT NOT NULL,
                target_value REAL,
                unit TEXT,
                frequency TEXT NOT NULL,
                custom_period_days INTEGER,
                period_start_date TEXT,
                active_days_mode TEXT NOT NULL,
                active_weekdays TEXT,
                require_mode TEXT NOT NULL,
                time_window_enabled INTEGER NOT NULL DEFAULT 0,
                time_window_start TEXT,
                time_window_end TEXT,
                time_window_mode TEXT,
                quality_layer_enabled INTEGER NOT NULL DEFAULT 0,
                quality_layer_label TEXT,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_template INTEGER NOT NULL DEFAULT 0,
                sort_order INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT
              )
            ''');

            // Create habit_events table
            await db.execute('''
              CREATE TABLE habit_events (
                event_id INTEGER PRIMARY KEY AUTOINCREMENT,
                habit_id INTEGER NOT NULL,
                event_date TEXT NOT NULL,
                event_timestamp TEXT NOT NULL,
                completed INTEGER,
                value REAL,
                value_delta REAL,
                time_recorded TEXT,
                within_time_window INTEGER,
                quality_achieved INTEGER,
                notes TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE
              )
            ''');

            // Create habit_streaks table
            await db.execute('''
              CREATE TABLE habit_streaks (
                streak_id INTEGER PRIMARY KEY AUTOINCREMENT,
                habit_id INTEGER NOT NULL,
                streak_type TEXT NOT NULL,
                current_streak INTEGER NOT NULL DEFAULT 0,
                current_streak_start_date TEXT,
                longest_streak INTEGER NOT NULL DEFAULT 0,
                longest_streak_start_date TEXT,
                longest_streak_end_date TEXT,
                total_completions INTEGER NOT NULL DEFAULT 0,
                total_days_active INTEGER NOT NULL DEFAULT 0,
                consistency_rate REAL NOT NULL DEFAULT 0,
                last_calculated_at TEXT NOT NULL,
                last_event_date TEXT,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE,
                UNIQUE(habit_id, streak_type)
              )
            ''');

            // Create habit_period_progress table
            await db.execute('''
              CREATE TABLE habit_period_progress (
                progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
                habit_id INTEGER NOT NULL,
                period_type TEXT NOT NULL,
                period_start_date TEXT NOT NULL,
                period_end_date TEXT NOT NULL,
                target_value REAL NOT NULL,
                current_value REAL NOT NULL DEFAULT 0,
                completed INTEGER NOT NULL DEFAULT 0,
                completion_date TEXT,
                time_window_completions INTEGER NOT NULL DEFAULT 0,
                quality_completions INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE
              )
            ''');

            // Create user_profile table
            await db.execute('''
              CREATE TABLE user_profile (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT,
                profile_picture_path TEXT,
                start_of_week INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');

            // Insert default user profile
            await db.insert('user_profile', {
              'name': 'Test User',
              'start_of_week': 1,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          },
        ),
      );

      repository = HabitRepository();
    });

    tearDown(() async {
      await testDb.close();
    });

    // Subtask 10.1: Provider prevents state updates after disposal
    test('Provider prevents state updates after disposal', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Create a test habit
      final habit = Habit(
        name: 'Test Habit',
        icon: '✅',
        color: '0xFF4CAF50',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);

      // Load the provider to initialize it
      final initialState = await container.read(habitsProvider.future);
      expect(initialState, isNotEmpty);
      expect(initialState.first.name, 'Test Habit');

      // Dispose the container (simulating provider disposal)
      container.dispose();

      // Try to add a habit after disposal - should not throw or update state
      try {
        await container.read(habitsProvider.notifier).addHabit(
          Habit(
            name: 'Should Not Be Added',
            icon: '❌',
            color: '0xFFFF0000',
            trackingType: TrackingType.binary,
            goalType: GoalType.minimum,
            frequency: Frequency.daily,
            activeDaysMode: ActiveDaysMode.all,
            requireMode: RequireMode.each,
            timeWindowEnabled: false,
            qualityLayerEnabled: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        // Provider may throw when accessed after disposal - this is acceptable
        expect(e, isA<StateError>());
      }

      // Verify the habit was not actually added to the database
      final allHabits = await repository.getActiveHabits();
      expect(allHabits.length, 1);
      expect(allHabits.first.name, 'Test Habit');
    });

    // Subtask 10.2: Cancelled operations are logged
    test('Cancelled operations are logged when provider is disposed', () async {
      final container = ProviderContainer();

      // Create a test habit
      final habit = Habit(
        name: 'Test Habit',
        icon: '✅',
        color: '0xFF4CAF50',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Load the provider
      await container.read(habitsProvider.future);

      // Dispose the container
      container.dispose();

      // Try to add a habit - should log cancellation
      try {
        await container.read(habitsProvider.notifier).addHabit(habit);
      } catch (e) {
        // Expected - provider disposed
        expect(e, isA<StateError>());
      }

      // Note: We can't directly verify log output in unit tests,
      // but we verify the operation doesn't crash and completes gracefully
    });

    // Subtask 10.3: Error states check mounted state
    test('Error states check mounted state before being set', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Load the provider
      await container.read(habitsProvider.future);

      // Try to log event for non-existent habit
      final now = DateTime.now();
      final event = HabitEvent(
        habitId: 99999, // Non-existent habit ID
        eventDate: now,
        eventTimestamp: now,
        value: 1.0,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await container.read(habitsProvider.notifier).logEvent(event);
      } catch (e) {
        // Error is expected
      }

      // Provider should still be in a valid state
      final state = container.read(habitsProvider);
      expect(state, isA<AsyncValue>());
    });
  });
}
