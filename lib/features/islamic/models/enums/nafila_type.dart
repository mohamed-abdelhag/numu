/// Represents the types of Nafila (voluntary) prayers.
/// Includes defined Sunnah prayers and custom Nafila.
enum NafilaType {
  sunnahFajr, // 2 rakats before Fajr prayer
  duha, // 2-12 rakats after sunrise until before Dhuhr
  shafiWitr, // Night prayers after Isha (Shaf'i is even, Witr is odd)
  custom; // User-defined Nafila prayers

  /// Arabic name of the Nafila prayer.
  String get arabicName => switch (this) {
        NafilaType.sunnahFajr => 'سنة الفجر',
        NafilaType.duha => 'صلاة الضحى',
        NafilaType.shafiWitr => 'الشفع والوتر',
        NafilaType.custom => 'نافلة',
      };

  /// English name of the Nafila prayer.
  String get englishName => switch (this) {
        NafilaType.sunnahFajr => 'Sunnah Fajr',
        NafilaType.duha => 'Duha',
        NafilaType.shafiWitr => "Shaf'i/Witr",
        NafilaType.custom => 'Custom Nafila',
      };

  /// Minimum number of rakats for this Nafila type.
  int get minRakats => switch (this) {
        NafilaType.sunnahFajr => 2,
        NafilaType.duha => 2,
        NafilaType.shafiWitr => 1, // Witr can be 1 rakat
        NafilaType.custom => 2,
      };

  /// Maximum number of rakats for this Nafila type.
  int get maxRakats => switch (this) {
        NafilaType.sunnahFajr => 2,
        NafilaType.duha => 12,
        NafilaType.shafiWitr => 11, // 2+2+2+2+2+1 (Shaf'i pairs + Witr)
        NafilaType.custom => 12,
      };

  /// Default number of rakats for this Nafila type.
  int get defaultRakats => switch (this) {
        NafilaType.sunnahFajr => 2,
        NafilaType.duha => 2,
        NafilaType.shafiWitr => 3, // 2 Shaf'i + 1 Witr
        NafilaType.custom => 2,
      };

  /// Whether this is a defined Sunnah prayer (not custom).
  bool get isDefined => this != NafilaType.custom;

  /// Sort order for displaying Nafila prayers in chronological order.
  int get sortOrder => index;

  String toJson() => name;

  static NafilaType fromJson(String json) {
    return NafilaType.values.firstWhere((e) => e.name == json);
  }
}
