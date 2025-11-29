import 'enums/nafila_type.dart';

/// Model representing a Nafila prayer's strength score using exponential moving average.
/// Tracks score, streaks, total rakats, and completions for each Nafila type.
class NafilaScore {
  final NafilaType nafilaType;
  final double score; // 0.0 to 1.0
  final int currentStreak;
  final int longestStreak;
  final int totalRakats;
  final int totalCompletions;
  final DateTime calculatedAt;
  final DateTime? lastEventDate;

  const NafilaScore({
    required this.nafilaType,
    required this.score,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalRakats = 0,
    this.totalCompletions = 0,
    required this.calculatedAt,
    this.lastEventDate,
  });

  /// Score as percentage (0-100)
  int get percentage => (score * 100).round();

  /// Average rakats per session
  double get averageRakats =>
      totalCompletions > 0 ? totalRakats / totalCompletions : 0.0;

  factory NafilaScore.fromMap(Map<String, dynamic> map) {
    return NafilaScore(
      nafilaType: NafilaType.fromJson(map['nafila_type'] as String),
      score: map['score'] as double,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      totalRakats: map['total_rakats'] as int,
      totalCompletions: map['total_completions'] as int,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
      lastEventDate: map['last_event_date'] != null
          ? DateTime.parse(map['last_event_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nafila_type': nafilaType.toJson(),
      'score': score,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_rakats': totalRakats,
      'total_completions': totalCompletions,
      'calculated_at': calculatedAt.toIso8601String(),
      'last_event_date': lastEventDate?.toIso8601String(),
    };
  }

  NafilaScore copyWith({
    NafilaType? nafilaType,
    double? score,
    int? currentStreak,
    int? longestStreak,
    int? totalRakats,
    int? totalCompletions,
    DateTime? calculatedAt,
    DateTime? lastEventDate,
  }) {
    return NafilaScore(
      nafilaType: nafilaType ?? this.nafilaType,
      score: score ?? this.score,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalRakats: totalRakats ?? this.totalRakats,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      lastEventDate: lastEventDate ?? this.lastEventDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NafilaScore &&
        other.nafilaType == nafilaType &&
        other.score == score &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.totalRakats == totalRakats &&
        other.totalCompletions == totalCompletions &&
        other.calculatedAt == calculatedAt &&
        other.lastEventDate == lastEventDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      nafilaType,
      score,
      currentStreak,
      longestStreak,
      totalRakats,
      totalCompletions,
      calculatedAt,
      lastEventDate,
    );
  }

  @override
  String toString() {
    return 'NafilaScore(nafilaType: $nafilaType, score: $score, percentage: $percentage%, currentStreak: $currentStreak, longestStreak: $longestStreak, totalRakats: $totalRakats)';
  }
}
