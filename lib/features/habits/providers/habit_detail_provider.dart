import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_streak.dart';
import '../models/enums/streak_type.dart';
import '../repositories/habit_repository.dart';

part 'habit_detail_provider.g.dart';

/// State class to hold all habit detail data
class HabitDetailState {
  final Habit habit;
  final List<HabitEvent> events;
  final Map<StreakType, HabitStreak> streaks;

  const HabitDetailState({
    required this.habit,
    required this.events,
    required this.streaks,
  });

  HabitDetailState copyWith({
    Habit? habit,
    List<HabitEvent>? events,
    Map<StreakType, HabitStreak>? streaks,
  }) {
    return HabitDetailState(
      habit: habit ?? this.habit,
      events: events ?? this.events,
      streaks: streaks ?? this.streaks,
    );
  }
}

/// Provider for managing a single habit's detail view
/// Loads habit data, events, and streak information
@riverpod
class HabitDetailNotifier extends _$HabitDetailNotifier {
  late final HabitRepository _repository;

  @override
  Future<HabitDetailState> build(int habitId) async {
    _repository = HabitRepository();

    final habit = await _repository.getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit not found');
    }

    final events = await _repository.getEventsForHabit(habitId);
    final streaks = await _loadStreaks(habitId);

    return HabitDetailState(
      habit: habit,
      events: events,
      streaks: streaks,
    );
  }

  /// Load all streak types for the habit
  Future<Map<StreakType, HabitStreak>> _loadStreaks(int habitId) async {
    final streaks = <StreakType, HabitStreak>{};
    for (final type in StreakType.values) {
      final streak = await _repository.getStreakForHabit(habitId, type);
      if (streak != null) {
        streaks[type] = streak;
      }
    }
    return streaks;
  }

  /// Refresh the habit detail data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final habitId = state.value?.habit.id;
      if (habitId == null) throw Exception('No habit ID available');
      
      final habit = await _repository.getHabitById(habitId);
      if (habit == null) {
        throw Exception('Habit not found');
      }

      final events = await _repository.getEventsForHabit(habitId);
      final streaks = await _loadStreaks(habitId);

      return HabitDetailState(
        habit: habit,
        events: events,
        streaks: streaks,
      );
    });
  }
}
