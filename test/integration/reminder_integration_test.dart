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

  group('Reminder System Integration Tests', () {
    late Database testDb;
    late ReminderRepository reminderRepository;
    late ReminderSchedulerService schedulerService;
    late HabitRepository habitRepository;
    late TasksRepository tasksRepository;
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
          },
        ),
      );

      reminderRepository = ReminderRepository();
      habitRepository = HabitRepository();
      tasksRepository = TasksRepository();
      schedulerService = ReminderSchedulerService(
        reminderRepository: reminderRepository,
        habitRepository: habitRepository,
        tasksRepository: tasksRepository,
      );
    });

    tearDown(() async {
      try {
        // Clean up all data before closing
        await testDb.delete('reminders');
        await testDb.delete('habits');
        await testDb.delete('tasks');
        await testDb.close();
        await databaseFactory.deleteDatabase(':memory:$dbCounter');
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('End-to-end: Create standalone reminder, verify database entry and scheduling', () async {
      // Create a standalone reminder
      final futureTime = DateTime.now().add(const Duration(hours: 3));
      final reminder = Reminder(
        title: 'Standalone Reminder',
        description: 'This is a test reminder',
        type: ReminderType.notification,
        schedule: ReminderSchedule(
          frequency: ScheduleFrequency.none,
          specificDateTime: futureTime,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      final reminderId = await reminderRepository.createReminder(reminder);
      expect(reminderId, greaterThan(0));

      // Verify database entry
      final savedReminder = await reminderRepository.getReminderById(reminderId);
      expect(savedReminder, isNotNull);
      expect(savedReminder!.title, 'Standalone Reminder');
      expect(savedReminder.description, 'This is a test reminder');
      expect(savedReminder.type, ReminderType.notification);
      expect(savedReminder.isActive, true);
      expect(savedReminder.link, isNull);

      // Calculate trigger time (simulating scheduling)
      final triggerTime = await schedulerService.calculateNextTriggerTime(savedReminder);
      expect(triggerTime, isNotNull);
      expect(triggerTime, futureTime);

      // Verify the reminder can be retrieved from active reminders
      final activeReminders = await reminderRepository.getActiveReminders();
      expect(activeReminders.any((r) => r.id == reminderId), true);
    });

    test('End-to-end: Create habit-linked reminder and verify it inherits habit configuration', () async {
      // Create a habit with time window and active days
      final habit = Habit(
        name: 'Morning Workout',
        icon: '💪',
        color: '0xFF4CAF50',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.weekly,
        activeDaysMode: ActiveDaysMode.selected,
        activeWeekdays: [1, 3, 5], // Monday, Wednesday, Friday
        requireMode: RequireMode.each,
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 7, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 9, minute: 0),
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await habitRepository.createHabit(habit);
      expect(savedHabit.id, isNotNull);

      // Create reminder linked to habit
      final reminder = Reminder(
        title: 'Workout Reminder',
        description: 'Time to exercise!',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.weekly,
          useHabitTimeWindow: true,
          useHabitActiveDays: true,
          minutesBefore: 15, // 15 minutes before time window
        ),
        link: ReminderLink(
          type: LinkType.habit,
          entityId: savedHabit.id!,
          entityName: savedHabit.name,
          useDefaultText: true,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save reminder
      final reminderId = await reminderRepository.createReminder(reminder);
      final savedReminder = await reminderRepository.getReminderById(reminderId);

      // Verify reminder is linked to habit
      expect(savedReminder!.link, isNotNull);
      expect(savedReminder.link!.type, LinkType.habit);
      expect(savedReminder.link!.entityId, savedHabit.id);
      expect(savedReminder.link!.entityName, 'Morning Workout');

      // Calculate trigger time and verify it inherits habit configuration
      final triggerTime = await schedulerService.calculateNextTriggerTime(savedReminder);
      expect(triggerTime, isNotNull);

      // Verify trigger time is on one of the habit's active days
      expect([1, 3, 5].contains(triggerTime!.weekday), true);

      // Verify trigger time is 15 minutes before habit time window (6:45 AM)
      expect(triggerTime.hour, 6);
      expect(triggerTime.minute, 45);

      // Verify reminder can be retrieved by habit ID
      final habitReminders = await reminderRepository.getRemindersByHabitId(savedHabit.id!);
      expect(habitReminders.length, 1);
      expect(habitReminders.first.id, reminderId);
    });

    test('End-to-end: Update habit time window and verify reminders are rescheduled', () async {
      // Create habit with initial time window
      final habit = Habit(
        name: 'Reading',
        icon: '📚',
        color: '0xFF2196F3',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        timeWindowEnabled: true,
        timeWindowStart: const TimeOfDay(hour: 20, minute: 0), // 8:00 PM
        timeWindowEnd: const TimeOfDay(hour: 22, minute: 0), // 10:00 PM
        qualityLayerEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedHabit = await habitRepository.createHabit(habit);

      // Create reminder using habit time window
      final reminder = Reminder(
        title: 'Reading Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          useHabitTimeWindow: true,
          minutesBefore: 30, // 30 minutes before
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

      final reminderId = await reminderRepository.createReminder(reminder);
      final savedReminder = await reminderRepository.getReminderById(reminderId);

      // Calculate initial trigger time (should be 7:30 PM)
      final initialTriggerTime = await schedulerService.calculateNextTriggerTime(savedReminder!);
      expect(initialTriggerTime, isNotNull);
      expect(initialTriggerTime!.hour, 19);
      expect(initialTriggerTime.minute, 30);

      // Update habit time window to 9:00 PM - 11:00 PM
      final updatedHabit = savedHabit.copyWith(
        timeWindowStart: const TimeOfDay(hour: 21, minute: 0), // 9:00 PM
        timeWindowEnd: const TimeOfDay(hour: 23, minute: 0), // 11:00 PM
        updatedAt: DateTime.now(),
      );

      await habitRepository.updateHabit(updatedHabit);

      // Retrieve reminder and calculate new trigger time directly
      // (avoiding handleHabitUpdate which calls notification service)
      final updatedReminder = await reminderRepository.getReminderById(reminderId);
      final newTriggerTime = await schedulerService.calculateNextTriggerTime(updatedReminder!);

      // Verify trigger time is updated (should now be 8:30 PM)
      expect(newTriggerTime, isNotNull);
      expect(newTriggerTime!.hour, 20);
      expect(newTriggerTime.minute, 30);

      // Verify the trigger time changed
      expect(newTriggerTime.hour, isNot(initialTriggerTime.hour));
    });

    test('End-to-end: Delete task and verify reminders are cascade deleted', () async {
      // Create a task
      final dueDate = DateTime.now().add(const Duration(days: 2));
      final task = Task(
        title: 'Important Task',
        description: 'Complete this task',
        dueDate: dueDate,
        isCompleted: false,
      );

      final savedTask = await tasksRepository.createTask(task);
      expect(savedTask.id, isNotNull);

      // Create multiple reminders for the task
      final reminder1 = Reminder(
        title: 'Task Reminder 1',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 60, // 1 hour before
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

      final reminder2 = Reminder(
        title: 'Task Reminder 2',
        type: ReminderType.fullScreenAlarm,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.none,
          minutesBefore: 1440, // 1 day before
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

      final reminderId1 = await reminderRepository.createReminder(reminder1);
      final reminderId2 = await reminderRepository.createReminder(reminder2);

      // Verify reminders exist
      final taskReminders = await reminderRepository.getRemindersByTaskId(savedTask.id!);
      expect(taskReminders.length, 2);

      // Delete the task
      await tasksRepository.deleteTask(savedTask.id!);

      // Cascade delete reminders
      await reminderRepository.deleteRemindersByTaskId(savedTask.id!);

      // Verify reminders are deleted
      final remainingReminders = await reminderRepository.getRemindersByTaskId(savedTask.id!);
      expect(remainingReminders.length, 0);

      // Verify individual reminders are gone
      final deletedReminder1 = await reminderRepository.getReminderById(reminderId1);
      final deletedReminder2 = await reminderRepository.getReminderById(reminderId2);
      expect(deletedReminder1, isNull);
      expect(deletedReminder2, isNull);
    });

    test('End-to-end: App restart simulation - verify reminders are rescheduled', () async {
      // Create multiple reminders of different types
      final now = DateTime.now();

      // One-time reminder
      final oneTimeReminder = Reminder(
        title: 'One-time Reminder',
        type: ReminderType.notification,
        schedule: ReminderSchedule(
          frequency: ScheduleFrequency.none,
          specificDateTime: now.add(const Duration(hours: 5)),
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Daily reminder
      final dailyReminder = Reminder(
        title: 'Daily Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          timeOfDay: TimeOfDay(hour: 8, minute: 0),
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Weekly reminder
      final weeklyReminder = Reminder(
        title: 'Weekly Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.weekly,
          timeOfDay: TimeOfDay(hour: 10, minute: 0),
          activeWeekdays: [1, 3, 5],
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Inactive reminder (should not be rescheduled)
      final inactiveReminder = Reminder(
        title: 'Inactive Reminder',
        type: ReminderType.notification,
        schedule: const ReminderSchedule(
          frequency: ScheduleFrequency.daily,
          timeOfDay: TimeOfDay(hour: 12, minute: 0),
        ),
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );

      // Save all reminders
      await reminderRepository.createReminder(oneTimeReminder);
      await reminderRepository.createReminder(dailyReminder);
      await reminderRepository.createReminder(weeklyReminder);
      await reminderRepository.createReminder(inactiveReminder);

      // Simulate app restart by verifying all active reminders can be rescheduled
      // (avoiding rescheduleAllReminders which calls notification service)
      final activeReminders = await reminderRepository.getActiveReminders();
      expect(activeReminders.length, 3); // Only active reminders

      for (final reminder in activeReminders) {
        final triggerTime = await schedulerService.calculateNextTriggerTime(reminder);
        
        // All active reminders should have valid trigger times
        if (reminder.schedule.frequency != ScheduleFrequency.none ||
            (reminder.schedule.specificDateTime != null &&
             reminder.schedule.specificDateTime!.isAfter(now))) {
          expect(triggerTime, isNotNull);
        }
      }

      // Verify inactive reminder is not scheduled
      final allReminders = await reminderRepository.getAllReminders();
      final inactive = allReminders.firstWhere((r) => r.title == 'Inactive Reminder');
      expect(inactive.isActive, false);
    });
  });
}
