import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../repositories/habit_repository.dart';
import 'log_habit_event_dialog.dart';

/// Widget that displays a calendar grid showing habit completion history
/// Marks completed days with checkmark, incomplete days with X or empty
/// Supports tapping dates to edit existing entries or create new ones
class HabitCalendarView extends ConsumerWidget {
  final int habitId;
  final int weeksToShow;

  const HabitCalendarView({
    super.key,
    required this.habitId,
    this.weeksToShow = 4,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _loadCalendarData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Failed to load calendar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final habit = data['habit'] as Habit;
        final completionMap = data['completionMap'] as Map<String, bool>;
        final dates = data['dates'] as List<DateTime>;
        final eventsByDate = data['eventsByDate'] as Map<String, List<HabitEvent>>;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildWeekdayHeaders(context),
                const SizedBox(height: 8),
                _buildCalendarGrid(context, habit, dates, completionMap, eventsByDate),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build weekday headers (Mo, Tu, We, etc.)
  Widget _buildWeekdayHeaders(BuildContext context) {
    const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build the calendar grid with completion status
  Widget _buildCalendarGrid(
    BuildContext context,
    Habit habit,
    List<DateTime> dates,
    Map<String, bool> completionMap,
    Map<String, List<HabitEvent>> eventsByDate,
  ) {
    // Group dates by week
    final weeks = <List<DateTime>>[];
    List<DateTime> currentWeek = [];

    for (final date in dates) {
      currentWeek.add(date);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    // Add remaining days if any
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((date) {
              return Expanded(
                child: _buildDayCell(context, habit, date, completionMap, eventsByDate),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Build a single day cell in the calendar
  Widget _buildDayCell(
    BuildContext context,
    Habit habit,
    DateTime date,
    Map<String, bool> completionMap,
    Map<String, List<HabitEvent>> eventsByDate,
  ) {
    final dateKey = _formatDateKey(date);
    final isCompleted = completionMap[dateKey] ?? false;
    final isToday = _isToday(date);
    final isFuture = date.isAfter(DateTime.now());
    final isActiveDay = _isActiveDay(habit, date);

    Color backgroundColor;
    Color? borderColor;
    Widget? icon;

    if (isFuture) {
      // Future dates - gray out
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    } else if (!isActiveDay) {
      // Inactive days (not in active weekdays) - very light gray
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1);
    } else if (isCompleted) {
      // Completed - green
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      icon = const Icon(Icons.check, size: 16, color: Colors.green);
    } else {
      // Incomplete - red/empty
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      icon = Icon(Icons.close, size: 16, color: Colors.red.withValues(alpha: 0.5));
    }

    if (isToday) {
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return InkWell(
      onTap: isFuture ? null : () => _handleDateTap(context, habit, date, eventsByDate),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isFuture
                          ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              if (icon != null && !isFuture) icon,
            ],
          ),
        ),
      ),
    );
  }

  /// Handle tapping on a calendar date
  void _handleDateTap(
    BuildContext context,
    Habit habit,
    DateTime date,
    Map<String, List<HabitEvent>> eventsByDate,
  ) {
    final dateKey = _formatDateKey(date);
    final events = eventsByDate[dateKey] ?? [];
    
    // Get the first event for this date if it exists
    // For most habits, there should only be one event per day
    final existingEvent = events.isNotEmpty ? events.first : null;
    
    showDialog(
      context: context,
      builder: (context) => LogHabitEventDialog(
        habit: habit,
        prefilledDate: date,
        existingEvent: existingEvent,
      ),
    );
  }

  /// Check if a date is an active day for the habit
  bool _isActiveDay(Habit habit, DateTime date) {
    if (habit.activeDaysMode.toString() == 'ActiveDaysMode.all') {
      return true;
    }
    
    final weekday = date.weekday; // 1-7, Monday-Sunday
    return habit.activeWeekdays?.contains(weekday) ?? true;
  }

  /// Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Format date as a key for the completion map
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Load calendar data including habit and events
  Future<Map<String, dynamic>> _loadCalendarData() async {
    final repository = HabitRepository();
    
    // Get habit details
    final habit = await repository.getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit not found');
    }

    // Calculate date range (last N weeks)
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: weeksToShow * 7));

    // Get events for the date range
    final events = await repository.getEventsForHabit(
      habitId,
      startDate: startDate,
      endDate: endDate,
    );

    // Build completion map
    final completionMap = <String, bool>{};
    
    // Group events by date
    final eventsByDate = <String, List<HabitEvent>>{};
    for (final event in events) {
      final dateKey = _formatDateKey(event.eventDate);
      eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }

    // Check completion for each date
    for (final entry in eventsByDate.entries) {
      final dateKey = entry.key;
      final dayEvents = entry.value;
      completionMap[dateKey] = _checkDayCompletion(habit, dayEvents);
    }

    // Generate list of dates to display
    final dates = <DateTime>[];
    
    // Start from the Monday of the week containing startDate
    DateTime current = startDate;
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    // Add dates until we reach today or complete the last week
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    // Complete the last week if needed
    while (dates.length % 7 != 0) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return {
      'habit': habit,
      'completionMap': completionMap,
      'dates': dates,
      'eventsByDate': eventsByDate,
    };
  }

  /// Check if a day was completed based on habit configuration
  bool _checkDayCompletion(Habit habit, List<HabitEvent> events) {
    if (events.isEmpty) return false;

    if (habit.trackingType == TrackingType.binary) {
      return events.any((e) => e.completed == true);
    }

    // For value-based habits, check if target was met
    final total = events.fold<double>(0, (sum, e) => sum + (e.valueDelta ?? 0));

    switch (habit.goalType) {
      case GoalType.minimum:
        return total >= (habit.targetValue ?? 0);
      case GoalType.maximum:
        return total <= (habit.targetValue ?? double.infinity);
      case GoalType.none:
        return events.isNotEmpty;
    }
  }
}
