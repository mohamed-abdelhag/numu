/// Enum representing different types of streaks that can be tracked
enum StreakType {
  /// Basic completion streak - habit was completed according to its goal
  completion,
  
  /// Time window streak - habit was completed within the preferred time window
  timeWindow,
  
  /// Quality streak - habit was completed with quality achievement
  quality,
  
  /// Perfect streak - habit was completed with all criteria (completion + time window + quality)
  perfect;

  /// Convert enum to JSON string for database storage
  String toJson() => name;

  /// Create enum from JSON string
  static StreakType fromJson(String json) {
    return StreakType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => StreakType.completion,
    );
  }
}
