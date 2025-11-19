import 'reminder_type.dart';
import 'reminder_schedule.dart';
import 'reminder_link.dart';

class Reminder {
  final int? id;
  final String title;
  final String? description;
  final ReminderType type;
  final ReminderSchedule schedule;
  final ReminderLink? link;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextTriggerTime;

  const Reminder({
    this.id,
    required this.title,
    this.description,
    required this.type,
    required this.schedule,
    this.link,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.nextTriggerTime,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'reminder_type': type.toMap(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'next_trigger_time': nextTriggerTime?.toIso8601String(),
    };

    // Add schedule fields
    map.addAll(schedule.toMap());

    // Add link fields if present
    if (link != null) {
      map.addAll(link!.toMap());
    } else {
      map['link_type'] = null;
      map['link_entity_id'] = null;
      map['link_entity_name'] = null;
      map['use_default_text'] = 1;
    }

    // Add id if present
    if (id != null) {
      map['reminder_id'] = id;
    }

    return map;
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    ReminderLink? link;
    if (map['link_type'] != null) {
      link = ReminderLink.fromMap(map);
    }

    return Reminder(
      id: map['reminder_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: ReminderType.fromMap(map['reminder_type'] as String),
      schedule: ReminderSchedule.fromMap(map),
      link: link,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      nextTriggerTime: map['next_trigger_time'] != null
          ? DateTime.parse(map['next_trigger_time'] as String)
          : null,
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    ReminderType? type,
    ReminderSchedule? schedule,
    ReminderLink? link,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextTriggerTime,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      schedule: schedule ?? this.schedule,
      link: link ?? this.link,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextTriggerTime: nextTriggerTime ?? this.nextTriggerTime,
    );
  }
}
