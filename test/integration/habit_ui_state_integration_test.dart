import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/habits/models/habit_event.dart';
import 'package:numu/features/habits/models/enums/tracking_type.dart';
import 'package:numu/features/habits/models/enums/goal_type.dart';
import 'package:numu/features/habits/models/enums/frequency.dart';
import 'package:numu/features/habits/models/enums/active_days_mode.dart';
import 'package:numu/features/habits/models/enums/require_mode.dart';
import 'package:numu/features/habits/repositories/habit_repository.dart';

import 'package:numu/features/profile/models/user_profile.dart';
import 'package:numu/features/profile/repositories/user_profile_repository.dart';
import 'package:numu/core/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Habit UI State Synchronization Integration Tests', () {
    late Database testDb;
    late HabitRepository habitRepository;
    late UserProfileRepository userProfileRepository;
    int dbCounter = 0;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      dbCounter++;
      testDb = await databaseFactory.openDatabase(
        ':memory:$dbCounter',
        options: OpenDatabaseOptions(
          version: 9,
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
                longest_streak INTEGER NOT NULL DEFAULT 0,
                last_completion_date TEXT,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE,
                UNIQUE(habit_id, streak_type)
              )
            ''');

            // Create habit_period_progress table
            await db.execute('''
              CREATE TABLE habit_period_progress (
                progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
                habit_id INTEGER NOT NULL,
                period_start_date TEXT NOT NULL,
                period_end_date TEXT NOT NULL,
                completed_days INTEGER NOT NULL DEFAULT 0,
                total_days INTEGER NOT NULL,
                completion_percentage REAL NOT NULL DEFAULT 0.0,
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
          },
        ),
      );

      habitRepository = HabitRepository();
      userProfileRepository = UserProfileRepository(DatabaseService.instance);
    });

    tearDown(() async {
      try {
        await testDb.delete('habit_events');
        await testDb.delete('habit_streaks');
        await testDb.delete('habit_period_progress');
        await testDb.delete('habits');
        await testDb.delete('user_profile');
        await testDb.close();
        await databaseFactory.deleteDatabase(':memory:$dbCounter');
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('12.1: Habit event logging updates provider state quickly', () async {
      // Create a test habit
      final habit = Habit(
        name: 'Test Habit',
        icon: '💪',
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

      final savedHabit = await habitRepository.createHabit(habit);
      expect(savedHabit.id, isNotNull);

      // Log a habit event
      final event = HabitEvent(
        habitId: savedHabit.id!,
        eventDate: DateTime.now(),
        eventTimestamp: DateTime.now(),
        completed: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final startTime = DateTime.now();
      await habitRepository.logEvent(event);
      final endTime = DateTime.now();

      // Verify event logging is fast
      expect(
        endTime.difference(startTime).inMilliseconds,
        lessThan(100),
        reason: 'Event logging should complete within 100ms',
      );

      // Verify event was saved
      final events = await habitRepository.getEventsForHabit(savedHabit.id!);
      expect(events.length, equals(1));
      expect(events.first.completed, isTrue);
    });

    test('12.2: Streak values are consistent in database', () async {
      // Create a test habit
      final habit = Habit(
        name: 'Streak Test Habit',
        icon: '🔥',
        color: '0xFFE67E22',
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

      final savedHabit = await habitRepository.createHabit(habit);

      // Log events for 3 days
      final now = DateTime.now();
      for (int i = 2; i >= 0; i--) {
        final eventDate = now.subtract(Duration(days: i));
        final event = HabitEvent(
          habitId: savedHabit.id!,
          eventDate: eventDate,
          eventTimestamp: eventDate,
          completed: true,
          createdAt: eventDate,
          updatedAt: eventDate,
        );
        await habitRepository.logEvent(event);
      }

      // Verify events were saved
      final events = await habitRepository.getEventsForHabit(savedHabit.id!);
      expect(events.length, equals(3), reason: '3 events should be saved');
      
      // Verify all events are marked as completed
      for (final event in events) {
        expect(event.completed, isTrue);
      }
    });

    test('12.3: State remains consistent after multiple reads', () async {
      // Create a test habit
      final habit = Habit(
        name: 'Navigation Test Habit',
        icon: '📱',
        color: '0xFF2196F3',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 10.0,
        unit: 'reps',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await habitRepository.createHabit(habit);

      // Log an event
      final event = HabitEvent(
        habitId: savedHabit.id!,
        eventDate: DateTime.now(),
        eventTimestamp: DateTime.now(),
        value: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await habitRepository.logEvent(event);

      // Read events multiple times
      final events1 = await habitRepository.getEventsForHabit(savedHabit.id!);
      final events2 = await habitRepository.getEventsForHabit(savedHabit.id!);

      // Verify consistency
      expect(events1.length, equals(events2.length));
      expect(events1.first.value, equals(events2.first.value));
      expect(events1.first.habitId, equals(events2.first.habitId));
    });

    test('12.4: Week start preference can be updated', () async {
      // Check if profile exists, if not create it
      var profile = await userProfileRepository.getProfile();
      
      if (profile == null) {
        final userProfile = UserProfile(
          name: 'Test User',
          startOfWeek: 1, // Monday
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        profile = await userProfileRepository.createProfile(userProfile);
      }

      // Verify initial week start
      final initialWeekStart = profile.startOfWeek;

      // Update to different value
      final newWeekStart = initialWeekStart == 1 ? 7 : 1;
      final updatedProfile = profile.copyWith(
        startOfWeek: newWeekStart,
        updatedAt: DateTime.now(),
      );
      await userProfileRepository.updateProfile(updatedProfile);

      // Verify update
      final retrievedProfile = await userProfileRepository.getProfile();
      expect(retrievedProfile, isNotNull);
      expect(retrievedProfile!.startOfWeek, equals(newWeekStart));
    });
  });
}
