import 'enums/streak_type.dart';

/// Model representing streak data for a habit
/// Tracks current streak, longest streak, and consistency metrics
class HabitStreak {
  final int? id;
  final int habitId;
  final StreakType streakType;
  
  // Current streak data
  final int currentStreak;
  final DateTime? currentStreakStartDate;
  
  // Longest streak data
  final int longestStreak;
  final DateTime? longestStreakStartDate;
  final DateTime? longestStreakEndDate;
  
  // Statistics
  final int totalCompletions;
  final int totalDaysActive;
  final double consistencyRate;
  
  // Metadata
  final DateTime lastCalculatedAt;
  final DateTime? lastEventDate;

  const HabitStreak({
    this.id,
    required this.habitId,
    required this.streakType,
    this.currentStreak = 0,
    this.currentStreakStartDate,
    this.longestStreak = 0,
    this.longestStreakStartDate,
    this.longestStreakEndDate,
    this.totalCompletions = 0,
    this.totalDaysActive = 0,
    this.consistencyRate = 0.0,
    required this.lastCalculatedAt,
    this.lastEventDate,
  });

  factory HabitStreak.fromMap(Map<String, dynamic> map) {
    return HabitStreak(
      id: map['streak_id'] as int?,
      habitId: map['habit_id'] as int,
      streakType: StreakType.fromJson(map['streak_type'] as String),
      currentStreak: map['current_streak'] as int,
      currentStreakStartDate: map['current_streak_start_date'] != null
          ? DateTime.parse(map['current_streak_start_date'] as String)
          : null,
      longestStreak: map['longest_streak'] as int,
      longestStreakStartDate: map['longest_streak_start_date'] != null
          ? DateTime.parse(map['longest_streak_start_date'] as String)
          : null,
      longestStreakEndDate: map['longest_streak_end_date'] != null
          ? DateTime.parse(map['longest_streak_end_date'] as String)
          : null,
      totalCompletions: map['total_completions'] as int,
      totalDaysActive: map['total_days_active'] as int,
      consistencyRate: map['consistency_rate'] as double,
      lastCalculatedAt: DateTime.parse(map['last_calculated_at'] as String),
      lastEventDate: map['last_event_date'] != null
          ? DateTime.parse(map['last_event_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'streak_id': id,
      'habit_id': habitId,
      'streak_type': streakType.toJson(),
      'current_streak': currentStreak,
      'current_streak_start_date': currentStreakStartDate?.toIso8601String(),
      'longest_streak': longestStreak,
      'longest_streak_start_date': longestStreakStartDate?.toIso8601String(),
      'longest_streak_end_date': longestStreakEndDate?.toIso8601String(),
      'total_completions': totalCompletions,
      'total_days_active': totalDaysActive,
      'consistency_rate': consistencyRate,
      'last_calculated_at': lastCalculatedAt.toIso8601String(),
      'last_event_date': lastEventDate?.toIso8601String(),
    };
  }

  HabitStreak copyWith({
    int? id,
    int? habitId,
    StreakType? streakType,
    int? currentStreak,
    DateTime? currentStreakStartDate,
    int? longestStreak,
    DateTime? longestStreakStartDate,
    DateTime? longestStreakEndDate,
    int? totalCompletions,
    int? totalDaysActive,
    double? consistencyRate,
    DateTime? lastCalculatedAt,
    DateTime? lastEventDate,
  }) {
    return HabitStreak(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      streakType: streakType ?? this.streakType,
      currentStreak: currentStreak ?? this.currentStreak,
      currentStreakStartDate: currentStreakStartDate ?? this.currentStreakStartDate,
      longestStreak: longestStreak ?? this.longestStreak,
      longestStreakStartDate: longestStreakStartDate ?? this.longestStreakStartDate,
      longestStreakEndDate: longestStreakEndDate ?? this.longestStreakEndDate,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      consistencyRate: consistencyRate ?? this.consistencyRate,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      lastEventDate: lastEventDate ?? this.lastEventDate,
    );
  }
}
