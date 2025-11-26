/// Model representing a habit's strength score using exponential moving average
class HabitScore {
  final int habitId;
  final double score; // 0.0 to 1.0
  final DateTime calculatedAt;
  final DateTime? lastEventDate;

  const HabitScore({
    required this.habitId,
    required this.score,
    required this.calculatedAt,
    this.lastEventDate,
  });

  /// Score as percentage (0-100)
  int get percentage => (score * 100).round();

  factory HabitScore.fromMap(Map<String, dynamic> map) {
    return HabitScore(
      habitId: map['habit_id'] as int,
      score: map['score'] as double,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
      lastEventDate: map['last_event_date'] != null
          ? DateTime.parse(map['last_event_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habit_id': habitId,
      'score': score,
      'calculated_at': calculatedAt.toIso8601String(),
      'last_event_date': lastEventDate?.toIso8601String(),
    };
  }

  HabitScore copyWith({
    int? habitId,
    double? score,
    DateTime? calculatedAt,
    DateTime? lastEventDate,
  }) {
    return HabitScore(
      habitId: habitId ?? this.habitId,
      score: score ?? this.score,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      lastEventDate: lastEventDate ?? this.lastEventDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitScore &&
        other.habitId == habitId &&
        other.score == score &&
        other.calculatedAt == calculatedAt &&
        other.lastEventDate == lastEventDate;
  }

  @override
  int get hashCode {
    return Object.hash(habitId, score, calculatedAt, lastEventDate);
  }

  @override
  String toString() {
    return 'HabitScore(habitId: $habitId, score: $score, percentage: $percentage%, calculatedAt: $calculatedAt, lastEventDate: $lastEventDate)';
  }
}
