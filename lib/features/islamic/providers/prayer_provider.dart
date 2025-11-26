import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_event.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/prayer_status.dart';
import '../repositories/prayer_repository.dart';
import '../services/prayer_status_service.dart';
import '../services/prayer_score_service.dart';
import 'prayer_settings_provider.dart';
import 'prayer_schedule_provider.dart';

part 'prayer_provider.g.dart';

/// State class for today's prayer status and events
class PrayerState {
  final List<PrayerEvent> todayEvents;
  final Map<PrayerType, PrayerStatus> statuses;
  final int completedCount;
  final bool isEnabled;

  const PrayerState({
    this.todayEvents = const [],
    this.statuses = const {},
    this.completedCount = 0,
    this.isEnabled = false,
  });

  PrayerState copyWith({
    List<PrayerEvent>? todayEvents,
    Map<PrayerType, PrayerStatus>? statuses,
    int? completedCount,
    bool? isEnabled,
  }) {
    return PrayerState(
      todayEvents: todayEvents ?? this.todayEvents,
      statuses: statuses ?? this.statuses,
      completedCount: completedCount ?? this.completedCount,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Check if a specific prayer is completed
  bool isPrayerCompleted(PrayerType type) {
    return statuses[type] == PrayerStatus.completed;
  }

  /// Get the status for a specific prayer
  PrayerStatus? getStatus(PrayerType type) => statuses[type];
}

/// Provider for managing prayer events and status for today.
///
/// **Validates: Requirements 2.1, 6.1, 6.5**
@riverpod
class PrayerNotifier extends _$PrayerNotifier {
  late final PrayerRepository _repository;
  late final PrayerScoreService _scoreService;
  
  bool _isMounted = true;

  @override
  Future<PrayerState> build() async {
    _repository = PrayerRepository();
    _scoreService = PrayerScoreService();
    _isMounted = true;
    
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'PrayerProvider',
        'dispose',
        'Provider disposed',
      );
    });
    
    try {
      // Check if prayer system is enabled
      final settings = await ref.watch(prayerSettingsProvider.future);
      if (!settings.isEnabled) {
        return const PrayerState(isEnabled: false);
      }

      // Get today's schedule
      final scheduleState = await ref.watch(prayerScheduleProvider.future);
      final schedule = scheduleState.schedule;
      
      if (schedule == null) {
        return const PrayerState(isEnabled: true);
      }

      // Get today's events
      final today = DateTime.now();
      final events = await _repository.getEventsForDate(today);

      // Calculate statuses for all prayers
      final statuses = PrayerStatusService.calculateAllStatuses(
        schedule: schedule,
        events: events,
        currentTime: today,
        timeWindowMinutes: settings.timeWindowMinutes,
      );

      // Count completed prayers
      final completedCount = PrayerStatusService.countCompletedPrayers(events);

      CoreLoggingUtility.info(
        'PrayerProvider',
        'build',
        'Loaded prayer state: $completedCount/5 completed',
      );

      return PrayerState(
        todayEvents: events,
        statuses: statuses,
        completedCount: completedCount,
        isEnabled: true,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerProvider',
        'build',
        'Failed to load prayer state: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Log a prayer as completed.
  ///
  /// **Validates: Requirements 2.1, 2.2, 2.3**
  Future<void> logPrayer({
    required PrayerType prayerType,
    DateTime? actualPrayerTime,
    bool prayedInJamaah = false,
    String? notes,
  }) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'PrayerProvider',
        'logPrayer',
        'Logging ${prayerType.englishName} prayer',
      );

      final now = DateTime.now();
      final prayerTime = actualPrayerTime ?? now;

      // Validate that prayer time is not in the future
      final validation = PrayerStatusService.validatePrayerTime(
        actualPrayerTime: prayerTime,
        currentTime: now,
      );

      if (!validation.isValid) {
        throw ArgumentError(validation.errorMessage);
      }

      // Get current schedule to determine if within time window
      final settings = await ref.read(prayerSettingsProvider.future);
      final schedule = await ref.read(todayPrayerScheduleProvider.future);
      
      bool withinTimeWindow = false;
      if (schedule != null) {
        withinTimeWindow = PrayerStatusService.isWithinTimeWindow(
          actualPrayerTime: prayerTime,
          scheduledPrayerTime: schedule.getTimeForPrayer(prayerType),
          timeWindowMinutes: settings.timeWindowMinutes,
        );
      }

      // Create the prayer event
      final event = PrayerEvent(
        prayerType: prayerType,
        eventDate: now,
        eventTimestamp: now,
        actualPrayerTime: actualPrayerTime,
        prayedInJamaah: prayedInJamaah,
        withinTimeWindow: withinTimeWindow,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      // Save to repository
      await _repository.logPrayerEvent(event);

      // Recalculate score for this prayer type
      await _scoreService.recalculateScore(prayerType);

      CoreLoggingUtility.info(
        'PrayerProvider',
        'logPrayer',
        'Successfully logged ${prayerType.englishName} prayer',
      );

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerProvider',
        'logPrayer',
        'Failed to log prayer: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Delete a prayer event.
  Future<void> deletePrayerEvent(int eventId) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'PrayerProvider',
        'deletePrayerEvent',
        'Deleting prayer event ID $eventId',
      );

      await _repository.deletePrayerEvent(eventId);

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerProvider',
        'deletePrayerEvent',
        'Failed to delete prayer event: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Refresh the prayer state.
  Future<void> refresh() async {
    if (!_isMounted) return;
    ref.invalidateSelf();
  }
}

/// Provider for getting the completion count for today.
///
/// **Validates: Requirements 6.5**
@riverpod
Future<int> prayerCompletionCount(Ref ref) async {
  final prayerState = await ref.watch(prayerProvider.future);
  return prayerState.completedCount;
}

/// Provider for getting the status of a specific prayer.
@riverpod
Future<PrayerStatus?> prayerStatus(Ref ref, PrayerType type) async {
  final prayerState = await ref.watch(prayerProvider.future);
  return prayerState.getStatus(type);
}

/// Provider for checking if a specific prayer is completed.
@riverpod
Future<bool> isPrayerCompleted(Ref ref, PrayerType type) async {
  final prayerState = await ref.watch(prayerProvider.future);
  return prayerState.isPrayerCompleted(type);
}

/// Utility function to count completed prayers from a list of events.
/// This is exposed for testing purposes.
///
/// **Validates: Requirements 6.5**
int countCompletedPrayers(List<PrayerEvent> events) {
  return PrayerStatusService.countCompletedPrayers(events);
}
