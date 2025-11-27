import 'package:flutter/material.dart';
import '../../islamic/models/enums/prayer_type.dart';
import '../../islamic/models/enums/prayer_status.dart';

enum DailyItemType { habit, task, prayer }

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
  
  // Prayer-specific fields
  final PrayerType? prayerType;
  final PrayerStatus? prayerStatus;
  final String? arabicName;

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
    this.prayerType,
    this.prayerStatus,
    this.arabicName,
  });
  
  /// Check if this item is a prayer
  bool get isPrayer => type == DailyItemType.prayer;
  
  /// Check if this prayer is missed
  bool get isMissed => prayerStatus == PrayerStatus.missed;
  
  /// Check if this prayer is pending
  bool get isPending => prayerStatus == PrayerStatus.pending;
}
