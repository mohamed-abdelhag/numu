import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/daily_item.dart';
import '../../habits/models/habit.dart';
import '../../habits/models/enums/active_days_mode.dart';
import '../../habits/models/enums/goal_type.dart';
import '../../habits/repositories/habit_repository.dart';
import '../../tasks/tasks_repository.dart';
import '../../tasks/task.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'daily_items_provider.g.dart';

class DailyItemsState {
  final List<DailyItem> items;
  final int completionPercentage;
  final int habitCount;
  final int taskCount;

  const DailyItemsState({
    required this.items,
    required this.completionPercentage,
    required this.habitCount,
    required this.taskCount,
  });
}

@riverpod
class DailyItemsNotifier extends _$DailyItemsNotifier {
  @override
  Future<DailyItemsState> build() async {
    // Create repository instances locally to avoid re-initialization issues
    final habitRepository = HabitRepository();
    final taskRepository = TasksRepository();

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
      
      // Combine and sort items
      final allItems = [...habitItems, ...taskItems];
      allItems.sort(_compareItems);
      
      // Calculate completion percentage
      final completedCount = allItems.where((item) => item.isCompleted).length;
      final totalCount = allItems.length;
      final percentage = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;
      
      CoreLoggingUtility.info(
        'DailyItemsProvider',
        'build',
        'Loaded ${habitItems.length} habits and ${taskItems.length} tasks for today',
      );
      
      return DailyItemsState(
        items: allItems,
        completionPercentage: percentage,
        habitCount: habitItems.length,
        taskCount: taskItems.length,
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
    
    // Neither has scheduled time - maintain order (habits before tasks)
    if (a.type == DailyItemType.habit && b.type == DailyItemType.task) {
      return -1;
    }
    if (a.type == DailyItemType.task && b.type == DailyItemType.habit) {
      return 1;
    }
    
    return 0;
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
