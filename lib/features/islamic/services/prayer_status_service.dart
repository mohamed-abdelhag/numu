import '../models/enums/prayer_status.dart';
import '../models/enums/prayer_type.dart';
import '../models/prayer_event.dart';
import '../models/prayer_schedule.dart';

/// Result of validating a prayer event for future time.
class PrayerValidationResult {
  final bool isValid;
  final String? errorMessage;

  const PrayerValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  const PrayerValidationResult.valid() : isValid = true, errorMessage = null;

  const PrayerValidationResult.invalid(String message)
      : isValid = false,
        errorMessage = message;
}

/// Service for calculating prayer status and validating prayer events.
///
/// This service determines whether a prayer is pending, completed, or missed
/// based on the prayer schedule, time window, and logged events.
class PrayerStatusService {
  /// Default time window in minutes after prayer time starts.
  static const int defaultTimeWindowMinutes = 30;

  /// Calculates the status of a specific prayer.
  ///
  /// The status is determined as follows:
  /// - **completed**: If there is a logged prayer event for this prayer type on the given date
  /// - **missed**: If the time window has expired (current time > prayer time + window) and no event logged
  /// - **pending**: If the prayer time has arrived but window hasn't expired and no event logged
  ///
  /// Note: If current time is before the prayer time, the prayer is considered pending
  /// (waiting for its time to arrive).
  ///
  /// [prayerType] - The type of prayer to check status for
  /// [schedule] - The prayer schedule containing prayer times for the day
  /// [events] - List of prayer events logged for the day
  /// [currentTime] - The current time to evaluate against
  /// [timeWindowMinutes] - Duration of the time window in minutes (default: 30)
  static PrayerStatus calculateStatus({
    required PrayerType prayerType,
    required PrayerSchedule schedule,
    required List<PrayerEvent> events,
    required DateTime currentTime,
    int timeWindowMinutes = defaultTimeWindowMinutes,
  }) {
    // Check if prayer has been completed (logged)
    final hasCompletedEvent = events.any(
      (event) => event.prayerType == prayerType,
    );

    if (hasCompletedEvent) {
      return PrayerStatus.completed;
    }

    // Get the window end time
    final windowEnd = schedule.getTimeWindowEnd(prayerType, timeWindowMinutes);

    // Check if time window has expired
    if (currentTime.isAfter(windowEnd)) {
      return PrayerStatus.missed;
    }

    // Prayer is pending (either time hasn't arrived or within window)
    return PrayerStatus.pending;
  }

  /// Calculates the status for all five prayers.
  ///
  /// Returns a map of prayer type to status.
  static Map<PrayerType, PrayerStatus> calculateAllStatuses({
    required PrayerSchedule schedule,
    required List<PrayerEvent> events,
    required DateTime currentTime,
    int timeWindowMinutes = defaultTimeWindowMinutes,
  }) {
    return {
      for (final type in PrayerType.values)
        type: calculateStatus(
          prayerType: type,
          schedule: schedule,
          events: events,
          currentTime: currentTime,
          timeWindowMinutes: timeWindowMinutes,
        ),
    };
  }

  /// Validates that a prayer event's actual prayer time is not in the future.
  ///
  /// [actualPrayerTime] - The time the user claims to have prayed
  /// [currentTime] - The current time to validate against
  ///
  /// Returns a validation result indicating if the time is valid.
  static PrayerValidationResult validatePrayerTime({
    required DateTime actualPrayerTime,
    required DateTime currentTime,
  }) {
    if (actualPrayerTime.isAfter(currentTime)) {
      return const PrayerValidationResult.invalid(
        'Cannot log a prayer for a future time. Please select a time that has already passed.',
      );
    }

    return const PrayerValidationResult.valid();
  }

  /// Checks if a prayer time is within the time window.
  ///
  /// [actualPrayerTime] - The time the prayer was performed
  /// [scheduledPrayerTime] - The scheduled start time of the prayer
  /// [timeWindowMinutes] - Duration of the time window in minutes
  ///
  /// Returns true if the prayer was performed within the time window.
  static bool isWithinTimeWindow({
    required DateTime actualPrayerTime,
    required DateTime scheduledPrayerTime,
    int timeWindowMinutes = defaultTimeWindowMinutes,
  }) {
    final windowEnd = scheduledPrayerTime.add(
      Duration(minutes: timeWindowMinutes),
    );

    // Prayer is within window if it's at or after the scheduled time
    // and before or at the window end
    return !actualPrayerTime.isBefore(scheduledPrayerTime) &&
        !actualPrayerTime.isAfter(windowEnd);
  }

  /// Gets the next pending prayer from the schedule.
  ///
  /// Returns the prayer type with the earliest start time that:
  /// - Has a start time after the current time
  /// - Has not been completed
  ///
  /// Returns null if all prayers are completed or missed.
  static PrayerType? getNextPendingPrayer({
    required PrayerSchedule schedule,
    required List<PrayerEvent> events,
    required DateTime currentTime,
    int timeWindowMinutes = defaultTimeWindowMinutes,
  }) {
    final statuses = calculateAllStatuses(
      schedule: schedule,
      events: events,
      currentTime: currentTime,
      timeWindowMinutes: timeWindowMinutes,
    );

    // Find pending prayers and sort by prayer time
    final pendingPrayers = PrayerType.values
        .where((type) => statuses[type] == PrayerStatus.pending)
        .toList();

    if (pendingPrayers.isEmpty) {
      return null;
    }

    // Sort by prayer time and return the earliest
    pendingPrayers.sort((a, b) {
      final timeA = schedule.getTimeForPrayer(a);
      final timeB = schedule.getTimeForPrayer(b);
      return timeA.compareTo(timeB);
    });

    return pendingPrayers.first;
  }

  /// Counts the number of completed prayers for the day.
  static int countCompletedPrayers(List<PrayerEvent> events) {
    // Count distinct prayer types that have been completed
    final completedTypes = events.map((e) => e.prayerType).toSet();
    return completedTypes.length;
  }
}
