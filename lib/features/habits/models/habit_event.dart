import 'package:flutter/material.dart';

class HabitEvent {
  final int? id;
  final int habitId;

  // Event timing
  final DateTime eventDate;
  final DateTime eventTimestamp;

  // Tracking data
  final bool? completed;
  final double? value;
  final double? valueDelta;

  // Optional layer data
  final TimeOfDay? timeRecorded;
  final bool? withinTimeWindow;
  final bool? qualityAchieved;

  // Metadata
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitEvent({
    this.id,
    required this.habitId,
    required this.eventDate,
    required this.eventTimestamp,
    this.completed,
    this.value,
    this.valueDelta,
    this.timeRecorded,
    this.withinTimeWindow,
    this.qualityAchieved,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitEvent.fromMap(Map<String, dynamic> map) {
    return HabitEvent(
      id: map['event_id'] as int?,
      habitId: map['habit_id'] as int,
      eventDate: DateTime.parse(map['event_date'] as String),
      eventTimestamp: DateTime.parse(map['event_timestamp'] as String),
      completed: map['completed'] != null ? (map['completed'] as int) == 1 : null,
      value: map['value'] as double?,
      valueDelta: map['value_delta'] as double?,
      timeRecorded: map['time_recorded'] != null
          ? _parseTimeOfDay(map['time_recorded'] as String)
          : null,
      withinTimeWindow: map['within_time_window'] != null
          ? (map['within_time_window'] as int) == 1
          : null,
      qualityAchieved: map['quality_achieved'] != null
          ? (map['quality_achieved'] as int) == 1
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'event_id': id,
      'habit_id': habitId,
      'event_date': eventDate.toIso8601String(),
      'event_timestamp': eventTimestamp.toIso8601String(),
      'completed': completed != null ? (completed! ? 1 : 0) : null,
      'value': value,
      'value_delta': valueDelta,
      'time_recorded': timeRecorded != null
          ? _formatTimeOfDay(timeRecorded!)
          : null,
      'within_time_window': withinTimeWindow != null
          ? (withinTimeWindow! ? 1 : 0)
          : null,
      'quality_achieved': qualityAchieved != null
          ? (qualityAchieved! ? 1 : 0)
          : null,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HabitEvent copyWith({
    int? id,
    int? habitId,
    DateTime? eventDate,
    DateTime? eventTimestamp,
    bool? completed,
    double? value,
    double? valueDelta,
    TimeOfDay? timeRecorded,
    bool? withinTimeWindow,
    bool? qualityAchieved,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitEvent(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      eventDate: eventDate ?? this.eventDate,
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      completed: completed ?? this.completed,
      value: value ?? this.value,
      valueDelta: valueDelta ?? this.valueDelta,
      timeRecorded: timeRecorded ?? this.timeRecorded,
      withinTimeWindow: withinTimeWindow ?? this.withinTimeWindow,
      qualityAchieved: qualityAchieved ?? this.qualityAchieved,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for TimeOfDay conversion
  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
