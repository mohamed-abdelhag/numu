import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/nafila_event.dart';
import '../models/enums/nafila_type.dart';
import '../repositories/nafila_repository.dart';
import '../services/nafila_time_service.dart';
import '../services/nafila_score_service.dart';
import 'prayer_settings_provider.dart';
import 'prayer_schedule_provider.dart';

part 'nafila_provider.g.dart';

/// State class for today's Nafila prayer status and events.
///
/// **Validates: Requirements 1.2, 2.1, 2.2**
class NafilaState {
  final List<NafilaEvent> todayEvents;
  final Map<NafilaType, bool> definedNafilaCompleted;
  final bool isLoading;
  final String? errorMessage;

  const NafilaState({
    this.todayEvents = const [],
    this.definedNafilaCompleted = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  NafilaState copyWith({
    List<NafilaEvent>? todayEvents,
    Map<NafilaType, bool>? definedNafilaCompleted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NafilaState(
      todayEvents: todayEvents ?? this.todayEvents,
      definedNafilaCompleted: definedNafilaCompleted ?? this.definedNafilaCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Check if a specific Nafila type is completed today.
  bool isCompleted(NafilaType type) => definedNafilaCompleted[type] ?? false;

  /// Get events for a specific Nafila type.
  List<NafilaEvent> getEventsForType(NafilaType type) {
    return todayEvents.where((e) => e.nafilaType == type).toList();
  }

  /// Get total rakats for a specific Nafila type today.
  int getRakatsForType(NafilaType type) {
    return getEventsForType(type).fold(0, (sum, e) => sum + e.rakatCount);
  }

  /// Get all custom Nafila events for today.
  List<NafilaEvent> get customNafilaEvents {
    return todayEvents.where((e) => e.nafilaType == NafilaType.custom).toList();
  }
}

/// Provider for managing Nafila prayer events and status for today.
///
/// **Validates: Requirements 1.2, 2.1, 2.2**
@riverpod
class NafilaNotifier extends _$NafilaNotifier {
  NafilaRepository? _repository;
  NafilaTimeService? _timeService;
  NafilaScoreService? _scoreService;
  
  bool _isMounted = true;

  @override
  Future<NafilaState> build() async {
    _repository = NafilaRepository();
    _timeService = NafilaTimeService();
    _scoreService = NafilaScoreService();
    _isMounted = true;
    
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'NafilaProvider',
        'dispose',
        'Provider disposed',
      );
    });
    
    try {
      // Check if prayer system is enabled
      final settings = await ref.watch(prayerSettingsProvider.future);
      if (!settings.isEnabled) {
        return const NafilaState();
      }

      // Get today's Nafila events
      final today = DateTime.now();
      final events = await _getRepository().getEventsForDate(today);

      // Calculate completion status for defined Nafila types
      final definedNafilaCompleted = _calculateCompletionStatus(events);

      CoreLoggingUtility.info(
        'NafilaProvider',
        'build',
        'Loaded ${events.length} Nafila events for today',
      );

      return NafilaState(
        todayEvents: events,
        definedNafilaCompleted: definedNafilaCompleted,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaProvider',
        'build',
        'Failed to load Nafila state: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Get repository, ensuring it's initialized.
  NafilaRepository _getRepository() {
    _repository ??= NafilaRepository();
    return _repository!;
  }
  
  /// Get time service, ensuring it's initialized.
  NafilaTimeService _getTimeService() {
    _timeService ??= NafilaTimeService();
    return _timeService!;
  }
  
  /// Get score service, ensuring it's initialized.
  NafilaScoreService _getScoreService() {
    _scoreService ??= NafilaScoreService();
    return _scoreService!;
  }

  /// Calculate completion status for defined Nafila types.
  Map<NafilaType, bool> _calculateCompletionStatus(List<NafilaEvent> events) {
    final completionStatus = <NafilaType, bool>{};
    
    for (final type in NafilaType.values) {
      if (type.isDefined) {
        completionStatus[type] = events.any((e) => e.nafilaType == type);
      }
    }
    
    return completionStatus;
  }

  /// Log a Nafila prayer with time validation.
  ///
  /// **Validates: Requirements 1.2, 2.1, 2.2**
  Future<void> logNafila({
    required NafilaType type,
    required int rakats,
    DateTime? actualTime,
    String? notes,
  }) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'NafilaProvider',
        'logNafila',
        'Logging ${type.englishName} with $rakats rakats',
      );

      final now = DateTime.now();
      final prayerTime = actualTime ?? now;

      // Validate rakat count
      if (rakats < type.minRakats || rakats > type.maxRakats) {
        throw ArgumentError(
          'Rakat count must be between ${type.minRakats} and ${type.maxRakats} for ${type.englishName}',
        );
      }

      // Validate time for defined Nafila types
      if (type.isDefined) {
        final scheduleState = await ref.read(prayerScheduleProvider.future);
        final schedule = scheduleState.schedule;
        
        if (schedule != null) {
          bool isValidTime = false;
          String? errorMessage;
          
          switch (type) {
            case NafilaType.sunnahFajr:
              isValidTime = _getTimeService().isValidTimeForSunnahFajr(prayerTime, schedule);
              if (!isValidTime) {
                final (start, end) = _getTimeService().getSunnahFajrWindow(schedule);
                errorMessage = 'Sunnah Fajr must be prayed between ${_formatTime(start)} and ${_formatTime(end)}';
              }
              break;
            case NafilaType.duha:
              isValidTime = _getTimeService().isValidTimeForDuha(prayerTime, schedule);
              if (!isValidTime) {
                final (start, end) = _getTimeService().getDuhaWindow(schedule);
                errorMessage = 'Duha must be prayed between ${_formatTime(start)} and ${_formatTime(end)}';
              }
              break;
            case NafilaType.shafiWitr:
              // Validate Shaf'i/Witr time (next day schedule not available here)
              isValidTime = _getTimeService().isValidTimeForShafiWitr(prayerTime, schedule, null);
              if (!isValidTime) {
                final (start, end) = _getTimeService().getShafiWitrWindow(schedule, null);
                errorMessage = "Shaf'i/Witr must be prayed between ${_formatTime(start)} and ${_formatTime(end)}";
              }
              break;
            case NafilaType.custom:
              isValidTime = true; // Custom Nafila has no time restrictions
              break;
          }
          
          if (!isValidTime && errorMessage != null) {
            CoreLoggingUtility.warning(
              'NafilaProvider',
              'logNafila',
              'Time validation failed: $errorMessage',
            );
            throw ArgumentError(errorMessage);
          }
        }
      }

      if (!_isMounted) return;

      // Create the Nafila event
      final event = NafilaEvent(
        nafilaType: type,
        eventDate: now,
        eventTimestamp: now,
        rakatCount: rakats,
        actualPrayerTime: actualTime,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      // Save to repository
      await _getRepository().logNafilaEvent(event);
      if (!_isMounted) return;

      // Recalculate score for this Nafila type
      if (type.isDefined) {
        await _getScoreService().recalculateScore(type);
      }

      CoreLoggingUtility.info(
        'NafilaProvider',
        'logNafila',
        'Successfully logged ${type.englishName}',
      );

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaProvider',
        'logNafila',
        'Failed to log Nafila: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Update an existing Nafila event.
  ///
  /// **Validates: Requirements 2.2**
  Future<void> updateNafila(NafilaEvent event) async {
    if (!_isMounted) return;
    if (event.id == null) {
      throw ArgumentError('Cannot update Nafila event without an ID');
    }

    try {
      CoreLoggingUtility.info(
        'NafilaProvider',
        'updateNafila',
        'Updating Nafila event ID ${event.id}',
      );

      // Validate rakat count
      if (event.rakatCount < event.nafilaType.minRakats || 
          event.rakatCount > event.nafilaType.maxRakats) {
        throw ArgumentError(
          'Rakat count must be between ${event.nafilaType.minRakats} and ${event.nafilaType.maxRakats}',
        );
      }

      // Update in repository
      await _getRepository().updateNafilaEvent(event);
      if (!_isMounted) return;

      // Recalculate score for this Nafila type
      if (event.nafilaType.isDefined) {
        await _getScoreService().recalculateScore(event.nafilaType);
      }

      CoreLoggingUtility.info(
        'NafilaProvider',
        'updateNafila',
        'Successfully updated Nafila event',
      );

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaProvider',
        'updateNafila',
        'Failed to update Nafila: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Delete a Nafila event.
  Future<void> deleteNafila(int eventId) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'NafilaProvider',
        'deleteNafila',
        'Deleting Nafila event ID $eventId',
      );

      // Get the event first to know its type for score recalculation
      final currentState = state.value;
      NafilaType? eventType;
      if (currentState != null) {
        final event = currentState.todayEvents.firstWhere(
          (e) => e.id == eventId,
          orElse: () => throw ArgumentError('Event not found'),
        );
        eventType = event.nafilaType;
      }

      await _getRepository().deleteNafilaEvent(eventId);
      if (!_isMounted) return;

      // Recalculate score for this Nafila type
      if (eventType != null && eventType.isDefined) {
        await _getScoreService().recalculateScore(eventType);
      }

      CoreLoggingUtility.info(
        'NafilaProvider',
        'deleteNafila',
        'Successfully deleted Nafila event',
      );

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaProvider',
        'deleteNafila',
        'Failed to delete Nafila: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Refresh the Nafila state.
  Future<void> refresh() async {
    if (!_isMounted) return;
    ref.invalidateSelf();
  }

  /// Format time for display in error messages.
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Provider for checking if a specific Nafila type is completed today.
@riverpod
Future<bool> isNafilaCompleted(Ref ref, NafilaType type) async {
  final nafilaState = await ref.watch(nafilaProvider.future);
  return nafilaState.isCompleted(type);
}

/// Provider for getting today's events for a specific Nafila type.
@riverpod
Future<List<NafilaEvent>> nafilaEventsForType(Ref ref, NafilaType type) async {
  final nafilaState = await ref.watch(nafilaProvider.future);
  return nafilaState.getEventsForType(type);
}

/// Provider for getting total rakats for a specific Nafila type today.
@riverpod
Future<int> nafilaRakatsForType(Ref ref, NafilaType type) async {
  final nafilaState = await ref.watch(nafilaProvider.future);
  return nafilaState.getRakatsForType(type);
}
