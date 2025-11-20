import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../repositories/habit_repository.dart';
import '../services/streak_calculation_service.dart';
import '../services/period_progress_service.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../reminders/services/reminder_scheduler_service.dart';
import '../../profile/providers/user_profile_provider.dart';

part 'habits_provider.g.dart';

/// Provider for managing the list of active habits
/// Handles CRUD operations and event logging with automatic state refresh
@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  late final HabitRepository _repository;
  late final StreakCalculationService _streakService;
  late final PeriodProgressService _periodService;
  late final ReminderSchedulerService _reminderSchedulerService;
  
  /// Track if the notifier is still mounted/active
  bool _isMounted = true;

  @override
  Future<List<Habit>> build() async {
    _repository = HabitRepository();
    _streakService = StreakCalculationService(_repository);
    _periodService = PeriodProgressService(_repository);
    _reminderSchedulerService = ReminderSchedulerService();
    _isMounted = true;
    
    // Set up disposal callback to mark as unmounted
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'HabitsProvider',
        'dispose',
        'Provider disposed, marking as unmounted',
      );
    });
    
    try {
      return await _repository.getActiveHabits();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'build',
        'Failed to load active habits: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Add a new habit and refresh the list
  Future<void> addHabit(Habit habit) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'HabitsProvider',
        'addHabit',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      await _repository.createHabit(habit);
      CoreLoggingUtility.info(
        'HabitsProvider',
        'addHabit',
        'Successfully created habit: ${habit.name}',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'addHabit',
          'State update cancelled: provider disposed after habit creation',
        );
        return;
      }
      
      final habits = await _repository.getActiveHabits();
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'addHabit',
          'State update cancelled: provider disposed after fetching habits',
        );
        return;
      }
      
      state = AsyncValue.data(habits);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'addHabit',
        'Failed to create habit "${habit.name}": $e\n$stackTrace',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'addHabit',
          'Error state update cancelled: provider is disposed',
        );
        return;
      }
      
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update an existing habit and refresh the list
  /// Also notifies reminder scheduler to update linked reminders
  Future<void> updateHabit(Habit habit) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'HabitsProvider',
        'updateHabit',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      await _repository.updateHabit(habit);
      CoreLoggingUtility.info(
        'HabitsProvider',
        'updateHabit',
        'Successfully updated habit: ${habit.name} (ID: ${habit.id})',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'updateHabit',
          'State update cancelled: provider disposed after habit update',
        );
        return;
      }
      
      // Notify reminder scheduler to update linked reminders
      if (habit.id != null) {
        await _reminderSchedulerService.handleHabitUpdate(habit.id!);
        CoreLoggingUtility.info(
          'HabitsProvider',
          'updateHabit',
          'Successfully updated reminders for habit ID: ${habit.id}',
        );
      }
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'updateHabit',
          'State update cancelled: provider disposed after reminder update',
        );
        return;
      }
      
      final habits = await _repository.getActiveHabits();
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'updateHabit',
          'State update cancelled: provider disposed after fetching habits',
        );
        return;
      }
      
      state = AsyncValue.data(habits);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'updateHabit',
        'Failed to update habit "${habit.name}" (ID: ${habit.id}): $e\n$stackTrace',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'updateHabit',
          'Error state update cancelled: provider is disposed',
        );
        return;
      }
      
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Archive a habit and refresh the list
  Future<void> archiveHabit(int id) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'HabitsProvider',
        'archiveHabit',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      await _repository.archiveHabit(id);
      CoreLoggingUtility.info(
        'HabitsProvider',
        'archiveHabit',
        'Successfully archived habit with ID: $id',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'archiveHabit',
          'State update cancelled: provider disposed after archiving habit',
        );
        return;
      }
      
      final habits = await _repository.getActiveHabits();
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'archiveHabit',
          'State update cancelled: provider disposed after fetching habits',
        );
        return;
      }
      
      state = AsyncValue.data(habits);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'archiveHabit',
        'Failed to archive habit with ID $id: $e\n$stackTrace',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'archiveHabit',
          'Error state update cancelled: provider is disposed',
        );
        return;
      }
      
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Log a habit event, recalculate streaks and period progress, and refresh the list
  Future<void> logEvent(HabitEvent event) async {
    if (!_isMounted) {
      CoreLoggingUtility.info(
        'HabitsProvider',
        'logEvent',
        'Operation cancelled: provider is disposed',
      );
      return;
    }
    
    try {
      // Log the event
      await _repository.logEvent(event);
      CoreLoggingUtility.info(
        'HabitsProvider',
        'logEvent',
        'Successfully logged event for habit ID: ${event.habitId}',
      );

      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'logEvent',
          'Operation cancelled: provider disposed after logging event',
        );
        return;
      }

      // Recalculate streaks for the habit
      await _streakService.recalculateStreaks(event.habitId);

      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'logEvent',
          'Operation cancelled: provider disposed after recalculating streaks',
        );
        return;
      }

      // Get user's week start preference for period progress calculation
      final userProfile = await ref.read(userProfileProvider.future);
      final startOfWeek = userProfile?.startOfWeek ?? 1; // Default to Monday

      // Recalculate period progress for the habit with user's week start preference
      await _periodService.recalculatePeriodProgress(
        event.habitId,
        startOfWeek: startOfWeek,
      );

      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'logEvent',
          'State update cancelled: provider disposed after recalculating progress',
        );
        return;
      }

      // Refresh the habit list
      final habits = await _repository.getActiveHabits();
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'logEvent',
          'State update cancelled: provider disposed after fetching habits',
        );
        return;
      }
      
      state = AsyncValue.data(habits);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'logEvent',
        'Failed to log event for habit ID ${event.habitId}: $e\n$stackTrace',
      );
      
      if (!_isMounted) {
        CoreLoggingUtility.info(
          'HabitsProvider',
          'logEvent',
          'Error state update cancelled: provider is disposed',
        );
        return;
      }
      
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
