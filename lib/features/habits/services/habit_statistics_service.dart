import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_statistics.dart';
import '../models/enums/tracking_type.dart';
import '../repositories/habit_repository.dart';

/// Service for calculating aggregated statistics for habits
/// Handles calculation of total, weekly, monthly, average, and quality statistics
class HabitStatisticsService {
  final HabitRepository _repository;

  HabitStatisticsService(this._repository);

  /// Calculate comprehensive statistics for a habit
  /// Returns aggregated values including total, weekly, monthly, average, and quality metrics
  Future<HabitStatistics> calculateStatistics(int habitId, Habit habit) async {
    final events = await _repository.getEventsForHabit(habitId);

    if (events.isEmpty) {
      return const HabitStatistics.empty();
    }

    final totalValue = _calculateTotal(events, habit);
    final weeklyValue = _calculateWeekly(events, habit);
    final monthlyValue = _calculateMonthly(events, habit);
    final averagePerDay = _calculateAverage(events, habit);
    final qualityDays = _calculateQualityDays(events);
    final qualityPercentage = _calculateQualityPercentage(events);

    return HabitStatistics(
      totalValue: totalValue,
      weeklyValue: weeklyValue,
      monthlyValue: monthlyValue,
      averagePerDay: averagePerDay,
      qualityDays: qualityDays,
      qualityPercentage: qualityPercentage,
    );
  }

  /// Calculate total value across all time
  /// For countable habits: sum of all values
  /// For boolean habits: count of completed days
  double _calculateTotal(List<HabitEvent> events, Habit habit) {
    if (habit.trackingType == TrackingType.binary) {
      // Count completed days for boolean habits
      return events.where((e) => e.completed == true).length.toDouble();
    }

    // Sum all values for countable habits
    return events.fold<double>(
      0,
      (sum, event) => sum + (event.value ?? 0),
    );
  }

  /// Calculate total value for the current week
  /// Week starts on Monday and ends on Sunday
  double _calculateWeekly(List<HabitEvent> events, Habit habit) {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekEvents = events.where((event) {
      final eventDate = _normalizeDate(event.eventDate);
      return eventDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          eventDate.isBefore(endOfWeek);
    }).toList();

    if (habit.trackingType == TrackingType.binary) {
      return weekEvents.where((e) => e.completed == true).length.toDouble();
    }

    return weekEvents.fold<double>(
      0,
      (sum, event) => sum + (event.value ?? 0),
    );
  }

  /// Calculate total value for the current month
  double _calculateMonthly(List<HabitEvent> events, Habit habit) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final monthEvents = events.where((event) {
      final eventDate = _normalizeDate(event.eventDate);
      return eventDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          eventDate.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    if (habit.trackingType == TrackingType.binary) {
      return monthEvents.where((e) => e.completed == true).length.toDouble();
    }

    return monthEvents.fold<double>(
      0,
      (sum, event) => sum + (event.value ?? 0),
    );
  }

  /// Calculate average value per day
  /// Calculated from the first event date to today
  double _calculateAverage(List<HabitEvent> events, Habit habit) {
    if (events.isEmpty) return 0;

    // Find the earliest event date
    final sortedEvents = events.toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    final firstEventDate = _normalizeDate(sortedEvents.first.eventDate);
    final today = _normalizeDate(DateTime.now());

    // Calculate total days from first event to today
    final totalDays = today.difference(firstEventDate).inDays + 1;

    if (totalDays <= 0) return 0;

    final totalValue = _calculateTotal(events, habit);
    return totalValue / totalDays;
  }

  /// Calculate number of days with quality achieved
  int _calculateQualityDays(List<HabitEvent> events) {
    return events.where((e) => e.qualityAchieved == true).length;
  }

  /// Calculate percentage of completed days that achieved quality
  /// Returns 0 if no completed days exist
  double _calculateQualityPercentage(List<HabitEvent> events) {
    final completedEvents = events.where((e) => 
      e.completed == true || (e.value ?? 0) > 0
    ).toList();

    if (completedEvents.isEmpty) return 0;

    final qualityEvents = completedEvents.where((e) => 
      e.qualityAchieved == true
    ).length;

    return (qualityEvents / completedEvents.length) * 100;
  }

  /// Get the start of the week (Monday) for a given date
  DateTime _getStartOfWeek(DateTime date) {
    final normalized = _normalizeDate(date);
    final weekday = normalized.weekday; // 1 = Monday, 7 = Sunday
    return normalized.subtract(Duration(days: weekday - 1));
  }

  /// Normalize a date to start of day (midnight)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
