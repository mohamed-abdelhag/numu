import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_settings.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/prayer_status.dart';
import '../services/prayer_time_service.dart';
import '../services/prayer_location_service.dart';
import '../services/prayer_status_service.dart';
import '../repositories/prayer_repository.dart';
import 'prayer_settings_provider.dart';

part 'prayer_schedule_provider.g.dart';

/// State class for prayer schedule with additional computed properties
class PrayerScheduleState {
  final PrayerSchedule? schedule;
  final PrayerType? nextPrayer;
  final Duration? timeUntilNextPrayer;
  final bool isOfflineMode;
  final String? errorMessage;

  const PrayerScheduleState({
    this.schedule,
    this.nextPrayer,
    this.timeUntilNextPrayer,
    this.isOfflineMode = false,
    this.errorMessage,
  });

  PrayerScheduleState copyWith({
    PrayerSchedule? schedule,
    PrayerType? nextPrayer,
    Duration? timeUntilNextPrayer,
    bool? isOfflineMode,
    String? errorMessage,
  }) {
    return PrayerScheduleState(
      schedule: schedule ?? this.schedule,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      timeUntilNextPrayer: timeUntilNextPrayer ?? this.timeUntilNextPrayer,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for managing today's prayer schedule and next prayer identification.
///
/// **Validates: Requirements 6.2, 6.3**
@riverpod
class PrayerScheduleNotifier extends _$PrayerScheduleNotifier {
  late final PrayerTimeService _timeService;
  late final PrayerLocationService _locationService;
  late final PrayerRepository _repository;
  
  bool _isMounted = true;

  @override
  Future<PrayerScheduleState> build() async {
    _timeService = PrayerTimeService();
    _locationService = PrayerLocationService();
    _repository = PrayerRepository();
    _isMounted = true;
    
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'PrayerScheduleProvider',
        'dispose',
        'Provider disposed',
      );
    });

    
    try {
      // Check if prayer system is enabled
      final settings = await ref.watch(prayerSettingsProvider.future);
      if (!settings.isEnabled) {
        CoreLoggingUtility.info(
          'PrayerScheduleProvider',
          'build',
          'Prayer system is disabled, returning empty state',
        );
        return const PrayerScheduleState();
      }

      // Try to get prayer schedule for today
      final schedule = await _fetchTodaySchedule(settings);
      
      if (schedule == null) {
        return const PrayerScheduleState(
          errorMessage: 'Unable to fetch prayer times. Please check your location settings.',
        );
      }

      // Get today's events to determine next prayer
      final today = DateTime.now();
      final events = await _repository.getEventsForDate(today);
      
      // Calculate next prayer
      final nextPrayer = PrayerStatusService.getNextPendingPrayer(
        schedule: schedule,
        events: events,
        currentTime: today,
        timeWindowMinutes: settings.timeWindowMinutes,
      );

      // Calculate time until next prayer
      Duration? timeUntilNext;
      if (nextPrayer != null) {
        final nextPrayerTime = schedule.getTimeForPrayer(nextPrayer);
        if (nextPrayerTime.isAfter(today)) {
          timeUntilNext = nextPrayerTime.difference(today);
        }
      }

      CoreLoggingUtility.info(
        'PrayerScheduleProvider',
        'build',
        'Loaded schedule for today, next prayer: ${nextPrayer?.englishName ?? "none"}',
      );

      return PrayerScheduleState(
        schedule: schedule,
        nextPrayer: nextPrayer,
        timeUntilNextPrayer: timeUntilNext,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerScheduleProvider',
        'build',
        'Failed to load prayer schedule: $e\n$stackTrace',
      );
      return PrayerScheduleState(
        errorMessage: 'Failed to load prayer times: $e',
      );
    }
  }

  /// Fetch today's prayer schedule using location and settings
  Future<PrayerSchedule?> _fetchTodaySchedule(PrayerSettings settings) async {
    try {
      // Check for location permission
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        CoreLoggingUtility.warning(
          'PrayerScheduleProvider',
          '_fetchTodaySchedule',
          'Location permission not granted',
        );
        
        // Try to use last known location from settings
        if (settings.lastLatitude != null && settings.lastLongitude != null) {
          return await _timeService.getPrayerTimesForToday(
            latitude: settings.lastLatitude!,
            longitude: settings.lastLongitude!,
            method: settings.calculationMethod,
          );
        }
        return null;
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        CoreLoggingUtility.warning(
          'PrayerScheduleProvider',
          '_fetchTodaySchedule',
          'Could not get current location',
        );
        
        // Fall back to last known location
        if (settings.lastLatitude != null && settings.lastLongitude != null) {
          return await _timeService.getPrayerTimesForToday(
            latitude: settings.lastLatitude!,
            longitude: settings.lastLongitude!,
            method: settings.calculationMethod,
          );
        }
        return null;
      }

      // Fetch prayer times
      return await _timeService.getPrayerTimesForToday(
        latitude: location.latitude,
        longitude: location.longitude,
        method: settings.calculationMethod,
      );
    } on PrayerTimeException catch (e) {
      CoreLoggingUtility.error(
        'PrayerScheduleProvider',
        '_fetchTodaySchedule',
        'Prayer time service error: ${e.message}',
      );
      
      if (e.isNetworkError) {
        // Return cached schedule if available
        final cached = await _timeService.getCachedSchedule(DateTime.now());
        if (cached != null) {
          return cached;
        }
      }
      return null;
    }
  }


  /// Refresh the prayer schedule
  Future<void> refresh() async {
    if (!_isMounted) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Get the next pending prayer based on current time and events
  ///
  /// **Validates: Requirements 6.3**
  PrayerType? getNextPendingPrayer({
    required PrayerSchedule schedule,
    required List<dynamic> events,
    required DateTime currentTime,
    int timeWindowMinutes = 30,
  }) {
    // Calculate statuses for all prayers
    final statuses = <PrayerType, PrayerStatus>{};
    
    for (final type in PrayerType.values) {
      final hasCompleted = events.any((e) => e.prayerType == type);
      
      if (hasCompleted) {
        statuses[type] = PrayerStatus.completed;
        continue;
      }
      
      final windowEnd = schedule.getTimeWindowEnd(type, timeWindowMinutes);
      if (currentTime.isAfter(windowEnd)) {
        statuses[type] = PrayerStatus.missed;
      } else {
        statuses[type] = PrayerStatus.pending;
      }
    }

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

  /// Calculate time remaining until a specific prayer
  Duration? getTimeUntilPrayer(PrayerType type) {
    final currentState = state.value;
    if (currentState?.schedule == null) return null;
    
    final prayerTime = currentState!.schedule!.getTimeForPrayer(type);
    final now = DateTime.now();
    
    if (prayerTime.isAfter(now)) {
      return prayerTime.difference(now);
    }
    return null;
  }
}

/// Provider for getting just the next prayer type
@riverpod
Future<PrayerType?> nextPrayer(Ref ref) async {
  final scheduleState = await ref.watch(prayerScheduleProvider.future);
  return scheduleState.nextPrayer;
}

/// Provider for getting the prayer schedule for today
@riverpod
Future<PrayerSchedule?> todayPrayerSchedule(Ref ref) async {
  final scheduleState = await ref.watch(prayerScheduleProvider.future);
  return scheduleState.schedule;
}
