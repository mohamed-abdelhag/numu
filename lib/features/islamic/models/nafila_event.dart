import 'enums/nafila_type.dart';

/// Represents a Nafila (voluntary) prayer completion event.
/// Records when a user marks a Nafila prayer as completed, including
/// the number of rakats prayed and optional notes.
class NafilaEvent {
  final int? id;
  final NafilaType nafilaType;
  final DateTime eventDate;
  final DateTime eventTimestamp;
  final int rakatCount;
  final DateTime? actualPrayerTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NafilaEvent({
    this.id,
    required this.nafilaType,
    required this.eventDate,
    required this.eventTimestamp,
    required this.rakatCount,
    this.actualPrayerTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NafilaEvent.fromMap(Map<String, dynamic> map) {
    return NafilaEvent(
      id: map['event_id'] as int?,
      nafilaType: NafilaType.fromJson(map['nafila_type'] as String),
      eventDate: DateTime.parse(map['event_date'] as String),
      eventTimestamp: DateTime.parse(map['event_timestamp'] as String),
      rakatCount: map['rakat_count'] as int,
      actualPrayerTime: map['actual_prayer_time'] != null
          ? DateTime.parse(map['actual_prayer_time'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'event_id': id,
      'nafila_type': nafilaType.toJson(),
      'event_date': _formatDateOnly(eventDate),
      'event_timestamp': eventTimestamp.toIso8601String(),
      'rakat_count': rakatCount,
      'actual_prayer_time': actualPrayerTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NafilaEvent copyWith({
    int? id,
    NafilaType? nafilaType,
    DateTime? eventDate,
    DateTime? eventTimestamp,
    int? rakatCount,
    DateTime? actualPrayerTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NafilaEvent(
      id: id ?? this.id,
      nafilaType: nafilaType ?? this.nafilaType,
      eventDate: eventDate ?? this.eventDate,
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      rakatCount: rakatCount ?? this.rakatCount,
      actualPrayerTime: actualPrayerTime ?? this.actualPrayerTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Format date as YYYY-MM-DD for database storage
  static String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NafilaEvent &&
        other.id == id &&
        other.nafilaType == nafilaType &&
        other.eventDate.year == eventDate.year &&
        other.eventDate.month == eventDate.month &&
        other.eventDate.day == eventDate.day &&
        other.eventTimestamp == eventTimestamp &&
        other.rakatCount == rakatCount &&
        other.actualPrayerTime == actualPrayerTime &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nafilaType,
      eventDate,
      eventTimestamp,
      rakatCount,
      actualPrayerTime,
      notes,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'NafilaEvent(id: $id, nafilaType: $nafilaType, eventDate: $eventDate, rakatCount: $rakatCount)';
  }
}
