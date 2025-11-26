import 'enums/prayer_type.dart';

/// Represents a prayer completion event.
/// Records when a user marks a prayer as completed, including
/// whether it was prayed in congregation (Jamaah) and within the time window.
class PrayerEvent {
  final int? id;
  final PrayerType prayerType;
  final DateTime eventDate;
  final DateTime eventTimestamp;
  final DateTime? actualPrayerTime; // When user actually prayed
  final bool prayedInJamaah; // Quality layer: congregation
  final bool withinTimeWindow;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrayerEvent({
    this.id,
    required this.prayerType,
    required this.eventDate,
    required this.eventTimestamp,
    this.actualPrayerTime,
    this.prayedInJamaah = false,
    this.withinTimeWindow = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrayerEvent.fromMap(Map<String, dynamic> map) {
    return PrayerEvent(
      id: map['event_id'] as int?,
      prayerType: PrayerType.fromJson(map['prayer_type'] as String),
      eventDate: DateTime.parse(map['event_date'] as String),
      eventTimestamp: DateTime.parse(map['event_timestamp'] as String),
      actualPrayerTime: map['actual_prayer_time'] != null
          ? DateTime.parse(map['actual_prayer_time'] as String)
          : null,
      prayedInJamaah: (map['prayed_in_jamaah'] as int) == 1,
      withinTimeWindow: (map['within_time_window'] as int) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'event_id': id,
      'prayer_type': prayerType.toJson(),
      'event_date': _formatDateOnly(eventDate),
      'event_timestamp': eventTimestamp.toIso8601String(),
      'actual_prayer_time': actualPrayerTime?.toIso8601String(),
      'prayed_in_jamaah': prayedInJamaah ? 1 : 0,
      'within_time_window': withinTimeWindow ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PrayerEvent copyWith({
    int? id,
    PrayerType? prayerType,
    DateTime? eventDate,
    DateTime? eventTimestamp,
    DateTime? actualPrayerTime,
    bool? prayedInJamaah,
    bool? withinTimeWindow,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrayerEvent(
      id: id ?? this.id,
      prayerType: prayerType ?? this.prayerType,
      eventDate: eventDate ?? this.eventDate,
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      actualPrayerTime: actualPrayerTime ?? this.actualPrayerTime,
      prayedInJamaah: prayedInJamaah ?? this.prayedInJamaah,
      withinTimeWindow: withinTimeWindow ?? this.withinTimeWindow,
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
    return other is PrayerEvent &&
        other.id == id &&
        other.prayerType == prayerType &&
        other.eventDate.year == eventDate.year &&
        other.eventDate.month == eventDate.month &&
        other.eventDate.day == eventDate.day &&
        other.eventTimestamp == eventTimestamp &&
        other.actualPrayerTime == actualPrayerTime &&
        other.prayedInJamaah == prayedInJamaah &&
        other.withinTimeWindow == withinTimeWindow &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      prayerType,
      eventDate,
      eventTimestamp,
      actualPrayerTime,
      prayedInJamaah,
      withinTimeWindow,
      notes,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'PrayerEvent(id: $id, prayerType: $prayerType, eventDate: $eventDate, prayedInJamaah: $prayedInJamaah, withinTimeWindow: $withinTimeWindow)';
  }
}
