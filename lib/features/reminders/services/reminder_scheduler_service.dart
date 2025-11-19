import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../models/reminder_schedule.dart';
import '../models/reminder_link.dart';
import '../models/reminder_type.dart';
import '../repositories/reminder_repository.dart';
import '../../habits/models/habit.dart';
import '../../habits/repositories/habit_repository.dart';
import '../../tasks/tasks_repository.dart';
import 'notification_service.dart';
import 'alarm_service.dart';

/// Service for calculating and managing reminder scheduling logic
/// 
/// This service handles:
/// - Calculating next trigger times for all reminder types
/// - Scheduling reminders with appropriate services (notification/alarm)
/// - Rescheduling reminders when linked entities change
/// - Handling habit time window and active days integration
/// - Handling task due date offsets
class ReminderSchedulerService {
  final ReminderRepository _reminderRepository;
  final HabitRepository _habitRepository;
  final TasksRepository _tasksRepository;
  final NotificationService _notificationService;
  final AlarmService _alarmService;

  ReminderSchedulerService({
    ReminderRepository? reminderRepository,
    HabitRepository? habitRepository,
    TasksRepository? tasksRepository,
    NotificationService? notificationService,
    AlarmService? alarmService,
  })  : _reminderRepository = reminderRepository ?? ReminderRepository(),
        _habitRepository = habitRepository ?? HabitRepository(),
        _tasksRepository = tasksRepository ?? TasksRepository(),
        _notificationService = notificationService ?? NotificationService(),
        _alarmService = alarmService ?? AlarmService();

  /// Calculate the next trigger time for a reminder
  /// 
  /// Returns null if the reminder cannot be scheduled (e.g., past one-time reminder)
  /// Handles all frequency types and linked entity configurations
  Future<DateTime?> calculateNextTriggerTime(Reminder reminder) async {
    final schedule = reminder.schedule;
    final now = DateTime.now();

    // Handle linked reminders with special logic
    if (reminder.link != null) {
      return await _calculateLinkedReminderTime(reminder, now);
    }

    // Handle standalone reminders based on frequency
    switch (schedule.frequency) {
      case ScheduleFrequency.none:
        return _calculateOneTimeReminderTime(schedule, now);
      
      case ScheduleFrequency.daily:
        return _calculateDailyReminderTime(schedule, now);
      
      case ScheduleFrequency.weekly:
        return _calculateWeeklyReminderTime(schedule, now);
      
      case ScheduleFrequency.monthly:
        return _calculateMonthlyReminderTime(schedule, now);
    }
  }

  /// Calculate trigger time for linked reminders (habit or task)
  Future<DateTime?> _calculateLinkedReminderTime(
    Reminder reminder,
    DateTime now,
  ) async {
    final link = reminder.link!;

    if (link.type == LinkType.habit) {
      return await _calculateHabitLinkedReminderTime(reminder, now);
    } else {
      return await _calculateTaskLinkedReminderTime(reminder, now);
    }
  }

  /// Calculate trigger time for habit-linked reminders
  Future<DateTime?> _calculateHabitLinkedReminderTime(
    Reminder reminder,
    DateTime now,
  ) async {
    final link = reminder.link!;
    final schedule = reminder.schedule;

    // Fetch the linked habit
    final habit = await _habitRepository.getHabitById(link.entityId);
    if (habit == null) {
      return null; // Habit no longer exists
    }

    // If using habit time window
    if (schedule.useHabitTimeWindow && habit.timeWindowEnabled) {
      return _calculateHabitTimeWindowReminder(habit, schedule, now);
    }

    // If using habit active days
    if (schedule.useHabitActiveDays && habit.activeWeekdays != null) {
      return _calculateHabitActiveDaysReminder(habit, schedule, now);
    }

    // Otherwise, use standard scheduling with habit's frequency
    return _calculateStandardHabitReminder(habit, schedule, now);
  }

  /// Calculate reminder time based on habit time window
  DateTime? _calculateHabitTimeWindowReminder(
    Habit habit,
    ReminderSchedule schedule,
    DateTime now,
  ) {
    if (habit.timeWindowStart == null) {
      return null;
    }

    final minutesBefore = schedule.minutesBefore ?? 0;
    final timeWindow = habit.timeWindowStart!;

    // Calculate base time from time window
    DateTime baseTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeWindow.hour,
      timeWindow.minute,
    );

    // Subtract minutes before
    baseTime = baseTime.subtract(Duration(minutes: minutesBefore));

    // If time has passed today, move to next valid day
    if (baseTime.isBefore(now)) {
      baseTime = baseTime.add(const Duration(days: 1));
    }

    // Apply habit active days filter if enabled
    if (schedule.useHabitActiveDays && habit.activeWeekdays != null) {
      baseTime = _findNextActiveDay(baseTime, habit.activeWeekdays!);
    }

    return baseTime;
  }

  /// Calculate reminder time based on habit active days
  DateTime? _calculateHabitActiveDaysReminder(
    Habit habit,
    ReminderSchedule schedule,
    DateTime now,
  ) {
    if (habit.activeWeekdays == null || habit.activeWeekdays!.isEmpty) {
      return null;
    }

    // Use time of day from schedule or default to 9:00 AM
    final timeOfDay = schedule.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0);

    DateTime baseTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If time has passed today, move to tomorrow
    if (baseTime.isBefore(now)) {
      baseTime = baseTime.add(const Duration(days: 1));
    }

    // Find next active day
    return _findNextActiveDay(baseTime, habit.activeWeekdays!);
  }

  /// Calculate standard habit reminder (daily/weekly/monthly)
  DateTime? _calculateStandardHabitReminder(
    Habit habit,
    ReminderSchedule schedule,
    DateTime now,
  ) {
    // Use schedule frequency or fall back to daily
    switch (schedule.frequency) {
      case ScheduleFrequency.none:
        return _calculateOneTimeReminderTime(schedule, now);
      case ScheduleFrequency.daily:
        return _calculateDailyReminderTime(schedule, now);
      case ScheduleFrequency.weekly:
        return _calculateWeeklyReminderTime(schedule, now);
      case ScheduleFrequency.monthly:
        return _calculateMonthlyReminderTime(schedule, now);
    }
  }

  /// Calculate trigger time for task-linked reminders
  Future<DateTime?> _calculateTaskLinkedReminderTime(
    Reminder reminder,
    DateTime now,
  ) async {
    final link = reminder.link!;

    // Fetch the linked task
    final task = await _tasksRepository.getTaskById(link.entityId);
    if (task == null || task.dueDate == null) {
      return null; // Task no longer exists or has no due date
    }

    // If task is completed, don't schedule reminder
    if (task.isCompleted) {
      return null;
    }

    // Calculate reminder time: due date minus minutes before
    final minutesBefore = reminder.schedule.minutesBefore ?? 0;
    final reminderTime = task.dueDate!.subtract(Duration(minutes: minutesBefore));

    // Only schedule if reminder time is in the future
    if (reminderTime.isBefore(now)) {
      return null;
    }

    return reminderTime;
  }

  /// Calculate one-time reminder trigger time
  DateTime? _calculateOneTimeReminderTime(
    ReminderSchedule schedule,
    DateTime now,
  ) {
    if (schedule.specificDateTime == null) {
      return null;
    }

    // Only schedule if time is in the future
    if (schedule.specificDateTime!.isBefore(now)) {
      return null;
    }

    return schedule.specificDateTime;
  }

  /// Calculate daily reminder trigger time
  DateTime? _calculateDailyReminderTime(
    ReminderSchedule schedule,
    DateTime now,
  ) {
    if (schedule.timeOfDay == null) {
      return null;
    }

    final timeOfDay = schedule.timeOfDay!;
    DateTime nextTrigger = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (nextTrigger.isBefore(now) || nextTrigger.isAtSameMomentAs(now)) {
      nextTrigger = nextTrigger.add(const Duration(days: 1));
    }

    return nextTrigger;
  }

  /// Calculate weekly reminder trigger time
  DateTime? _calculateWeeklyReminderTime(
    ReminderSchedule schedule,
    DateTime now,
  ) {
    if (schedule.timeOfDay == null || 
        schedule.activeWeekdays == null || 
        schedule.activeWeekdays!.isEmpty) {
      return null;
    }

    final timeOfDay = schedule.timeOfDay!;
    DateTime nextTrigger = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If time has passed today, start from tomorrow
    if (nextTrigger.isBefore(now) || nextTrigger.isAtSameMomentAs(now)) {
      nextTrigger = nextTrigger.add(const Duration(days: 1));
    }

    // Find next active weekday
    return _findNextActiveDay(nextTrigger, schedule.activeWeekdays!);
  }

  /// Calculate monthly reminder trigger time
  DateTime? _calculateMonthlyReminderTime(
    ReminderSchedule schedule,
    DateTime now,
  ) {
    if (schedule.timeOfDay == null || schedule.dayOfMonth == null) {
      return null;
    }

    final timeOfDay = schedule.timeOfDay!;
    final dayOfMonth = schedule.dayOfMonth!;

    // Start with current month
    DateTime nextTrigger = _createDateTimeForDayOfMonth(
      now.year,
      now.month,
      dayOfMonth,
      timeOfDay,
    );

    // If time has passed this month, move to next month
    if (nextTrigger.isBefore(now) || nextTrigger.isAtSameMomentAs(now)) {
      // Move to next month
      int nextMonth = now.month + 1;
      int nextYear = now.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      nextTrigger = _createDateTimeForDayOfMonth(
        nextYear,
        nextMonth,
        dayOfMonth,
        timeOfDay,
      );
    }

    return nextTrigger;
  }

  /// Helper to create DateTime for a specific day of month, handling month-end edge cases
  DateTime _createDateTimeForDayOfMonth(
    int year,
    int month,
    int dayOfMonth,
    TimeOfDay timeOfDay,
  ) {
    // Get the last day of the month
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    
    // Use the smaller of dayOfMonth or lastDayOfMonth
    final actualDay = dayOfMonth > lastDayOfMonth ? lastDayOfMonth : dayOfMonth;

    return DateTime(
      year,
      month,
      actualDay,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  /// Find the next day that matches one of the active weekdays
  /// weekdays: 1-7 (Monday-Sunday)
  DateTime _findNextActiveDay(DateTime startDate, List<int> activeWeekdays) {
    DateTime current = startDate;
    
    // Search up to 7 days ahead to find next active day
    for (int i = 0; i < 7; i++) {
      final weekday = current.weekday; // 1-7 (Monday-Sunday)
      if (activeWeekdays.contains(weekday)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }

    // Fallback: return start date if no active day found (shouldn't happen)
    return startDate;
  }

  /// Schedule a reminder with the appropriate service (notification or alarm)
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isActive) {
      return; // Don't schedule inactive reminders
    }

    // Calculate next trigger time
    final triggerTime = await calculateNextTriggerTime(reminder);
    if (triggerTime == null) {
      return; // Cannot schedule this reminder
    }

    // Update next trigger time in database
    if (reminder.id != null) {
      await _reminderRepository.updateNextTriggerTime(reminder.id!, triggerTime);
    }

    // Delegate to appropriate service based on reminder type
    if (reminder.type == ReminderType.notification) {
      await _notificationService.scheduleNotification(reminder, triggerTime);
    } else {
      await _alarmService.scheduleAlarm(reminder, triggerTime);
    }
  }

  /// Reschedule an existing reminder
  /// 
  /// Cancels the old schedule and creates a new one with updated trigger time
  Future<void> rescheduleReminder(Reminder reminder) async {
    if (reminder.id == null) {
      return;
    }

    // Cancel existing schedule
    if (reminder.type == ReminderType.notification) {
      await _notificationService.cancelNotification(reminder.id!);
    } else {
      await _alarmService.cancelAlarm(reminder.id!);
    }

    // Schedule with new trigger time
    await scheduleReminder(reminder);
  }

  /// Reschedule all active reminders
  /// 
  /// Called on app launch to refresh the notification queue
  Future<void> rescheduleAllReminders() async {
    final reminders = await _reminderRepository.getActiveReminders();
    
    for (final reminder in reminders) {
      await rescheduleReminder(reminder);
    }
  }

  /// Handle habit updates by recalculating linked reminder trigger times
  /// 
  /// Called when a habit's time window or active days change
  Future<void> handleHabitUpdate(int habitId) async {
    // Get all reminders linked to this habit
    final reminders = await _reminderRepository.getRemindersByHabitId(habitId);
    
    for (final reminder in reminders) {
      if (reminder.isActive) {
        await rescheduleReminder(reminder);
      }
    }
  }

  /// Handle task updates by recalculating linked reminder trigger times
  /// 
  /// Called when a task's due date changes or completion status changes
  Future<void> handleTaskUpdate(int taskId) async {
    // Get all reminders linked to this task
    final reminders = await _reminderRepository.getRemindersByTaskId(taskId);
    
    // Fetch the task to check completion status
    final task = await _tasksRepository.getTaskById(taskId);
    
    for (final reminder in reminders) {
      if (task != null && task.isCompleted) {
        // Cancel reminders for completed tasks
        if (reminder.id != null) {
          if (reminder.type == ReminderType.notification) {
            await _notificationService.cancelNotification(reminder.id!);
          } else {
            await _alarmService.cancelAlarm(reminder.id!);
          }
        }
      } else if (reminder.isActive) {
        // Reschedule active reminders for incomplete tasks
        await rescheduleReminder(reminder);
      }
    }
  }

  /// Mark one-time reminders as inactive after they trigger
  /// 
  /// Should be called after a one-time reminder is delivered
  Future<void> markOneTimeReminderAsInactive(int reminderId) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null) {
      return;
    }

    // Only mark as inactive if it's a one-time reminder
    if (reminder.schedule.frequency == ScheduleFrequency.none) {
      final updatedReminder = reminder.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _reminderRepository.updateReminder(updatedReminder);
    }
  }

  /// Calculate and schedule the next occurrence for repeating reminders
  /// 
  /// Should be called after a repeating reminder is delivered
  Future<void> scheduleNextOccurrence(int reminderId) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null || !reminder.isActive) {
      return;
    }

    // Only reschedule if it's a repeating reminder
    if (reminder.schedule.frequency != ScheduleFrequency.none) {
      await rescheduleReminder(reminder);
    }
  }
}
