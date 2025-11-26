/// Represents the five daily Islamic prayers (Salah).
enum PrayerType {
  fajr,    // Dawn prayer
  dhuhr,   // Noon prayer
  asr,     // Afternoon prayer
  maghrib, // Sunset prayer
  isha;    // Night prayer

  /// Arabic name of the prayer.
  String get arabicName => switch (this) {
    PrayerType.fajr => 'الفجر',
    PrayerType.dhuhr => 'الظهر',
    PrayerType.asr => 'العصر',
    PrayerType.maghrib => 'المغرب',
    PrayerType.isha => 'العشاء',
  };

  /// English name of the prayer.
  String get englishName => switch (this) {
    PrayerType.fajr => 'Fajr',
    PrayerType.dhuhr => 'Dhuhr',
    PrayerType.asr => 'Asr',
    PrayerType.maghrib => 'Maghrib',
    PrayerType.isha => 'Isha',
  };

  /// Sort order for displaying prayers in chronological order.
  int get sortOrder => index;

  String toJson() => name;

  static PrayerType fromJson(String json) {
    return PrayerType.values.firstWhere((e) => e.name == json);
  }
}
