import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_score.dart';
import '../models/enums/prayer_type.dart';
import '../services/prayer_score_service.dart';
import 'prayer_settings_provider.dart';

part 'prayer_score_provider.g.dart';

/// State class for prayer scores and statistics
class PrayerScoreState {
  final Map<PrayerType, PrayerScore> scores;
  final double overallScore;
  final bool isEnabled;

  const PrayerScoreState({
    this.scores = const {},
    this.overallScore = 0.0,
    this.isEnabled = false,
  });

  PrayerScoreState copyWith({
    Map<PrayerType, PrayerScore>? scores,
    double? overallScore,
    bool? isEnabled,
  }) {
    return PrayerScoreState(
      scores: scores ?? this.scores,
      overallScore: overallScore ?? this.overallScore,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Get the score for a specific prayer type
  PrayerScore? getScore(PrayerType type) => scores[type];

  /// Get the overall score as a percentage (0-100)
  int get overallPercentage => (overallScore * 100).round();

  /// Get the total current streak across all prayers
  int get totalCurrentStreak {
    if (scores.isEmpty) return 0;
    return scores.values.fold(0, (sum, score) => sum + score.currentStreak);
  }

  /// Get the average current streak
  double get averageCurrentStreak {
    if (scores.isEmpty) return 0.0;
    return totalCurrentStreak / scores.length;
  }

  /// Get the average Jamaah rate across all prayers
  double get averageJamaahRate {
    if (scores.isEmpty) return 0.0;
    final totalRate = scores.values.fold(0.0, (sum, score) => sum + score.jamaahRate);
    return totalRate / scores.length;
  }

  /// Get the average Jamaah rate as a percentage (0-100)
  int get averageJamaahPercentage => (averageJamaahRate * 100).round();
}

/// Provider for managing prayer scores and statistics display.
///
/// **Validates: Requirements 4.2, 4.3, 6.6**
@riverpod
class PrayerScoreNotifier extends _$PrayerScoreNotifier {
  late final PrayerScoreService _scoreService;
  
  bool _isMounted = true;

  @override
  Future<PrayerScoreState> build() async {
    _scoreService = PrayerScoreService();
    _isMounted = true;
    
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'PrayerScoreProvider',
        'dispose',
        'Provider disposed',
      );
    });
    
    try {
      // Check if prayer system is enabled
      final settings = await ref.watch(prayerSettingsProvider.future);
      if (!settings.isEnabled) {
        return const PrayerScoreState(isEnabled: false);
      }

      // Get all cached scores
      final scores = await _scoreService.getAllScores();

      // Calculate overall score
      final overallScore = await _scoreService.getOverallScore();

      CoreLoggingUtility.info(
        'PrayerScoreProvider',
        'build',
        'Loaded prayer scores: overall=${(overallScore * 100).round()}%',
      );

      return PrayerScoreState(
        scores: scores,
        overallScore: overallScore,
        isEnabled: true,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerScoreProvider',
        'build',
        'Failed to load prayer scores: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Recalculate the score for a specific prayer type.
  Future<void> recalculateScore(PrayerType prayerType) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'PrayerScoreProvider',
        'recalculateScore',
        'Recalculating score for ${prayerType.englishName}',
      );

      await _scoreService.recalculateScore(prayerType);

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerScoreProvider',
        'recalculateScore',
        'Failed to recalculate score: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Recalculate all prayer scores.
  Future<void> recalculateAllScores() async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'PrayerScoreProvider',
        'recalculateAllScores',
        'Recalculating all prayer scores',
      );

      await _scoreService.recalculateAllScores();

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerScoreProvider',
        'recalculateAllScores',
        'Failed to recalculate all scores: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Refresh the prayer score state.
  Future<void> refresh() async {
    if (!_isMounted) return;
    ref.invalidateSelf();
  }
}

/// Provider for getting the overall prayer score.
///
/// **Validates: Requirements 4.2, 4.3**
@riverpod
Future<double> overallPrayerScore(Ref ref) async {
  final scoreState = await ref.watch(prayerScoreProvider.future);
  return scoreState.overallScore;
}

/// Provider for getting the score of a specific prayer type.
@riverpod
Future<PrayerScore?> prayerTypeScore(Ref ref, PrayerType type) async {
  final scoreState = await ref.watch(prayerScoreProvider.future);
  return scoreState.getScore(type);
}

/// Provider for getting the overall score as a percentage.
@riverpod
Future<int> overallPrayerScorePercentage(Ref ref) async {
  final scoreState = await ref.watch(prayerScoreProvider.future);
  return scoreState.overallPercentage;
}

/// Provider for getting the average Jamaah rate.
@riverpod
Future<double> averageJamaahRate(Ref ref) async {
  final scoreState = await ref.watch(prayerScoreProvider.future);
  return scoreState.averageJamaahRate;
}
