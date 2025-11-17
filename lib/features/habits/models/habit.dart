import 'dart:convert';
import 'package:flutter/material.dart';
import 'enums/tracking_type.dart';
import 'enums/goal_type.dart';
import 'enums/frequency.dart';
import 'enums/active_days_mode.dart';
import 'enums/require_mode.dart';

class Habit {
  final int? id;
  final String name;
  final String? description;
  final int? categoryId;
  final String icon;
  final String color;

  // Tracking configuration
  final TrackingType trackingType;
  final GoalType goalType;
  final double? targetValue;
  final String? unit;

  // Frequency configuration
  final Frequency frequency;
  final int? customPeriodDays;
  final DateTime? periodStartDate;

  // Active days configuration
  final ActiveDaysMode activeDaysMode;
  final List<int>? activeWeekdays; // 1-7, Monday-Sunday
  final RequireMode requireMode;

  // Time window configuration (optional)
  final bool timeWindowEnabled;
  final TimeOfDay? timeWindowStart;
  final TimeOfDay? timeWindowEnd;
  final String? timeWindowMode;

  // Quality layer configuration (optional)
  final bool qualityLayerEnabled;
  final String? qualityLayerLabel;

  // Metadata
  final bool isActive;
  final bool isTemplate;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Habit({
    this.id,
    required this.name,
    this.description,
    this.categoryId,
    required this.icon,
    required this.color,
    required this.trackingType,
    required this.goalType,
    this.targetValue,
    this.unit,
    required this.frequency,
    this.customPeriodDays,
    this.periodStartDate,
    required this.activeDaysMode,
    this.activeWeekdays,
    required this.requireMode,
    this.timeWindowEnabled = false,
    this.timeWindowStart,
    this.timeWindowEnd,
    this.timeWindowMode,
    this.qualityLayerEnabled = false,
    this.qualityLayerLabel,
    this.isActive = true,
    this.isTemplate = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['habit_id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int?,
      icon: map['icon'] as String,
      color: map['color'] as String,
      trackingType: TrackingType.fromJson(map['tracking_type'] as String),
      goalType: GoalType.fromJson(map['goal_type'] as String),
      targetValue: map['target_value'] as double?,
      unit: map['unit'] as String?,
      frequency: Frequency.fromJson(map['frequency'] as String),
      customPeriodDays: map['custom_period_days'] as int?,
      periodStartDate: map['period_start_date'] != null
          ? DateTime.parse(map['period_start_date'] as String)
          : null,
      activeDaysMode: ActiveDaysMode.fromJson(map['active_days_mode'] as String),
      activeWeekdays: map['active_weekdays'] != null
          ? (jsonDecode(map['active_weekdays'] as String) as List<dynamic>)
              .map((e) => e as int)
              .toList()
          : null,
      requireMode: RequireMode.fromJson(map['require_mode'] as String),
      timeWindowEnabled: (map['time_window_enabled'] as int) == 1,
      timeWindowStart: map['time_window_start'] != null
          ? _parseTimeOfDay(map['time_window_start'] as String)
          : null,
      timeWindowEnd: map['time_window_end'] != null
          ? _parseTimeOfDay(map['time_window_end'] as String)
          : null,
      timeWindowMode: map['time_window_mode'] as String?,
      qualityLayerEnabled: (map['quality_layer_enabled'] as int) == 1,
      qualityLayerLabel: map['quality_layer_label'] as String?,
      isActive: (map['is_active'] as int) == 1,
      isTemplate: (map['is_template'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      archivedAt: map['archived_at'] != null
          ? DateTime.parse(map['archived_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'habit_id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'icon': icon,
      'color': color,
      'tracking_type': trackingType.toJson(),
      'goal_type': goalType.toJson(),
      'target_value': targetValue,
      'unit': unit,
      'frequency': frequency.toJson(),
      'custom_period_days': customPeriodDays,
      'period_start_date': periodStartDate?.toIso8601String(),
      'active_days_mode': activeDaysMode.toJson(),
      'active_weekdays': activeWeekdays != null ? jsonEncode(activeWeekdays) : null,
      'require_mode': requireMode.toJson(),
      'time_window_enabled': timeWindowEnabled ? 1 : 0,
      'time_window_start': timeWindowStart != null
          ? _formatTimeOfDay(timeWindowStart!)
          : null,
      'time_window_end': timeWindowEnd != null
          ? _formatTimeOfDay(timeWindowEnd!)
          : null,
      'time_window_mode': timeWindowMode,
      'quality_layer_enabled': qualityLayerEnabled ? 1 : 0,
      'quality_layer_label': qualityLayerLabel,
      'is_active': isActive ? 1 : 0,
      'is_template': isTemplate ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    String? icon,
    String? color,
    TrackingType? trackingType,
    GoalType? goalType,
    double? targetValue,
    String? unit,
    Frequency? frequency,
    int? customPeriodDays,
    DateTime? periodStartDate,
    ActiveDaysMode? activeDaysMode,
    List<int>? activeWeekdays,
    RequireMode? requireMode,
    bool? timeWindowEnabled,
    TimeOfDay? timeWindowStart,
    TimeOfDay? timeWindowEnd,
    String? timeWindowMode,
    bool? qualityLayerEnabled,
    String? qualityLayerLabel,
    bool? isActive,
    bool? isTemplate,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      trackingType: trackingType ?? this.trackingType,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      customPeriodDays: customPeriodDays ?? this.customPeriodDays,
      periodStartDate: periodStartDate ?? this.periodStartDate,
      activeDaysMode: activeDaysMode ?? this.activeDaysMode,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      requireMode: requireMode ?? this.requireMode,
      timeWindowEnabled: timeWindowEnabled ?? this.timeWindowEnabled,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
      timeWindowMode: timeWindowMode ?? this.timeWindowMode,
      qualityLayerEnabled: qualityLayerEnabled ?? this.qualityLayerEnabled,
      qualityLayerLabel: qualityLayerLabel ?? this.qualityLayerLabel,
      isActive: isActive ?? this.isActive,
      isTemplate: isTemplate ?? this.isTemplate,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
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
