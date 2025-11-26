import 'enums/calculation_method.dart';
import 'enums/prayer_type.dart';

/// Represents a daily prayer schedule with times for all five prayers.
/// Contains location and calculation method used to generate the times.
class PrayerSchedule {
  final int? id;
  final DateTime date;
  final double latitude;
  final double longitude;
  final CalculationMethod method;
  final DateTime fajrTime;
  final DateTime dhuhrTime;
  final DateTime asrTime;
  final DateTime maghribTime;
  final DateTime ishaTime;
  final DateTime sunrise; // For reference
  final DateTime createdAt;

  const PrayerSchedule({
    this.id,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.fajrTime,
    required this.dhuhrTime,
    required this.asrTime,
    required this.maghribTime,
    required this.ishaTime,
    required this.sunrise,
    required this.createdAt,
  });

  /// Get the prayer time for a specific prayer type.
  DateTime getTimeForPrayer(PrayerType type) => switch (type) {
        PrayerType.fajr => fajrTime,
        PrayerType.dhuhr => dhuhrTime,
        PrayerType.asr => asrTime,
        PrayerType.maghrib => maghribTime,
        PrayerType.isha => ishaTime,
      };

  /// Get the end of the time window for a specific prayer.
  DateTime getTimeWindowEnd(PrayerType type, int windowMinutes) {
    return getTimeForPrayer(type).add(Duration(minutes: windowMinutes));
  }

  factory PrayerSchedule.fromMap(Map<String, dynamic> map) {
    return PrayerSchedule(
      id: map['schedule_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      method: CalculationMethod.fromJson(map['calculation_method'] as String),
      fajrTime: DateTime.parse(map['fajr_time'] as String),
      dhuhrTime: DateTime.parse(map['dhuhr_time'] as String),
      asrTime: DateTime.parse(map['asr_time'] as String),
      maghribTime: DateTime.parse(map['maghrib_time'] as String),
      ishaTime: DateTime.parse(map['isha_time'] as String),
      sunrise: DateTime.parse(map['sunrise_time'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'schedule_id': id,
      'date': _formatDateOnly(date),
      'latitude': latitude,
      'longitude': longitude,
      'calculation_method': method.toJson(),
      'fajr_time': fajrTime.toIso8601String(),
      'dhuhr_time': dhuhrTime.toIso8601String(),
      'asr_time': asrTime.toIso8601String(),
      'maghrib_time': maghribTime.toIso8601String(),
      'isha_time': ishaTime.toIso8601String(),
      'sunrise_time': sunrise.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  PrayerSchedule copyWith({
    int? id,
    DateTime? date,
    double? latitude,
    double? longitude,
    CalculationMethod? method,
    DateTime? fajrTime,
    DateTime? dhuhrTime,
    DateTime? asrTime,
    DateTime? maghribTime,
    DateTime? ishaTime,
    DateTime? sunrise,
    DateTime? createdAt,
  }) {
    return PrayerSchedule(
      id: id ?? this.id,
      date: date ?? this.date,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      method: method ?? this.method,
      fajrTime: fajrTime ?? this.fajrTime,
      dhuhrTime: dhuhrTime ?? this.dhuhrTime,
      asrTime: asrTime ?? this.asrTime,
      maghribTime: maghribTime ?? this.maghribTime,
      ishaTime: ishaTime ?? this.ishaTime,
      sunrise: sunrise ?? this.sunrise,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format date as YYYY-MM-DD for database storage
  static String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerSchedule &&
        other.id == id &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.method == method &&
        other.fajrTime == fajrTime &&
        other.dhuhrTime == dhuhrTime &&
        other.asrTime == asrTime &&
        other.maghribTime == maghribTime &&
        other.ishaTime == ishaTime &&
        other.sunrise == sunrise &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      latitude,
      longitude,
      method,
      fajrTime,
      dhuhrTime,
      asrTime,
      maghribTime,
      ishaTime,
      sunrise,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'PrayerSchedule(id: $id, date: $date, latitude: $latitude, longitude: $longitude, method: $method)';
  }
}
