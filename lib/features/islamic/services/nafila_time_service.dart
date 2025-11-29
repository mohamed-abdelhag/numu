import '../models/prayer_schedule.dart';
import '../models/enums/nafila_type.dart';

/// Service for validating Nafila prayer times against prayer schedules.
///
/// Provides time window calculations and validation for:
/// - Sunnah Fajr: Between Fajr azan and Fajr prayer time
/// - Duha: After sunrise + 15 minutes until Dhuhr - 15 minutes
/// - Shaf'i/Witr: After Isha until next day's Fajr azan
///
/// **Validates: Requirements 1.3, 1.4, 1.5**
class NafilaTimeService {
  static final NafilaTimeService _instance = NafilaTimeService._internal();
  factory NafilaTimeService() => _instance;
  NafilaTimeService._internal();

  /// Offset in minutes after sunrise for Duha start time.
  static const int duhaStartOffsetMinutes = 15;

  /// Offset in minutes before Dhuhr for Duha end time.
  static const int duhaEndOffsetMinutes = 15;

  /// Get the time window for Sunnah Fajr prayer.
  ///
  /// Returns a tuple of (start, end) times where:
  /// - start: Fajr azan time (fajrTime from schedule)
  /// - end: Fajr prayer time (same as fajrTime since it's the azan time)
  ///
  /// Note: In this implementation, fajrTime represents the Fajr azan time.
  /// The Sunnah Fajr should be prayed between the azan and when the user
  /// actually prays the obligatory Fajr. Since we don't track when the user
  /// prays the obligatory prayer, we use sunrise as the practical end time.
  ///
  /// **Validates: Requirements 1.3**
  (DateTime start, DateTime end) getSunnahFajrWindow(PrayerSchedule schedule) {
    // Sunnah Fajr window: from Fajr azan until sunrise
    // (practical window since we don't know when user prays obligatory Fajr)
    return (schedule.fajrTime, schedule.sunrise);
  }

  /// Get the time window for Duha prayer.
  ///
  /// Returns a tuple of (start, end) times where:
  /// - start: Sunrise + 15 minutes
  /// - end: Dhuhr - 15 minutes
  ///
  /// **Validates: Requirements 1.4**
  (DateTime start, DateTime end) getDuhaWindow(PrayerSchedule schedule) {
    final start = schedule.sunrise.add(
      const Duration(minutes: duhaStartOffsetMinutes),
    );
    final end = schedule.dhuhrTime.subtract(
      const Duration(minutes: duhaEndOffsetMinutes),
    );
    return (start, end);
  }

  /// Get the time window for Shaf'i/Witr prayer.
  ///
  /// Returns a tuple of (start, end) times where:
  /// - start: Isha prayer time
  /// - end: Next day's Fajr azan time (or midnight + 6 hours if no next day schedule)
  ///
  /// **Validates: Requirements 1.5**
  (DateTime start, DateTime end) getShafiWitrWindow(
    PrayerSchedule schedule,
    PrayerSchedule? nextDaySchedule,
  ) {
    final start = schedule.ishaTime;

    // If we have next day's schedule, use its Fajr time
    // Otherwise, use a reasonable default (6 AM next day)
    final DateTime end;
    if (nextDaySchedule != null) {
      end = nextDaySchedule.fajrTime;
    } else {
      // Default to 6 AM next day if no schedule available
      final nextDay = schedule.date.add(const Duration(days: 1));
      end = DateTime(nextDay.year, nextDay.month, nextDay.day, 6, 0);
    }

    return (start, end);
  }

  /// Validate if a time is within the Sunnah Fajr window.
  ///
  /// Returns true if the time is between Fajr azan and sunrise.
  ///
  /// **Validates: Requirements 1.3**
  bool isValidTimeForSunnahFajr(DateTime time, PrayerSchedule schedule) {
    final (start, end) = getSunnahFajrWindow(schedule);
    return _isTimeInWindow(time, start, end);
  }

  /// Validate if a time is within the Duha window.
  ///
  /// Returns true if the time is after sunrise + 15 minutes
  /// and before Dhuhr - 15 minutes.
  ///
  /// **Validates: Requirements 1.4**
  bool isValidTimeForDuha(DateTime time, PrayerSchedule schedule) {
    final (start, end) = getDuhaWindow(schedule);
    return _isTimeInWindow(time, start, end);
  }

  /// Validate if a time is within the Shaf'i/Witr window.
  ///
  /// Returns true if the time is after Isha and before next day's Fajr.
  /// Handles the case where the time crosses midnight.
  ///
  /// **Validates: Requirements 1.5**
  bool isValidTimeForShafiWitr(
    DateTime time,
    PrayerSchedule schedule,
    PrayerSchedule? nextDaySchedule,
  ) {
    final (start, end) = getShafiWitrWindow(schedule, nextDaySchedule);
    return _isTimeInWindowCrossingMidnight(time, start, end);
  }

  /// Determine which Nafila type a given time belongs to.
  ///
  /// Returns the NafilaType if the time falls within a defined Sunnah window,
  /// or null if the time doesn't match any defined window.
  ///
  /// Note: This only returns defined Sunnah types (sunnahFajr, duha, shafiWitr),
  /// never returns NafilaType.custom.
  NafilaType? getNafilaTypeForTime(
    DateTime time,
    PrayerSchedule schedule, {
    PrayerSchedule? nextDaySchedule,
  }) {
    // Check Sunnah Fajr window first
    if (isValidTimeForSunnahFajr(time, schedule)) {
      return NafilaType.sunnahFajr;
    }

    // Check Duha window
    if (isValidTimeForDuha(time, schedule)) {
      return NafilaType.duha;
    }

    // Check Shaf'i/Witr window
    if (isValidTimeForShafiWitr(time, schedule, nextDaySchedule)) {
      return NafilaType.shafiWitr;
    }

    return null;
  }

  /// Check if a time is within a window (inclusive of start, exclusive of end).
  bool _isTimeInWindow(DateTime time, DateTime start, DateTime end) {
    // Normalize to compare only time components if on the same day
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // If comparing same day, use simple comparison
    if (_isSameDay(time, start) && _isSameDay(time, end)) {
      return timeMinutes >= startMinutes && timeMinutes < endMinutes;
    }

    // For cross-day comparison, use full DateTime comparison
    return !time.isBefore(start) && time.isBefore(end);
  }

  /// Check if a time is within a window that may cross midnight.
  ///
  /// This handles the Shaf'i/Witr case where the window starts after Isha
  /// (e.g., 8 PM) and ends at next day's Fajr (e.g., 5 AM).
  bool _isTimeInWindowCrossingMidnight(
    DateTime time,
    DateTime start,
    DateTime end,
  ) {
    // If end is after start (no midnight crossing), use normal comparison
    if (!end.isBefore(start)) {
      return !time.isBefore(start) && time.isBefore(end);
    }

    // Window crosses midnight: time is valid if it's after start OR before end
    // For example: start=22:00, end=05:00
    // Valid times: 22:00-23:59 (same day) OR 00:00-04:59 (next day)
    return !time.isBefore(start) || time.isBefore(end);
  }

  /// Check if two DateTimes are on the same calendar day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
