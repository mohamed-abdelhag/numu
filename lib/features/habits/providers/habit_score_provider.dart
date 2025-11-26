import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/habit_score.dart';
import '../services/habit_score_service.dart';
import '../repositories/habit_repository.dart';
import '../../../core/utils/core_logging_utility.dart';

part 'habit_score_provider.g.dart';

/// Provider for fetching and managing habit scores
/// Exposes score as AsyncValue with loading and error states
///
/// **Validates: Requirements 4.3**
@riverpod
class HabitScoreNotifier extends _$HabitScoreNotifier {
  late final HabitScoreService _scoreService;

  @override
  Future<HabitScore?> build(int habitId) async {
    _scoreService = HabitScoreService(repository: HabitRepository());

    try {
      CoreLoggingUtility.info(
        'HabitScoreProvider',
        'build',
        'Loading score for habit ID: $habitId',
      );

      // Get or calculate the score
      final score = await _scoreService.getOrCalculateScore(habitId);

      CoreLoggingUtility.info(
        'HabitScoreProvider',
        'build',
        'Successfully loaded score ${score.percentage}% for habit ID: $habitId',
      );

      return score;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitScoreProvider',
        'build',
        'Failed to load score for habit ID $habitId: $e\n$stackTrace',
      );
      // Return null on error rather than throwing to allow graceful degradation
      return null;
    }
  }

  /// Refresh the score by recalculating from scratch
  Future<void> refresh() async {
    final habitId = state.value?.habitId;
    if (habitId == null) {
      CoreLoggingUtility.warning(
        'HabitScoreProvider',
        'refresh',
        'Cannot refresh: no habit ID available',
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final score = await _scoreService.recalculateScore(habitId);
        CoreLoggingUtility.info(
          'HabitScoreProvider',
          'refresh',
          'Successfully refreshed score ${score.percentage}% for habit ID: $habitId',
        );
        return score;
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'HabitScoreProvider',
          'refresh',
          'Failed to refresh score for habit ID $habitId: $e\n$stackTrace',
        );
        return null;
      }
    });
  }
}
