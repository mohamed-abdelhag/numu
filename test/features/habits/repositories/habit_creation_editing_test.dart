import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/habits/models/enums/tracking_type.dart';
import 'package:numu/features/habits/models/enums/goal_type.dart';
import 'package:numu/features/habits/models/enums/frequency.dart';
import 'package:numu/features/habits/models/enums/active_days_mode.dart';
import 'package:numu/features/habits/models/enums/require_mode.dart';
import 'package:numu/features/habits/models/enums/time_window_mode.dart';
import 'package:numu/features/habits/repositories/habit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Habit Creation and Editing Flow Tests', () {
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
          },
        ),
      );

      repository = HabitRepository();
    });

    tearDown(() async {
      await testDb.close();
    });

    // Test creating binary habit without time window
    test('Create binary habit without time window', () async {
      final habit = Habit(
        name: 'Morning Stretch',
        description: 'Stretch for 5 minutes',
        icon: '🧘',
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
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.name, 'Morning Stretch');
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.timeWindowEnabled, false);
      expect(savedHabit.timeWindowStart, isNull);
      expect(savedHabit.timeWindowEnd, isNull);
      expect(savedHabit.timeWindowMode, isNull);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.trackingType, TrackingType.binary);
      expect(retrievedHabit.timeWindowEnabled, false);
    });

    // Test creating binary habit with time window
    test('Create binary habit with time window', () async {
      final habit = Habit(
        name: 'Morning Meditation',
        description: 'Meditate between 6-9 AM',
        icon: '🧘',
        color: '0xFF2196F3',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 6, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 9, minute: 0),
        timeWindowMode: TimeWindowMode.hard.toJson(),
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.name, 'Morning Meditation');
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.timeWindowEnabled, true);
      expect(savedHabit.timeWindowStart, const TimeOfDay(hour: 6, minute: 0));
      expect(savedHabit.timeWindowEnd, const TimeOfDay(hour: 9, minute: 0));
      expect(savedHabit.timeWindowMode, TimeWindowMode.hard.toJson());
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.trackingType, TrackingType.binary);
      expect(retrievedHabit.timeWindowEnabled, true);
      expect(retrievedHabit.timeWindowStart, const TimeOfDay(hour: 6, minute: 0));
      expect(retrievedHabit.timeWindowEnd, const TimeOfDay(hour: 9, minute: 0));
      expect(retrievedHabit.timeWindowMode, TimeWindowMode.hard.toJson());
    });

    // Test creating value habit with minimum goal
    test('Create value habit with minimum goal', () async {
      final habit = Habit(
        name: 'Read Pages',
        description: 'Read at least 30 pages daily',
        icon: '📚',
        color: '0xFFFF9800',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 30.0,
        unit: 'pages',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.name, 'Read Pages');
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.goalType, GoalType.minimum);
      expect(savedHabit.targetValue, 30.0);
      expect(savedHabit.unit, 'pages');
      expect(savedHabit.timeWindowEnabled, false);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.trackingType, TrackingType.value);
      expect(retrievedHabit.goalType, GoalType.minimum);
      expect(retrievedHabit.targetValue, 30.0);
      expect(retrievedHabit.unit, 'pages');
    });

    // Test creating value habit with maximum goal
    test('Create value habit with maximum goal', () async {
      final habit = Habit(
        name: 'Limit Coffee',
        description: 'Drink no more than 2 cups of coffee',
        icon: '☕',
        color: '0xFF795548',
        trackingType: TrackingType.value,
        goalType: GoalType.maximum,
        targetValue: 2.0,
        unit: 'cups',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.name, 'Limit Coffee');
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.goalType, GoalType.maximum);
      expect(savedHabit.targetValue, 2.0);
      expect(savedHabit.unit, 'cups');
      expect(savedHabit.timeWindowEnabled, false);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.trackingType, TrackingType.value);
      expect(retrievedHabit.goalType, GoalType.maximum);
      expect(retrievedHabit.targetValue, 2.0);
      expect(retrievedHabit.unit, 'cups');
    });

    // Test editing existing binary habit
    test('Edit existing binary habit', () async {
      // Create initial habit
      final habit = Habit(
        name: 'Exercise',
        description: 'Daily workout',
        icon: '💪',
        color: '0xFFE91E63',
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
      expect(savedHabit.id, isNotNull);
      
      // Edit the habit
      final updatedHabit = savedHabit.copyWith(
        name: 'Morning Exercise',
        description: 'Workout in the morning',
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 7, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 10, minute: 0),
        timeWindowMode: TimeWindowMode.soft.toJson(),
        updatedAt: DateTime.now(),
      );

      await repository.updateHabit(updatedHabit);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.id, savedHabit.id);
      expect(retrievedHabit.name, 'Morning Exercise');
      expect(retrievedHabit.description, 'Workout in the morning');
      expect(retrievedHabit.trackingType, TrackingType.binary);
      expect(retrievedHabit.timeWindowEnabled, true);
      expect(retrievedHabit.timeWindowStart, const TimeOfDay(hour: 7, minute: 0));
      expect(retrievedHabit.timeWindowEnd, const TimeOfDay(hour: 10, minute: 0));
      expect(retrievedHabit.timeWindowMode, TimeWindowMode.soft.toJson());
    });

    // Test editing existing value habit
    test('Edit existing value habit', () async {
      // Create initial habit
      final habit = Habit(
        name: 'Drink Water',
        description: 'Stay hydrated',
        icon: '💧',
        color: '0xFF03A9F4',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 8.0,
        unit: 'glasses',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      expect(savedHabit.id, isNotNull);
      
      // Edit the habit
      final updatedHabit = savedHabit.copyWith(
        targetValue: 10.0,
        description: 'Drink more water',
        qualityLayerEnabled: true,
        qualityLayerLabel: 'Hydration Quality',
        updatedAt: DateTime.now(),
      );

      await repository.updateHabit(updatedHabit);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.id, savedHabit.id);
      expect(retrievedHabit.name, 'Drink Water');
      expect(retrievedHabit.description, 'Drink more water');
      expect(retrievedHabit.trackingType, TrackingType.value);
      expect(retrievedHabit.goalType, GoalType.minimum);
      expect(retrievedHabit.targetValue, 10.0);
      expect(retrievedHabit.unit, 'glasses');
      expect(retrievedHabit.qualityLayerEnabled, true);
      expect(retrievedHabit.qualityLayerLabel, 'Hydration Quality');
    });

    // Test changing tracking type from binary to value
    test('Change tracking type from binary to value and verify field updates', () async {
      // Create initial binary habit
      final habit = Habit(
        name: 'Study',
        description: 'Daily study session',
        icon: '📖',
        color: '0xFF9C27B0',
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
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.binary);
      expect(savedHabit.targetValue, isNull);
      expect(savedHabit.unit, isNull);
      
      // Change to value tracking type
      final updatedHabit = savedHabit.copyWith(
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 2.0,
        unit: 'hours',
        updatedAt: DateTime.now(),
      );

      await repository.updateHabit(updatedHabit);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.id, savedHabit.id);
      expect(retrievedHabit.name, 'Study');
      expect(retrievedHabit.trackingType, TrackingType.value);
      expect(retrievedHabit.goalType, GoalType.minimum);
      expect(retrievedHabit.targetValue, 2.0);
      expect(retrievedHabit.unit, 'hours');
    });

    // Test changing tracking type from value to binary
    test('Change tracking type from value to binary and verify field updates', () async {
      // Create initial value habit
      final habit = Habit(
        name: 'Run Distance',
        description: 'Run daily',
        icon: '🏃',
        color: '0xFFFF5722',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 5.0,
        unit: 'km',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.targetValue, 5.0);
      expect(savedHabit.unit, 'km');
      
      // Change to binary tracking type (create new habit object without value-specific fields)
      final updatedHabit = Habit(
        id: savedHabit.id,
        name: savedHabit.name,
        description: savedHabit.description,
        icon: savedHabit.icon,
        color: savedHabit.color,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        targetValue: null,
        unit: null,
        frequency: savedHabit.frequency,
        activeDaysMode: savedHabit.activeDaysMode,
        requireMode: savedHabit.requireMode,
        timeWindowEnabled: savedHabit.timeWindowEnabled,
        qualityLayerEnabled: savedHabit.qualityLayerEnabled,
        createdAt: savedHabit.createdAt,
        updatedAt: DateTime.now(),
      );

      await repository.updateHabit(updatedHabit);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.id, savedHabit.id);
      expect(retrievedHabit.name, 'Run Distance');
      expect(retrievedHabit.trackingType, TrackingType.binary);
      expect(retrievedHabit.targetValue, isNull);
      expect(retrievedHabit.unit, isNull);
    });

    // Test value habit with time window
    test('Create value habit with time window', () async {
      final habit = Habit(
        name: 'Workout Minutes',
        description: 'Exercise for at least 45 minutes in the evening',
        icon: '💪',
        color: '0xFFE91E63',
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        targetValue: 45.0,
        unit: 'minutes',
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 17, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 21, minute: 0),
        timeWindowMode: TimeWindowMode.soft.toJson(),
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      
      expect(savedHabit.id, isNotNull);
      expect(savedHabit.name, 'Workout Minutes');
      expect(savedHabit.trackingType, TrackingType.value);
      expect(savedHabit.goalType, GoalType.minimum);
      expect(savedHabit.targetValue, 45.0);
      expect(savedHabit.unit, 'minutes');
      expect(savedHabit.timeWindowEnabled, true);
      expect(savedHabit.timeWindowStart, const TimeOfDay(hour: 17, minute: 0));
      expect(savedHabit.timeWindowEnd, const TimeOfDay(hour: 21, minute: 0));
      expect(savedHabit.timeWindowMode, TimeWindowMode.soft.toJson());
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.trackingType, TrackingType.value);
      expect(retrievedHabit.timeWindowEnabled, true);
      expect(retrievedHabit.timeWindowStart, const TimeOfDay(hour: 17, minute: 0));
    });

    // Test editing habit to add time window
    test('Edit habit to add time window configuration', () async {
      // Create habit without time window
      final habit = Habit(
        name: 'Journal',
        description: 'Write in journal',
        icon: '📝',
        color: '0xFF607D8B',
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
      expect(savedHabit.timeWindowEnabled, false);
      
      // Edit to add time window
      final updatedHabit = savedHabit.copyWith(
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 20, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 23, minute: 0),
        timeWindowMode: TimeWindowMode.hard.toJson(),
        updatedAt: DateTime.now(),
      );

      await repository.updateHabit(updatedHabit);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.timeWindowEnabled, true);
      expect(retrievedHabit.timeWindowStart, const TimeOfDay(hour: 20, minute: 0));
      expect(retrievedHabit.timeWindowEnd, const TimeOfDay(hour: 23, minute: 0));
      expect(retrievedHabit.timeWindowMode, TimeWindowMode.hard.toJson());
    });

    // Test editing habit to remove time window
    test('Edit habit to remove time window configuration', () async {
      // Create habit with time window
      final habit = Habit(
        name: 'Breakfast',
        description: 'Eat breakfast',
        icon: '🍳',
        color: '0xFFFFEB3B',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 6, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 10, minute: 0),
        timeWindowMode: TimeWindowMode.hard.toJson(),
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await repository.createHabit(habit);
      expect(savedHabit.timeWindowEnabled, true);
      
      // Edit to remove time window (create new habit object without time window fields)
      final updatedHabit = Habit(
        id: savedHabit.id,
        name: savedHabit.name,
        description: savedHabit.description,
        icon: savedHabit.icon,
        color: savedHabit.color,
        trackingType: savedHabit.trackingType,
        goalType: savedHabit.goalType,
        frequency: savedHabit.frequency,
        activeDaysMode: savedHabit.activeDaysMode,
        requireMode: savedHabit.requireMode,
        timeWindowEnabled: false,
        timeWindowStart: null,
        timeWindowEnd: null,
        timeWindowMode: null,
        qualityLayerEnabled: savedHabit.qualityLayerEnabled,
        createdAt: savedHabit.createdAt,
        updatedAt: DateTime.now(),
      );

      await repository.updateHabit(updatedHabit);
      
      // Verify persistence
      final retrievedHabit = await repository.getHabitById(savedHabit.id!);
      expect(retrievedHabit, isNotNull);
      expect(retrievedHabit!.timeWindowEnabled, false);
      expect(retrievedHabit.timeWindowStart, isNull);
      expect(retrievedHabit.timeWindowEnd, isNull);
      expect(retrievedHabit.timeWindowMode, isNull);
    });
  });
}
