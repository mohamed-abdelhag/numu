import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:numu/features/reminders/models/reminder.dart';
import 'package:numu/features/reminders/models/reminder_type.dart';
import 'package:numu/features/reminders/models/reminder_schedule.dart';
import 'package:numu/features/reminders/models/reminder_link.dart';
import 'package:numu/features/reminders/repositories/reminder_repository.dart';
import 'package:numu/features/reminders/services/reminder_scheduler_service.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/habits/models/enums/tracking_type.dart';
import 'package:numu/features/habits/models/enums/goal_type.dart';
import 'package:numu/features/habits/models/enums/frequency.dart';
import 'package:numu/features/habits/models/enums/active_days_mode.dart';
import 'package:numu/features/habits/models/enums/require_mode.dart';
import 'package:numu/features/habits/repositories/habit_repository.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/tasks/tasks_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reminder Model Serialization Tests', () {
    test(
      'Reminder with notification type serializes and deserializes correctly',
      () {
        final now = DateTime.now();
        final reminder = Reminder(
          id: 1,
          title: 'Test Reminder',
          description: 'Test Description',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(
            frequency: ScheduleFrequency.daily,
            timeOfDay: TimeOfDay(hour: 9, minute: 0),
          ),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final map = reminder.toMap();
        final deserialized = Reminder.fromMap(map);

        expect(deserialized.id, reminder.id);
        expect(deserialized.title, reminder.title);
        expect(deserialized.description, reminder.description);
        expect(deserialized.type, reminder.type);
        expect(deserialized.schedule.frequency, reminder.schedule.frequency);
        expect(deserialized.schedule.timeOfDay, reminder.schedule.timeOfDay);
        expect(deserialized.isActive, reminder.isActive);
      },
    );

    test('Reminder with full-screen alarm type serializes correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Alarm Reminder',
        type: ReminderType.fullScreenAlarm,
        schedule: ReminderSchedule(
          frequency: ScheduleFrequency.none,
          specificDateTime: DateTime(2025, 12, 25, 8, 0),
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      final deserialized = Reminder.fromMap(map);

      expect(deserialized.type, ReminderType.fullScreenAlarm);
      expect(deserialized.schedule.frequency, ScheduleFrequency.none);
      expect(deserialized.schedule.specificDateTime, isNotNull);
    });

    test('Reminder with habit link serializes and deserializes correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Habit Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          timeOfDay: TimeOfDay(hour: 7, minute: 30),
          useHabitTimeWindow: true,
        ),
        link: const ReminderLink(
          type: LinkType.habit,
          entityId: 5,
          entityName: 'Morning Exercise',
          useDefaultText: true,
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      final deserialized = Reminder.fromMap(map);

      expect(deserialized.link, isNotNull);
      expect(deserialized.link!.type, LinkType.habit);
      expect(deserialized.link!.entityId, 5);
      expect(deserialized.link!.entityName, 'Morning Exercise');
      expect(deserialized.link!.useDefaultText, true);
      expect(deserialized.schedule.useHabitTimeWindow, true);
    });

    test('Reminder with task link serializes correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Task Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 60,
        ),
        link: const ReminderLink(
          type: LinkType.task,
          entityId: 10,
          entityName: 'Complete Project',
          useDefaultText: false,
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      final deserialized = Reminder.fromMap(map);

      expect(deserialized.link!.type, LinkType.task);
      expect(deserialized.link!.entityId, 10);
      expect(deserialized.schedule.minutesBefore, 60);
    });

    test('Weekly reminder with active weekdays serializes correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Weekly Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.weekly,
          timeOfDay: TimeOfDay(hour: 10, minute: 0),
          activeWeekdays: [1, 3, 5], // Monday, Wednesday, Friday
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      final deserialized = Reminder.fromMap(map);

      expect(deserialized.schedule.frequency, ScheduleFrequency.weekly);
      expect(deserialized.schedule.activeWeekdays, [1, 3, 5]);
    });

    test('Monthly reminder with day of month serializes correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Monthly Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.monthly,
          timeOfDay: TimeOfDay(hour: 12, minute: 0),
          dayOfMonth: 15,
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      final deserialized = Reminder.fromMap(map);

      expect(deserialized.schedule.frequency, ScheduleFrequency.monthly);
      expect(deserialized.schedule.dayOfMonth, 15);
    });
  });

  group('Reminder Repository CRUD Tests', () {
    late Database testDb;
    late ReminderRepository repository;
    int dbCounter = 0;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    tearDown(() async {
      try {
        await testDb.close();
        await databaseFactory.deleteDatabase(':memory:$dbCounter');
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    Future<void> setupDatabase() async {
      dbCounter++;
      testDb = await databaseFactory.openDatabase(
        ':memory:$dbCounter',
        options: OpenDatabaseOptions(
          version: 9,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE reminders (
                reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                reminder_type TEXT NOT NULL,
                frequency TEXT NOT NULL,
                specific_date_time TEXT,
                time_of_day TEXT,
                active_weekdays TEXT,
                day_of_month INTEGER,
                minutes_before INTEGER,
                use_habit_time_window INTEGER NOT NULL DEFAULT 0,
                use_habit_active_days INTEGER NOT NULL DEFAULT 0,
                link_type TEXT,
                link_entity_id INTEGER,
                link_entity_name TEXT,
                use_default_text INTEGER NOT NULL DEFAULT 1,
                is_active INTEGER NOT NULL DEFAULT 1,
                next_trigger_time TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      repository = ReminderRepository();
    }

    test('Create reminder and retrieve by ID', () async {
      await setupDatabase();

      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Test Reminder',
        description: 'Test Description',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          timeOfDay: TimeOfDay(hour: 9, minute: 0),
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.createReminder(reminder);
      expect(id, greaterThan(0));

      final retrieved = await repository.getReminderById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Reminder');
      expect(retrieved.type, ReminderType.notification);
    });

    test('Get all reminders returns correct list', () async {
      await setupDatabase();

      final now = DateTime.now();

      // Create multiple reminders
      await repository.createReminder(
        Reminder(
          title: 'Reminder 1',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.createReminder(
        Reminder(
          title: 'Reminder 2',
          type: ReminderType.fullScreenAlarm,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.weekly),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final allReminders = await repository.getAllReminders();
      expect(allReminders.length, 2);
    });

    test('Get active reminders filters correctly', () async {
      await setupDatabase();

      final now = DateTime.now();

      await repository.createReminder(
        Reminder(
          title: 'Active Reminder',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.createReminder(
        Reminder(
          title: 'Inactive Reminder',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
          isActive: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final activeReminders = await repository.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.title, 'Active Reminder');
    });

    test('Update reminder modifies existing record', () async {
      await setupDatabase();

      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Original Title',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.createReminder(reminder);
      final retrieved = await repository.getReminderById(id);

      final updated = retrieved!.copyWith(
        title: 'Updated Title',
        isActive: false,
      );

      await repository.updateReminder(updated);

      final afterUpdate = await repository.getReminderById(id);
      expect(afterUpdate!.title, 'Updated Title');
      expect(afterUpdate.isActive, false);
    });

    test('Delete reminder removes record', () async {
      await setupDatabase();

      final now = DateTime.now();
      final reminder = Reminder(
        title: 'To Delete',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.createReminder(reminder);
      await repository.deleteReminder(id);

      final retrieved = await repository.getReminderById(id);
      expect(retrieved, isNull);
    });

    test('Get reminders by habit ID filters correctly', () async {
      await setupDatabase();

      final now = DateTime.now();

      await repository.createReminder(
        Reminder(
          title: 'Habit 1 Reminder',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
          link: const ReminderLink(
            type: LinkType.habit,
            entityId: 1,
            entityName: 'Habit 1',
          ),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.createReminder(
        Reminder(
          title: 'Habit 2 Reminder',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
          link: const ReminderLink(
            type: LinkType.habit,
            entityId: 2,
            entityName: 'Habit 2',
          ),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final habit1Reminders = await repository.getRemindersByHabitId(1);
      expect(habit1Reminders.length, 1);
      expect(habit1Reminders.first.title, 'Habit 1 Reminder');
    });

    test('Delete reminders by habit ID removes all linked reminders', () async {
      await setupDatabase();

      final now = DateTime.now();

      await repository.createReminder(
        Reminder(
          title: 'Habit Reminder 1',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.daily),
          link: const ReminderLink(
            type: LinkType.habit,
            entityId: 5,
            entityName: 'Test Habit',
          ),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.createReminder(
        Reminder(
          title: 'Habit Reminder 2',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(frequency: ScheduleFrequency.weekly),
          link: const ReminderLink(
            type: LinkType.habit,
            entityId: 5,
            entityName: 'Test Habit',
          ),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.deleteRemindersByHabitId(5);

      final remainingReminders = await repository.getRemindersByHabitId(5);
      expect(remainingReminders.length, 0);
    });
  });

  group('Reminder Scheduler Service - Trigger Time Calculations', () {
    late ReminderSchedulerService scheduler;

    setUp(() {
      scheduler = ReminderSchedulerService();
    });

    test('One-time reminder calculates correct trigger time', () async {
      final futureTime = DateTime.now().add(const Duration(hours: 2));
      final reminder = Reminder(
        title: 'One-time Reminder',
        type: ReminderType.notification,
        schedule: ReminderSchedule(
          frequency: ScheduleFrequency.none,
          specificDateTime: futureTime,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, futureTime);
    });

    test('One-time reminder in the past returns null', () async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));
      final reminder = Reminder(
        title: 'Past Reminder',
        type: ReminderType.notification,
        schedule: ReminderSchedule(
          frequency: ScheduleFrequency.none,
          specificDateTime: pastTime,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNull);
    });

    test('Daily reminder calculates next occurrence', () async {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Daily Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          timeOfDay: TimeOfDay(hour: 9, minute: 0),
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);
      expect(triggerTime!.hour, 9);
      expect(triggerTime.minute, 0);
      expect(triggerTime.isAfter(now), true);
    });

    test('Weekly reminder calculates next active weekday', () async {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Weekly Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.weekly,
          timeOfDay: TimeOfDay(hour: 10, minute: 0),
          activeWeekdays: [1, 3, 5], // Monday, Wednesday, Friday
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);
      expect([1, 3, 5].contains(triggerTime!.weekday), true);
      expect(triggerTime.hour, 10);
      expect(triggerTime.minute, 0);
    });

    test('Monthly reminder calculates correct day of month', () async {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Monthly Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.monthly,
          timeOfDay: TimeOfDay(hour: 12, minute: 0),
          dayOfMonth: 15,
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);
      expect(triggerTime!.day, 15);
      expect(triggerTime.hour, 12);
      expect(triggerTime.minute, 0);
    });

    test('Monthly reminder handles month-end edge case', () async {
      final now = DateTime.now();
      final reminder = Reminder(
        title: 'Month-end Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.monthly,
          timeOfDay: TimeOfDay(hour: 12, minute: 0),
          dayOfMonth: 31, // Not all months have 31 days
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);
      // Should use last day of month if 31 doesn't exist
      expect(triggerTime!.day, lessThanOrEqualTo(31));
    });
  });

  group('Reminder Scheduler Service - Habit Integration', () {
    late Database testDb;
    late HabitRepository habitRepository;
    late ReminderRepository reminderRepository;
    late ReminderSchedulerService scheduler;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
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

            // Create reminders table
            await db.execute('''
              CREATE TABLE reminders (
                reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                reminder_type TEXT NOT NULL,
                frequency TEXT NOT NULL,
                specific_date_time TEXT,
                time_of_day TEXT,
                active_weekdays TEXT,
                day_of_month INTEGER,
                minutes_before INTEGER,
                use_habit_time_window INTEGER NOT NULL DEFAULT 0,
                use_habit_active_days INTEGER NOT NULL DEFAULT 0,
                link_type TEXT,
                link_entity_id INTEGER,
                link_entity_name TEXT,
                use_default_text INTEGER NOT NULL DEFAULT 1,
                is_active INTEGER NOT NULL DEFAULT 1,
                next_trigger_time TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      habitRepository = HabitRepository();
      reminderRepository = ReminderRepository();
      scheduler = ReminderSchedulerService(
        habitRepository: habitRepository,
        reminderRepository: reminderRepository,
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Habit-linked reminder uses habit time window', () async {
      // Create habit with time window
      final habit = Habit(
        name: 'Morning Exercise',
        icon: '💪',
        color: '0xFF4CAF50',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 7, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 9, minute: 0),
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await habitRepository.createHabit(habit);

      // Create reminder linked to habit with time window
      final reminder = Reminder(
        title: 'Exercise Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          useHabitTimeWindow: true,
          minutesBefore: 15, // 15 minutes before time window
        ),
        link: ReminderLink(
          type: LinkType.habit,
          entityId: savedHabit.id!,
          entityName: savedHabit.name,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);
      // Should be 6:45 AM (7:00 - 15 minutes)
      expect(triggerTime!.hour, 6);
      expect(triggerTime.minute, 45);
    });

    test('Habit-linked reminder uses habit active days', () async {
      // Create habit with specific active days (Monday, Wednesday, Friday)
      final habit = Habit(
        name: 'Gym Workout',
        icon: '🏋️',
        color: '0xFFE91E63',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.weekly,
        activeDaysMode: ActiveDaysMode.selected,
        activeWeekdays: [1, 3, 5], // Monday, Wednesday, Friday
        requireMode: RequireMode.each,
        timeWindowEnabled: false,
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await habitRepository.createHabit(habit);

      // Create reminder linked to habit with active days
      final reminder = Reminder(
        title: 'Gym Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.weekly,
          timeOfDay: TimeOfDay(hour: 18, minute: 0),
          useHabitActiveDays: true,
        ),
        link: ReminderLink(
          type: LinkType.habit,
          entityId: savedHabit.id!,
          entityName: savedHabit.name,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);
      // Should be on Monday, Wednesday, or Friday
      expect([1, 3, 5].contains(triggerTime!.weekday), true);
      expect(triggerTime.hour, 18);
      expect(triggerTime.minute, 0);
    });

    test(
      'Habit-linked reminder with both time window and active days',
      () async {
        // Create habit with time window and active days
        final habit = Habit(
          name: 'Morning Meditation',
          icon: '🧘',
          color: '0xFF2196F3',
          trackingType: TrackingType.binary,
          goalType: GoalType.minimum,
          frequency: Frequency.weekly,
          activeDaysMode: ActiveDaysMode.selected,
          activeWeekdays: [1, 2, 3, 4, 5], // Weekdays
          requireMode: RequireMode.each,
          timeWindowEnabled: true,
          timeWindowStart: const TimeOfDay(hour: 6, minute: 0),
          timeWindowEnd: const TimeOfDay(hour: 8, minute: 0),
          qualityLayerEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final savedHabit = await habitRepository.createHabit(habit);

        // Create reminder using both configurations
        final reminder = Reminder(
          title: 'Meditation Reminder',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(
            frequency: ScheduleFrequency.weekly,
            useHabitTimeWindow: true,
            useHabitActiveDays: true,
            minutesBefore: 10,
          ),
          link: ReminderLink(
            type: LinkType.habit,
            entityId: savedHabit.id!,
            entityName: savedHabit.name,
          ),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
        expect(triggerTime, isNotNull);
        // Should be on a weekday
        expect([1, 2, 3, 4, 5].contains(triggerTime!.weekday), true);
        // Should be 5:50 AM (6:00 - 10 minutes)
        expect(triggerTime.hour, 5);
        expect(triggerTime.minute, 50);
      },
    );
  });

  group('Reminder Scheduler Service - Task Integration', () {
    late Database testDb;
    late TasksRepository tasksRepository;
    late ReminderRepository reminderRepository;
    late ReminderSchedulerService scheduler;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 9,
          onCreate: (db, version) async {
            // Create tasks table
            await db.execute('''
              CREATE TABLE tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                due_date TEXT,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                category_id INTEGER,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
              )
            ''');

            // Create reminders table
            await db.execute('''
              CREATE TABLE reminders (
                reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                reminder_type TEXT NOT NULL,
                frequency TEXT NOT NULL,
                specific_date_time TEXT,
                time_of_day TEXT,
                active_weekdays TEXT,
                day_of_month INTEGER,
                minutes_before INTEGER,
                use_habit_time_window INTEGER NOT NULL DEFAULT 0,
                use_habit_active_days INTEGER NOT NULL DEFAULT 0,
                link_type TEXT,
                link_entity_id INTEGER,
                link_entity_name TEXT,
                use_default_text INTEGER NOT NULL DEFAULT 1,
                is_active INTEGER NOT NULL DEFAULT 1,
                next_trigger_time TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      tasksRepository = TasksRepository();
      reminderRepository = ReminderRepository();
      scheduler = ReminderSchedulerService(
        tasksRepository: tasksRepository,
        reminderRepository: reminderRepository,
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Task-linked reminder calculates time based on due date', () async {
      // Create task with due date
      final dueDate = DateTime.now().add(const Duration(days: 2));
      final task = Task(
        title: 'Complete Project',
        description: 'Finish the project report',
        dueDate: dueDate,
        isCompleted: false,
      );

      final savedTask = await tasksRepository.createTask(task);

      // Create reminder 1 hour before task due date
      final reminder = Reminder(
        title: 'Project Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 60,
        ),
        link: ReminderLink(
          type: LinkType.task,
          entityId: savedTask.id!,
          entityName: savedTask.title,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNotNull);

      // Should be 1 hour before due date
      final expectedTime = dueDate.subtract(const Duration(hours: 1));
      expect(
        triggerTime!.difference(expectedTime).inMinutes.abs(),
        lessThan(1),
      );
    });

    test('Task-linked reminder returns null for completed task', () async {
      // Create completed task
      final task = Task(
        title: 'Completed Task',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isCompleted: true,
      );

      final savedTask = await tasksRepository.createTask(task);

      // Create reminder for completed task
      final reminder = Reminder(
        title: 'Task Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 30,
        ),
        link: ReminderLink(
          type: LinkType.task,
          entityId: savedTask.id!,
          entityName: savedTask.title,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNull); // Should not schedule for completed tasks
    });

    test(
      'Task-linked reminder returns null for task without due date',
      () async {
        // Create task without due date
        final task = Task(title: 'No Due Date Task', isCompleted: false);

        final savedTask = await tasksRepository.createTask(task);

        // Create reminder for task without due date
        final reminder = Reminder(
          title: 'Task Reminder',
          type: ReminderType.notification,
          schedule: const ReminderSchedule(
            frequency: ScheduleFrequency.none,
            minutesBefore: 60,
          ),
          link: ReminderLink(
            type: LinkType.task,
            entityId: savedTask.id!,
            entityName: savedTask.title,
          ),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
        expect(triggerTime, isNull); // Should not schedule without due date
      },
    );

    test('Task-linked reminder with past due date returns null', () async {
      // Create task with past due date
      final pastDueDate = DateTime.now().subtract(const Duration(days: 1));
      final task = Task(
        title: 'Overdue Task',
        dueDate: pastDueDate,
        isCompleted: false,
      );

      final savedTask = await tasksRepository.createTask(task);

      // Create reminder for overdue task
      final reminder = Reminder(
        title: 'Overdue Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 60,
        ),
        link: ReminderLink(
          type: LinkType.task,
          entityId: savedTask.id!,
          entityName: savedTask.title,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime = await scheduler.calculateNextTriggerTime(reminder);
      expect(triggerTime, isNull); // Should not schedule for past due dates
    });

    test('Task-linked reminder with different offset values', () async {
      final dueDate = DateTime.now().add(const Duration(days: 3));
      final task = Task(
        title: 'Important Task',
        dueDate: dueDate,
        isCompleted: false,
      );

      final savedTask = await tasksRepository.createTask(task);

      // Test 1 day before
      final reminder1Day = Reminder(
        title: '1 Day Before',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 1440, // 24 hours
        ),
        link: ReminderLink(
          type: LinkType.task,
          entityId: savedTask.id!,
          entityName: savedTask.title,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime1Day = await scheduler.calculateNextTriggerTime(
        reminder1Day,
      );
      expect(triggerTime1Day, isNotNull);

      final expected1Day = dueDate.subtract(const Duration(days: 1));
      expect(
        triggerTime1Day!.difference(expected1Day).inMinutes.abs(),
        lessThan(1),
      );

      // Test 15 minutes before
      final reminder15Min = Reminder(
        title: '15 Minutes Before',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 15,
        ),
        link: ReminderLink(
          type: LinkType.task,
          entityId: savedTask.id!,
          entityName: savedTask.title,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final triggerTime15Min = await scheduler.calculateNextTriggerTime(
        reminder15Min,
      );
      expect(triggerTime15Min, isNotNull);

      final expected15Min = dueDate.subtract(const Duration(minutes: 15));
      expect(
        triggerTime15Min!.difference(expected15Min).inMinutes.abs(),
        lessThan(1),
      );
    });
  });
}
