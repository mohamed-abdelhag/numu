import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_event.dart';
import '../models/prayer_schedule.dart';
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
