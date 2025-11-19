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
import 'package:numu/features/habits/services/streak_calculation_service.dart';
import 'package:numu/core/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Active Days and Quality Layer Tests', () {
    late Database testDb;
    late HabitRepository repository;
    late StreakCalculationService streakService;

    setUp(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Create in-memory database for testing
      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: (db, version) async {
            // Create habits table matching actual schema
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

            // Create habit_events table matching actual schema
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

            // Create habit_streaks table matching actual schema
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
          },
        ),
      );

      repository = HabitRepository();
      streakService = StreakCalculationService(repository);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Binary habit with active days configuration can be created', () async {
      final habit = Habit(
        name: 'Morning Exercise',
        icon: '🏃',
        color: '0xFF64B5F6',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.selected,
        activeWeekdays: [1, 2, 3, 4, 5], // Monday to Friday
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.activeDaysMode, ActiveDaysMode.selected);
      expect(savedHabit.activeWeekdays, [1, 2, 3, 4, 5]);
    });

    test('Value habit with active days configuration can be created', () async {
      final habit = Habit(
        name: 'Read Pages',
        icon: '📚',
        color: '0xFF64B5F6',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 30.0,
        unit: 'pages',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.selected,
        activeWeekdays: [1, 2, 3, 4, 5, 6, 7], // All days
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.activeDaysMode, ActiveDaysMode.selected);
      expect(savedHabit.activeWeekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(savedHabit.targetValue, 30.0);
      expect(savedHabit.unit, 'pages');
    });

    test('Binary habit with quality layer can be created', () async {
      final habit = Habit(
        name: 'Meditation',
        icon: '🧘',
        color: '0xFF64B5F6',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: true,
        qualityLayerLabel: 'Focus Level',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.qualityLayerEnabled, true);
      expect(savedHabit.qualityLayerLabel, 'Focus Level');
    });

    test('Value habit with quality layer can be created', () async {
      final habit = Habit(
        name: 'Workout Minutes',
        icon: '💪',
        color: '0xFF64B5F6',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 45.0,
        unit: 'minutes',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: true,
        qualityLayerLabel: 'Intensity',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.qualityLayerEnabled, true);
      expect(savedHabit.qualityLayerLabel, 'Intensity');
      expect(savedHabit.targetValue, 45.0);
      expect(savedHabit.unit, 'minutes');
    });

    test('Binary habit with active days stores configuration correctly', () async {
      // Create a binary habit with weekdays only (Mon-Fri)
      final habit = Habit(
        name: 'Work Task',
        icon: '💼',
        color: '0xFF64B5F6',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.selected,
        activeWeekdays: [1, 2, 3, 4, 5], // Monday to Friday
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      // Verify the habit was saved with active days configuration
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.activeDaysMode, ActiveDaysMode.selected);
      expect(savedHabit.activeWeekdays, [1, 2, 3, 4, 5]);
      
      // Retrieve the habit from database to verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.activeDaysMode, ActiveDaysMode.selected);
      expect(retrievedHabit.activeWeekdays, [1, 2, 3, 4, 5]);
    });

    test('Value habit with active days stores configuration correctly', () async {
      // Create a value habit with specific days
      final habit = Habit(
        name: 'Study Hours',
        icon: '📖',
        color: '0xFF64B5F6',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 2.0,
        unit: 'hours',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.selected,
        activeWeekdays: [1, 3, 5], // Mon, Wed, Fri
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      // Verify the habit was saved with active days configuration
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.activeDaysMode, ActiveDaysMode.selected);
      expect(savedHabit.activeWeekdays, [1, 3, 5]);
      expect(savedHabit.targetValue, 2.0);
      expect(savedHabit.unit, 'hours');
      
      // Retrieve the habit from database to verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.activeDaysMode, ActiveDaysMode.selected);
      expect(retrievedHabit.activeWeekdays, [1, 3, 5]);
    });

    test('Binary habit with quality layer stores configuration correctly', () async {
      final habit = Habit(
        name: 'Yoga',
        icon: '🧘',
        color: '0xFF64B5F6',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: true,
        qualityLayerLabel: 'Form Quality',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      // Verify the habit was saved with quality layer configuration
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.qualityLayerEnabled, true);
      expect(savedHabit.qualityLayerLabel, 'Form Quality');
      
      // Retrieve the habit from database to verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.qualityLayerEnabled, true);
      expect(retrievedHabit.qualityLayerLabel, 'Form Quality');
    });

    test('Value habit with quality layer stores configuration correctly', () async {
      final habit = Habit(
        name: 'Running Distance',
        icon: '🏃',
        color: '0xFF64B5F6',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 5.0,
        unit: 'km',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: true,
        qualityLayerLabel: 'Pace Quality',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      // Verify the habit was saved with quality layer configuration
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.qualityLayerEnabled, true);
      expect(savedHabit.qualityLayerLabel, 'Pace Quality');
      expect(savedHabit.targetValue, 5.0);
      expect(savedHabit.unit, 'km');
      
      // Retrieve the habit from database to verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.qualityLayerEnabled, true);
      expect(retrievedHabit.qualityLayerLabel, 'Pace Quality');
    });
  });
}
