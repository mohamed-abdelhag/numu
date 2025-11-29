import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_event.dart';
import '../models/prayer_settings.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/prayer_status.dart';
import '../repositories/prayer_repository.dart';
import '../repositories/prayer_settings_repository.dart';
import '../services/prayer_status_service.dart';
import '../services/prayer_score_service.dart';
import 'prayer_settings_provider.dart';
import 'prayer_schedule_provider.dart';
import 'prayer_score_provider.dart';

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
  PrayerRepository? _repository;
  PrayerSettingsRepository? _settingsRepository;
  PrayerScoreService? _scoreService;
  
  bool _isMounted = true;

  @override
  Future<PrayerState> build() async {
    _repository = PrayerRepository();
    _settingsRepository = PrayerSettingsRepository();
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
      // Check if prayer system is enabled - use read for initial load to avoid watch after async gaps
      final settingsFuture = ref.watch(prayerSettingsProvider.future);
      final scheduleFuture = ref.watch(prayerScheduleProvider.future);
      
      // Await both futures together to minimize async gaps
      final results = await Future.wait([
        settingsFuture,
        scheduleFuture,
      ]);
      
      // Check if still mounted after async operation
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'PrayerProvider',
          'build',
          'Provider disposed during build, returning empty state',
        );
        return const PrayerState(isEnabled: false);
      }
      
      final settings = results[0] as PrayerSettings;
      final scheduleState = results[1] as PrayerScheduleState;
      
      if (!settings.isEnabled) {
        return const PrayerState(isEnabled: false);
      }

      // Get today's schedule
      final schedule = scheduleState.schedule;
      
      if (schedule == null) {
        return const PrayerState(isEnabled: true);
      }

      // Get today's events
      final today = DateTime.now();
      final events = await _getRepository().getEventsForDate(today);
      
      // Check mounted state again after repository call
      if (!_isMounted) {
        return const PrayerState(isEnabled: false);
      }

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

  /// Get repository, ensuring it's initialized
  PrayerRepository _getRepository() {
    _repository ??= PrayerRepository();
    return _repository!;
  }
  
  /// Get settings repository, ensuring it's initialized
  PrayerSettingsRepository _getSettingsRepository() {
    _settingsRepository ??= PrayerSettingsRepository();
    return _settingsRepository!;
  }
  
  /// Get score service, ensuring it's initialized
  PrayerScoreService _getScoreService() {
    _scoreService ??= PrayerScoreService();
    return _scoreService!;
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

      // Check mounted before async operations
      if (!_isMounted) return;

      // Get current schedule to determine if within time window
      // Use settings repository directly to avoid ref usage after async gaps
      final settings = await _getSettingsRepository().getSettings();
      if (!_isMounted) return;
      
      final scheduleState = await ref.read(prayerScheduleProvider.future);
      if (!_isMounted) return;
      
      final schedule = scheduleState.schedule;
      
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
      await _getRepository().logPrayerEvent(event);
      if (!_isMounted) return;

      // Recalculate score for this prayer type
      await _getScoreService().recalculateScore(prayerType);

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

      await _getRepository().deletePrayerEvent(eventId);

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

  /// Update an existing prayer event (e.g., to edit the actual prayer time).
  /// This is for honest self-improvement - be truthful about when you prayed.
  Future<void> updatePrayerEvent({
    required PrayerEvent existingEvent,
    DateTime? newActualPrayerTime,
    bool? prayedInJamaah,
    String? notes,
  }) async {
    if (!_isMounted) {
      CoreLoggingUtility.warning(
        'PrayerProvider',
        'updatePrayerEvent',
        'Provider not mounted, aborting update',
      );
      return;
    }
    if (existingEvent.id == null) {
      throw ArgumentError('Cannot update prayer event without an ID');
    }

    try {
      CoreLoggingUtility.info(
        'PrayerProvider',
        'updatePrayerEvent',
        'Starting update for event ID ${existingEvent.id}, '
        'prayer: ${existingEvent.prayerType.englishName}, '
        'newTime: ${newActualPrayerTime?.toIso8601String()}, '
        'jamaah: $prayedInJamaah',
      );

      final now = DateTime.now();
      final prayerTime = newActualPrayerTime ?? existingEvent.actualPrayerTime ?? now;

      // Check mounted before async operations
      if (!_isMounted) return;

      // Get current schedule to determine if within time window
      CoreLoggingUtility.info(
        'PrayerProvider',
        'updatePrayerEvent',
        'Fetching settings and schedule...',
      );
      final settings = await _getSettingsRepository().getSettings();
      if (!_isMounted) return;
      
      final scheduleState = await ref.read(prayerScheduleProvider.future);
      if (!_isMounted) return;
      
      final schedule = scheduleState.schedule;
      
      bool withinTimeWindow = false;
      if (schedule != null) {
        final scheduledTime = schedule.getTimeForPrayer(existingEvent.prayerType);
        withinTimeWindow = PrayerStatusService.isWithinTimeWindow(
          actualPrayerTime: prayerTime,
          scheduledPrayerTime: scheduledTime,
          timeWindowMinutes: settings.timeWindowMinutes,
        );
        CoreLoggingUtility.info(
          'PrayerProvider',
          'updatePrayerEvent',
          'Time window check: scheduledTime=${scheduledTime.toIso8601String()}, '
          'actualTime=${prayerTime.toIso8601String()}, '
          'windowMinutes=${settings.timeWindowMinutes}, '
          'withinWindow=$withinTimeWindow',
        );
      }

      // Update the prayer event
      final updatedEvent = existingEvent.copyWith(
        actualPrayerTime: newActualPrayerTime ?? existingEvent.actualPrayerTime,
        prayedInJamaah: prayedInJamaah ?? existingEvent.prayedInJamaah,
        withinTimeWindow: withinTimeWindow,
        notes: notes ?? existingEvent.notes,
        updatedAt: now,
      );

      CoreLoggingUtility.info(
        'PrayerProvider',
        'updatePrayerEvent',
        'Saving updated event to repository: '
        'id=${updatedEvent.id}, '
        'actualTime=${updatedEvent.actualPrayerTime?.toIso8601String()}, '
        'jamaah=${updatedEvent.prayedInJamaah}, '
        'withinWindow=${updatedEvent.withinTimeWindow}',
      );

      // Save to repository
      await _getRepository().updatePrayerEvent(updatedEvent);
      if (!_isMounted) return;

      CoreLoggingUtility.info(
        'PrayerProvider',
        'updatePrayerEvent',
        'Repository update complete, recalculating score...',
      );

      // Recalculate score for this prayer type
      await _getScoreService().recalculateScore(existingEvent.prayerType);

      CoreLoggingUtility.info(
        'PrayerProvider',
        'updatePrayerEvent',
        'Score recalculated, invalidating provider state for UI refresh...',
      );

      // Refresh state - this will trigger UI update
      if (_isMounted) {
        ref.invalidateSelf();
        // Also invalidate score provider to refresh stats
        ref.invalidate(prayerScoreProvider);
        CoreLoggingUtility.info(
          'PrayerProvider',
          'updatePrayerEvent',
          'Provider state invalidated - UI should refresh now',
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerProvider',
        'updatePrayerEvent',
        'Failed to update prayer event: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Get today's event for a specific prayer type.
  PrayerEvent? getEventForPrayer(PrayerType prayerType) {
    final currentState = state.value;
    if (currentState == null) return null;
    
    try {
      return currentState.todayEvents.firstWhere(
        (event) => event.prayerType == prayerType,
      );
    } catch (_) {
      return null;
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
