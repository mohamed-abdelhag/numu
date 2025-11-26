import 'enums/prayer_type.dart';

/// Model representing a prayer's strength score using exponential moving average.
/// Tracks score, streaks, and Jamaah (congregation) rate for each prayer type.
class PrayerScore {
  final PrayerType prayerType;
  final double score; // 0.0 to 1.0
  final int currentStreak;
  final int longestStreak;
  final double jamaahRate; // Percentage prayed in congregation (0.0 to 1.0)
  final DateTime calculatedAt;
  final DateTime? lastEventDate;

  const PrayerScore({
    required this.prayerType,
    required this.score,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.jamaahRate = 0.0,
    required this.calculatedAt,
    this.lastEventDate,
  });

  /// Score as percentage (0-100)
  int get percentage => (score * 100).round();

  /// Jamaah rate as percentage (0-100)
  int get jamaahPercentage => (jamaahRate * 100).round();

  factory PrayerScore.fromMap(Map<String, dynamic> map) {
    return PrayerScore(
      prayerType: PrayerType.fromJson(map['prayer_type'] as String),
      score: map['score'] as double,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      jamaahRate: map['jamaah_rate'] as double,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
      lastEventDate: map['last_event_date'] != null
          ? DateTime.parse(map['last_event_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayer_type': prayerType.toJson(),
      'score': score,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'jamaah_rate': jamaahRate,
      'calculated_at': calculatedAt.toIso8601String(),
      'last_event_date': lastEventDate?.toIso8601String(),
    };
  }

  PrayerScore copyWith({
    PrayerType? prayerType,
    double? score,
    int? currentStreak,
    int? longestStreak,
    double? jamaahRate,
    DateTime? calculatedAt,
    DateTime? lastEventDate,
  }) {
    return PrayerScore(
      prayerType: prayerType ?? this.prayerType,
      score: score ?? this.score,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      jamaahRate: jamaahRate ?? this.jamaahRate,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      lastEventDate: lastEventDate ?? this.lastEventDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerScore &&
        other.prayerType == prayerType &&
        other.score == score &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.jamaahRate == jamaahRate &&
        other.calculatedAt == calculatedAt &&
        other.lastEventDate == lastEventDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      prayerType,
      score,
      currentStreak,
      longestStreak,
      jamaahRate,
      calculatedAt,
      lastEventDate,
    );
  }

  @override
  String toString() {
    return 'PrayerScore(prayerType: $prayerType, score: $score, percentage: $percentage%, currentStreak: $currentStreak, longestStreak: $longestStreak, jamaahRate: $jamaahRate)';
  }
}
