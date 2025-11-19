/// Model class representing aggregated statistics for a habit
class HabitStatistics {
  /// Total value across all time for countable habits, or total completed days for boolean habits
  final double totalValue;

  /// Total value for the current week
  final double weeklyValue;

  /// Total value for the current month
  final double monthlyValue;

  /// Average value per day
  final double averagePerDay;

  /// Number of days with quality achieved
  final int qualityDays;

  /// Percentage of completed days that achieved quality
  final double qualityPercentage;

  const HabitStatistics({
    required this.totalValue,
    required this.weeklyValue,
    required this.monthlyValue,
    required this.averagePerDay,
    required this.qualityDays,
    required this.qualityPercentage,
  });

  /// Creates an empty statistics object with all values set to zero
  const HabitStatistics.empty()
      : totalValue = 0,
        weeklyValue = 0,
        monthlyValue = 0,
        averagePerDay = 0,
        qualityDays = 0,
        qualityPercentage = 0;

  @override
  String toString() {
    return 'HabitStatistics(total: $totalValue, weekly: $weeklyValue, '
        'monthly: $monthlyValue, average: $averagePerDay, '
        'qualityDays: $qualityDays, qualityPercentage: $qualityPercentage%)';
  }
}
