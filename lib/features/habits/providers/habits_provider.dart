import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../repositories/habit_repository.dart';
import '../services/streak_calculation_service.dart';

part 'habits_provider.g.dart';

/// Provider for managing the list of active habits
/// Handles CRUD operations and event logging with automatic state refresh
@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  late final HabitRepository _repository;
  late final StreakCalculationService _streakService;

  @override
  Future<List<Habit>> build() async {
    _repository = HabitRepository();
    _streakService = StreakCalculationService(_repository);
    return await _repository.getActiveHabits();
  }

  /// Add a new habit and refresh the list
  Future<void> addHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createHabit(habit);
      return await _repository.getActiveHabits();
    });
  }

  /// Update an existing habit and refresh the list
  Future<void> updateHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateHabit(habit);
      return await _repository.getActiveHabits();
    });
  }

  /// Archive a habit and refresh the list
  Future<void> archiveHabit(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.archiveHabit(id);
      return await _repository.getActiveHabits();
    });
  }

  /// Log a habit event, recalculate streaks, and refresh the list
  Future<void> logEvent(HabitEvent event) async {
    // Log the event
    await _repository.logEvent(event);

    // Recalculate streaks for the habit
    await _streakService.recalculateStreaks(event.habitId);

    // Refresh the habit list
    state = await AsyncValue.guard(() async {
      return await _repository.getActiveHabits();
    });
  }
}
