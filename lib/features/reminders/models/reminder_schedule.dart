import 'dart:convert';
import 'package:flutter/material.dart';

enum ScheduleFrequency {
  none,
  daily,
  weekly,
  monthly;

  String toMap() {
    return name;
  }

  static ScheduleFrequency fromMap(String value) {
    return ScheduleFrequency.values.firstWhere(
      (freq) => freq.name == value,
      orElse: () => ScheduleFrequency.none,
    );
  }
}

class ReminderSchedule {
  final ScheduleFrequency frequency;
  final DateTime? specificDateTime;
  final TimeOfDay? timeOfDay;
  final List<int>? activeWeekdays;
  final int? dayOfMonth;
  final int? minutesBefore;
  final bool useHabitTimeWindow;
  final bool useHabitActiveDays;

  const ReminderSchedule({
    required this.frequency,
    this.specificDateTime,
    this.timeOfDay,
    this.activeWeekdays,
    this.dayOfMonth,
    this.minutesBefore,
    this.useHabitTimeWindow = false,
    this.useHabitActiveDays = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.toMap(),
      'specific_date_time': specificDateTime?.toIso8601String(),
      'time_of_day': timeOfDay != null
          ? '${timeOfDay!.hour}:${timeOfDay!.minute}'
          : null,
      'active_weekdays': activeWeekdays != null
          ? jsonEncode(activeWeekdays)
          : null,
      'day_of_month': dayOfMonth,
      'minutes_before': minutesBefore,
      'use_habit_time_window': useHabitTimeWindow ? 1 : 0,
      'use_habit_active_days': useHabitActiveDays ? 1 : 0,
    };
  }

  factory ReminderSchedule.fromMap(Map<String, dynamic> map) {
    TimeOfDay? timeOfDay;
    if (map['time_of_day'] != null) {
      final parts = (map['time_of_day'] as String).split(':');
      timeOfDay = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    List<int>? activeWeekdays;
    if (map['active_weekdays'] != null) {
      final decoded = jsonDecode(map['active_weekdays'] as String);
      activeWeekdays = List<int>.from(decoded);
    }

    return ReminderSchedule(
      frequency: ScheduleFrequency.fromMap(map['frequency'] as String),
      specificDateTime: map['specific_date_time'] != null
          ? DateTime.parse(map['specific_date_time'] as String)
          : null,
      timeOfDay: timeOfDay,
      activeWeekdays: activeWeekdays,
      dayOfMonth: map['day_of_month'] as int?,
      minutesBefore: map['minutes_before'] as int?,
      useHabitTimeWindow: (map['use_habit_time_window'] as int?) == 1,
      useHabitActiveDays: (map['use_habit_active_days'] as int?) == 1,
    );
  }

  ReminderSchedule copyWith({
    ScheduleFrequency? frequency,
    DateTime? specificDateTime,
    TimeOfDay? timeOfDay,
    List<int>? activeWeekdays,
    int? dayOfMonth,
    int? minutesBefore,
    bool? useHabitTimeWindow,
    bool? useHabitActiveDays,
  }) {
    return ReminderSchedule(
      frequency: frequency ?? this.frequency,
      specificDateTime: specificDateTime ?? this.specificDateTime,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      useHabitTimeWindow: useHabitTimeWindow ?? this.useHabitTimeWindow,
      useHabitActiveDays: useHabitActiveDays ?? this.useHabitActiveDays,
    );
  }
}
