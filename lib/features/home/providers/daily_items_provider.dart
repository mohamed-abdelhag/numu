import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/daily_item.dart';
import '../../habits/models/habit.dart';
import '../../habits/models/enums/active_days_mode.dart';
import '../../habits/models/enums/goal_type.dart';
import '../../habits/repositories/habit_repository.dart';
import '../../tasks/tasks_repository.dart';
import '../../tasks/task.dart';
import '../../islamic/models/enums/prayer_type.dart';
import '../../islamic/models/enums/prayer_status.dart';
import '../../islamic/repositories/prayer_repository.dart';
import '../../islamic/repositories/prayer_settings_repository.dart';
import '../../islamic/services/prayer_time_service.dart';
import '../../islamic/services/prayer_location_service.dart';
import '../../islamic/services/prayer_status_service.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'daily_items_provider.g.dart';

class DailyItemsState {
  final List<DailyItem> items;
  final int completionPercentage;
  final int habitCount;
  final int taskCount;
  final int prayerCount;
  final int completedPrayerCount;

  const DailyItemsState({
    required this.items,
    required this.completionPercentage,
    required this.habitCount,
    required this.taskCount,
    this.prayerCount = 0,
    this.completedPrayerCount = 0,
  });
}

@riverpod
class DailyItemsNotifier extends _$DailyItemsNotifier {
  @override
  Future<DailyItemsState> build() async {
    // Create repository instances locally to avoid re-initialization issues
    final habitRepository = HabitRepository();
    final taskRepository = TasksRepository();
    final prayerSettingsRepository = PrayerSettingsRepository();
    final prayerRepository = PrayerRepository();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Fetch all active habits
      final allHabits = await habitRepository.getActiveHabits();
      
      // Filter habits that are active today
      final todayHabits = allHabits.where((habit) => _isHabitActiveToday(habit, today)).toList();
      
      // Fetch all tasks
      final allTasks = await taskRepository.getTasks();
      
      // Filter tasks due today (not completed)
      final todayTasks = allTasks.where((task) => 
        !task.isCompleted && task.dueDate != null && _isSameDay(task.dueDate!, today)
      ).toList();
      
      // Convert habits to DailyItems
      final habitItems = await Future.wait(
        todayHabits.map((habit) => _habitToDailyItem(habit, today, habitRepository))
      );
      
      // Convert tasks to DailyItems
      final taskItems = todayTasks.map((task) => _taskToDailyItem(task)).toList();
      
      // Fetch prayer items if Islamic Prayer System is enabled
      List<DailyItem> prayerItems = [];
      int completedPrayerCount = 0;
      
      final prayerSettings = await prayerSettingsRepository.getSettings();
      if (prayerSettings.isEnabled) {
        final prayerResult = await _fetchPrayerItems(
          prayerSettings: prayerSettings,
          prayerRepository: prayerRepository,
          now: now,
        );
        prayerItems = prayerResult.items;
        completedPrayerCount = prayerResult.completedCount;
      }
      
      // Combine and sort items
      final allItems = [...habitItems, ...taskItems, ...prayerItems];
      allItems.sort(_compareItems);
      
      // Calculate completion percentage including prayers
      // **Validates: Requirements 7.5**
      final completedCount = allItems.where((item) => item.isCompleted).length;
      final totalCount = allItems.length;
      final percentage = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;
      
      CoreLoggingUtility.info(
        'DailyItemsProvider',
        'build',
        'Loaded ${habitItems.length} habits, ${taskItems.length} tasks, and ${prayerItems.length} prayers for today',
      );
      
      return DailyItemsState(
        items: allItems,
        completionPercentage: percentage,
        habitCount: habitItems.length,
        taskCount: taskItems.length,
        prayerCount: prayerItems.length,
        completedPrayerCount: completedPrayerCount,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'DailyItemsProvider',
        'build',
        'Failed to load daily items: $e\n$stackTrace',
      );
      rethrow;
    }
  }
  
  /// Fetch prayer items when Islamic Prayer System is enabled.
  ///
  /// **Validates: Requirements 7.1, 7.2, 7.3, 7.4**
  Future<_PrayerItemsResult> _fetchPrayerItems({
    required dynamic prayerSettings,
    required PrayerRepository prayerRepository,
    required DateTime now,
  }) async {
    try {
      final prayerTimeService = PrayerTimeService();
      final prayerLocationService = PrayerLocationService();
      
      // Try to get prayer schedule for today
      double? latitude = prayerSettings.lastLatitude;
      double? longitude = prayerSettings.lastLongitude;
      
      // Try to get current location if we have permission
      if (await prayerLocationService.hasLocationPermission()) {
        final location = await prayerLocationService.getCurrentLocation();
        if (location != null) {
          latitude = location.latitude;
          longitude = location.longitude;
        }
      }
      
      if (latitude == null || longitude == null) {
        CoreLoggingUtility.warning(
          'DailyItemsProvider',
          '_fetchPrayerItems',
          'No location available for prayer times',
        );
        return const _PrayerItemsResult(items: [], completedCount: 0);
      }
      
      // Fetch prayer schedule (can throw PrayerTimeException)
      final schedule = await prayerTimeService.getPrayerTimesForToday(
        latitude: latitude,
        longitude: longitude,
        method: prayerSettings.calculationMethod,
      );
      
      // Get today's prayer events
      final events = await prayerRepository.getEventsForDate(now);
      
      // Calculate statuses for all prayers
      final statuses = PrayerStatusService.calculateAllStatuses(
        schedule: schedule,
        events: events,
        currentTime: now,
        timeWindowMinutes: prayerSettings.timeWindowMinutes,
      );
      
      // Convert prayers to DailyItems
      final prayerItems = <DailyItem>[];
      int completedCount = 0;
      
      for (final type in PrayerType.values) {
        final status = statuses[type] ?? PrayerStatus.pending;
        final isCompleted = status == PrayerStatus.completed;
        
        if (isCompleted) {
          completedCount++;
        }
        
        prayerItems.add(DailyItem(
          id: 'prayer_${type.name}',
          title: type.englishName,
          type: DailyItemType.prayer,
          scheduledTime: schedule.getTimeForPrayer(type),
          isCompleted: isCompleted,
          icon: 'mosque',
          color: _getPrayerColor(status),
          prayerType: type,
          prayerStatus: status,
          arabicName: type.arabicName,
        ));
      }
      
      return _PrayerItemsResult(items: prayerItems, completedCount: completedCount);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'DailyItemsProvider',
        '_fetchPrayerItems',
        'Failed to fetch prayer items: $e\n$stackTrace',
      );
      return const _PrayerItemsResult(items: [], completedCount: 0);
    }
  }
  
  /// Get color for prayer based on status
  Color _getPrayerColor(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case PrayerStatus.pending:
        return const Color(0xFF2196F3); // Blue
      case PrayerStatus.missed:
        return const Color(0xFFF44336); // Red
    }
  }

  /// Check if a habit is active on a specific date
  bool _isHabitActiveToday(Habit habit, DateTime date) {
    // Check active days mode
    if (habit.activeDaysMode == ActiveDaysMode.selected) {
      if (habit.activeWeekdays == null || habit.activeWeekdays!.isEmpty) {
        return false;
      }
      
      // Check if today's weekday is in the active weekdays list
      // DateTime.weekday returns 1-7 (Monday-Sunday)
      final weekday = date.weekday;
      if (!habit.activeWeekdays!.contains(weekday)) {
        return false;
      }
    }
    
    // For ActiveDaysMode.all, the habit is active every day
    // Additional frequency checks could be added here if needed
    
    return true;
  }

  /// Convert a habit to a DailyItem
  Future<DailyItem> _habitToDailyItem(Habit habit, DateTime date, HabitRepository habitRepository) async {
    // Get today's events for this habit
    final events = await habitRepository.getEventsForHabit(habit.id!);
    final todayEvents = events.where((event) => _isSameDay(event.eventDate, date)).toList();
    
    // Calculate current value and completion status
    double currentValue = 0;
    bool isCompleted = false;
    
    if (todayEvents.isNotEmpty) {
      // Calculate total value from events
      for (final event in todayEvents) {
        if (event.valueDelta != null) {
          currentValue += event.valueDelta!;
        } else if (event.value != null) {
          currentValue = event.value!;
        }
      }
      
      // Check if habit is completed based on target and goal type
      if (habit.targetValue != null) {
        // For value-based habits, check against target
        if (habit.goalType == GoalType.minimum) {
          isCompleted = currentValue >= habit.targetValue!;
        } else {
          // For maximum goals, completed if value is at or below target
          isCompleted = currentValue <= habit.targetValue!;
        }
      } else {
        // For binary habits, any event means completed
        isCompleted = todayEvents.any((e) => e.completed == true);
      }
    }
    
    return DailyItem(
      id: 'habit_${habit.id}',
      title: habit.name,
      type: DailyItemType.habit,
      scheduledTime: habit.timeWindowEnabled && habit.timeWindowStart != null
          ? DateTime(date.year, date.month, date.day, habit.timeWindowStart!.hour, habit.timeWindowStart!.minute)
          : null,
      isCompleted: isCompleted,
      icon: habit.icon,
      color: _parseColor(habit.color),
      habitId: habit.id,
      currentValue: currentValue,
      targetValue: habit.targetValue,
      unit: habit.unit,
    );
  }

  /// Convert a task to a DailyItem
  DailyItem _taskToDailyItem(Task task) {
    return DailyItem(
      id: 'task_${task.id}',
      title: task.title,
      type: DailyItemType.task,
      scheduledTime: task.dueDate,
      isCompleted: task.isCompleted,
      taskId: task.id,
    );
  }

  /// Compare items for sorting
  /// Items with scheduled time come first, sorted by time
  /// Items without scheduled time come last
  int _compareItems(DailyItem a, DailyItem b) {
    // Both have scheduled time - sort by time
    if (a.scheduledTime != null && b.scheduledTime != null) {
      return a.scheduledTime!.compareTo(b.scheduledTime!);
    }
    
    // Only a has scheduled time - a comes first
    if (a.scheduledTime != null) {
      return -1;
    }
    
    // Only b has scheduled time - b comes first
    if (b.scheduledTime != null) {
      return 1;
    }
    
    // Neither has scheduled time - maintain order (habits before tasks before prayers)
    final typeOrder = {
      DailyItemType.habit: 0,
      DailyItemType.task: 1,
      DailyItemType.prayer: 2,
    };
    
    return typeOrder[a.type]!.compareTo(typeOrder[b.type]!);
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Parse color string to Color object
  Color _parseColor(String colorString) {
    // Remove '#' if present
    final hex = colorString.replaceAll('#', '');
    
    // Parse hex color
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    
    // Default color if parsing fails
    return const Color(0xFF6200EE);
  }
}


/// Helper class to return prayer items and completed count
class _PrayerItemsResult {
  final List<DailyItem> items;
  final int completedCount;

  const _PrayerItemsResult({
    required this.items,
    required this.completedCount,
  });
}
