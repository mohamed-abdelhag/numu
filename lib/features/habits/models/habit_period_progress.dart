import 'enums/frequency.dart';

/// Model representing period progress for weekly/monthly habits
class HabitPeriodProgress {
  final int? id;
  final int habitId;
  final Frequency periodType;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final double targetValue;
  final double currentValue;
  final bool completed;
  final DateTime? completionDate;
  final int timeWindowCompletions;
  final int qualityCompletions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitPeriodProgress({
    this.id,
    required this.habitId,
    required this.periodType,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.targetValue,
    this.currentValue = 0,
    this.completed = false,
    this.completionDate,
    this.timeWindowCompletions = 0,
    this.qualityCompletions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitPeriodProgress.fromMap(Map<String, dynamic> map) {
    return HabitPeriodProgress(
      id: map['progress_id'] as int?,
      habitId: map['habit_id'] as int,
      periodType: Frequency.fromJson(map['period_type'] as String),
      periodStartDate: DateTime.parse(map['period_start_date'] as String),
      periodEndDate: DateTime.parse(map['period_end_date'] as String),
      targetValue: map['target_value'] as double,
      currentValue: map['current_value'] as double,
      completed: (map['completed'] as int) == 1,
      completionDate: map['completion_date'] != null
          ? DateTime.parse(map['completion_date'] as String)
          : null,
      timeWindowCompletions: map['time_window_completions'] as int,
      qualityCompletions: map['quality_completions'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'progress_id': id,
      'habit_id': habitId,
      'period_type': periodType.toJson(),
      'period_start_date': periodStartDate.toIso8601String(),
      'period_end_date': periodEndDate.toIso8601String(),
      'target_value': targetValue,
      'current_value': currentValue,
      'completed': completed ? 1 : 0,
      'completion_date': completionDate?.toIso8601String(),
      'time_window_completions': timeWindowCompletions,
      'quality_completions': qualityCompletions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HabitPeriodProgress copyWith({
    int? id,
    int? habitId,
    Frequency? periodType,
    DateTime? periodStartDate,
    DateTime? periodEndDate,
    double? targetValue,
    double? currentValue,
    bool? completed,
    DateTime? completionDate,
    int? timeWindowCompletions,
    int? qualityCompletions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitPeriodProgress(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      periodType: periodType ?? this.periodType,
      periodStartDate: periodStartDate ?? this.periodStartDate,
      periodEndDate: periodEndDate ?? this.periodEndDate,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      completed: completed ?? this.completed,
      completionDate: completionDate ?? this.completionDate,
      timeWindowCompletions: timeWindowCompletions ?? this.timeWindowCompletions,
      qualityCompletions: qualityCompletions ?? this.qualityCompletions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
