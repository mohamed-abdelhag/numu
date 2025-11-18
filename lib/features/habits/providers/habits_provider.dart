import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../repositories/habit_repository.dart';
import '../services/streak_calculation_service.dart';
import '../services/period_progress_service.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'habits_provider.g.dart';

/// Provider for managing the list of active habits
/// Handles CRUD operations and event logging with automatic state refresh
@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  late final HabitRepository _repository;
  late final StreakCalculationService _streakService;
  late final PeriodProgressService _periodService;

  @override
  Future<List<Habit>> build() async {
    _repository = HabitRepository();
    _streakService = StreakCalculationService(_repository);
    _periodService = PeriodProgressService(_repository);
    
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.createHabit(habit);
        CoreLoggingUtility.info(
          'HabitsProvider',
          'addHabit',
          'Successfully created habit: ${habit.name}',
        );
        return await _repository.getActiveHabits();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'HabitsProvider',
          'addHabit',
          'Failed to create habit "${habit.name}": $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Update an existing habit and refresh the list
  Future<void> updateHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.updateHabit(habit);
        CoreLoggingUtility.info(
          'HabitsProvider',
          'updateHabit',
          'Successfully updated habit: ${habit.name} (ID: ${habit.id})',
        );
        return await _repository.getActiveHabits();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'HabitsProvider',
          'updateHabit',
          'Failed to update habit "${habit.name}" (ID: ${habit.id}): $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Archive a habit and refresh the list
  Future<void> archiveHabit(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repository.archiveHabit(id);
        CoreLoggingUtility.info(
          'HabitsProvider',
          'archiveHabit',
          'Successfully archived habit with ID: $id',
        );
        return await _repository.getActiveHabits();
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'HabitsProvider',
          'archiveHabit',
          'Failed to archive habit with ID $id: $e\n$stackTrace',
        );
        rethrow;
      }
    });
  }

  /// Log a habit event, recalculate streaks and period progress, and refresh the list
  Future<void> logEvent(HabitEvent event) async {
    try {
      // Log the event
      await _repository.logEvent(event);
      CoreLoggingUtility.info(
        'HabitsProvider',
        'logEvent',
        'Successfully logged event for habit ID: ${event.habitId}',
      );

      // Recalculate streaks for the habit
      await _streakService.recalculateStreaks(event.habitId);

      // Recalculate period progress for the habit
      await _periodService.recalculatePeriodProgress(event.habitId);

      // Refresh the habit list
      state = await AsyncValue.guard(() async {
        return await _repository.getActiveHabits();
      });
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'logEvent',
        'Failed to log event for habit ID ${event.habitId}: $e\n$stackTrace',
      );
      rethrow;
    }
  }
}
