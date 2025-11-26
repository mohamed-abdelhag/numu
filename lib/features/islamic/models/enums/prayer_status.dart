/// Represents the status of a prayer for a given day.
enum PrayerStatus {
  pending,   // Prayer time has arrived but not yet logged
  completed, // Prayer has been logged
  missed;    // Time window expired without logging

  String toJson() => name;

  static PrayerStatus fromJson(String json) {
    return PrayerStatus.values.firstWhere((e) => e.name == json);
  }
}
