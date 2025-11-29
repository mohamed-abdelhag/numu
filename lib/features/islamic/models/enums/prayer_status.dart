/// Represents the status of a prayer for a given day.
enum PrayerStatus {
  pending,       // Prayer time has arrived but not yet logged
  completed,     // Prayer has been logged within the time window
  completedLate, // Prayer has been logged but after the time window expired
  missed;        // Time window expired without logging

  String toJson() => name;

  static PrayerStatus fromJson(String json) {
    return PrayerStatus.values.firstWhere((e) => e.name == json);
  }
  
  /// Whether this status represents a completed prayer (either on time or late)
  bool get isCompleted => this == completed || this == completedLate;
}
