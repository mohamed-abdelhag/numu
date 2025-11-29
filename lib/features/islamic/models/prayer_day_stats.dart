import 'enums/nafila_type.dart';
import 'enums/prayer_type.dart';

/// Model representing prayer statistics for a single day.
/// Used for calendar view to show completion status of all prayers.
class PrayerDayStats {
  final DateTime date;
  final Map<PrayerType, bool> obligatoryCompleted;
  final Map<NafilaType, bool> nafilaCompleted;
  final int totalRakatsNafila;

  const PrayerDayStats({
    required this.date,
    required this.obligatoryCompleted,
    required this.nafilaCompleted,
    this.totalRakatsNafila = 0,
  });

  /// Number of obligatory prayers completed
  int get obligatoryCompletedCount =>
      obligatoryCompleted.values.where((v) => v).length;

  /// Number of defined Nafila prayers completed (excluding custom)
  int get definedNafilaCompletedCount => nafilaCompleted.entries
      .where((e) => e.key.isDefined && e.value)
      .length;

  /// Total obligatory prayers (always 5)
  int get totalObligatoryPrayers => PrayerType.values.length;

  /// Total defined Nafila prayers (3: Sunnah Fajr, Duha, Shaf'i/Witr)
  int get totalDefinedNafilaPrayers =>
      NafilaType.values.where((t) => t.isDefined).length;

  /// Obligatory completion percentage (0-100)
  int get obligatoryPercentage =>
      (obligatoryCompletedCount / totalObligatoryPrayers * 100).round();

  /// Defined Nafila completion percentage (0-100)
  int get nafilaPercentage => totalDefinedNafilaPrayers > 0
      ? (definedNafilaCompletedCount / totalDefinedNafilaPrayers * 100).round()
      : 0;

  /// Check if a specific obligatory prayer is completed
  bool isObligatoryCompleted(PrayerType type) =>
      obligatoryCompleted[type] ?? false;

  /// Check if a specific Nafila prayer is completed
  bool isNafilaCompleted(NafilaType type) => nafilaCompleted[type] ?? false;

  /// Create empty stats for a date
  factory PrayerDayStats.empty(DateTime date) {
    return PrayerDayStats(
      date: date,
      obligatoryCompleted: {
        for (final type in PrayerType.values) type: false,
      },
      nafilaCompleted: {
        for (final type in NafilaType.values.where((t) => t.isDefined))
          type: false,
      },
      totalRakatsNafila: 0,
    );
  }

  PrayerDayStats copyWith({
    DateTime? date,
    Map<PrayerType, bool>? obligatoryCompleted,
    Map<NafilaType, bool>? nafilaCompleted,
    int? totalRakatsNafila,
  }) {
    return PrayerDayStats(
      date: date ?? this.date,
      obligatoryCompleted: obligatoryCompleted ?? this.obligatoryCompleted,
      nafilaCompleted: nafilaCompleted ?? this.nafilaCompleted,
      totalRakatsNafila: totalRakatsNafila ?? this.totalRakatsNafila,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PrayerDayStats) return false;

    // Compare maps manually
    bool mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (a[key] != b[key]) return false;
      }
      return true;
    }

    return other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        mapsEqual(other.obligatoryCompleted, obligatoryCompleted) &&
        mapsEqual(other.nafilaCompleted, nafilaCompleted) &&
        other.totalRakatsNafila == totalRakatsNafila;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      Object.hashAll(obligatoryCompleted.entries),
      Object.hashAll(nafilaCompleted.entries),
      totalRakatsNafila,
    );
  }

  @override
  String toString() {
    return 'PrayerDayStats(date: $date, obligatory: $obligatoryCompletedCount/$totalObligatoryPrayers, nafila: $definedNafilaCompletedCount/$totalDefinedNafilaPrayers, rakats: $totalRakatsNafila)';
  }
}
