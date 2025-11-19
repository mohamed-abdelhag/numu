import 'package:flutter/material.dart';

enum DailyItemType { habit, task }

class DailyItem {
  final String id;
  final String title;
  final DailyItemType type;
  final DateTime? scheduledTime;
  final bool isCompleted;
  final String? icon;
  final Color? color;
  final int? habitId;
  final int? taskId;
  final double? currentValue;
  final double? targetValue;
  final String? unit;

  DailyItem({
    required this.id,
    required this.title,
    required this.type,
    this.scheduledTime,
    required this.isCompleted,
    this.icon,
    this.color,
    this.habitId,
    this.taskId,
    this.currentValue,
    this.targetValue,
    this.unit,
  });
}
