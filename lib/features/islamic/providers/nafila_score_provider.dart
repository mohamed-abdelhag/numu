import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/nafila_score.dart';
import '../models/enums/nafila_type.dart';
import '../services/nafila_score_service.dart';
import 'prayer_settings_provider.dart';

part 'nafila_score_provider.g.dart';

/// State class for Nafila prayer scores and statistics.
///
/// **Validates: Requirements 4.4, 4.5**
class NafilaScoreState {
  final Map<NafilaType, NafilaScore> scores;
  final int overallPercentage;
  final int totalRakatsAllTime;
  final bool isEnabled;

  const NafilaScoreState({
    this.scores = const {},
    this.overallPercentage = 0,
    this.totalRakatsAllTime = 0,
    this.isEnabled = false,
  });

  NafilaScoreState copyWith({
    Map<NafilaType, NafilaScore>? scores,
    int? overallPercentage,
    int? totalRakatsAllTime,
    bool? isEnabled,
  }) {
    return NafilaScoreState(
      scores: scores ?? this.scores,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      totalRakatsAllTime: totalRakatsAllTime ?? this.totalRakatsAllTime,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Get the score for a specific Nafila type.
  NafilaScore? getScore(NafilaType type) => scores[type];

  /// Get the total current streak across all defined Nafila types.
  int get totalCurrentStreak {
    if (scores.isEmpty) return 0;
    return scores.values
        .where((s) => s.nafilaType.isDefined)
        .fold(0, (sum, score) => sum + score.currentStreak);
  }

  /// Get the average current streak across defined Nafila types.
  double get averageCurrentStreak {
    final definedScores = scores.values.where((s) => s.nafilaType.isDefined).toList();
    if (definedScores.isEmpty) return 0.0;
    return totalCurrentStreak / definedScores.length;
  }

  /// Get the total completions across all Nafila types.
  int get totalCompletions {
    return scores.values.fold(0, (sum, score) => sum + score.totalCompletions);
  }
}

/// Provider for managing Nafila prayer scores and statistics display.
///
/// **Validates: Requirements 4.4, 4.5**
@riverpod
class NafilaScoreNotifier extends _$NafilaScoreNotifier {
  late NafilaScoreService _scoreService;
  
  bool _isMounted = true;

  @override
  Future<NafilaScoreState> build() async {
    _scoreService = NafilaScoreService();
    _isMounted = true;
    
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'NafilaScoreProvider',
        'dispose',
        'Provider disposed',
      );
    });
    
    try {
      // Check if prayer system is enabled
      final settings = await ref.watch(prayerSettingsProvider.future);
      if (!settings.isEnabled) {
        return const NafilaScoreState(isEnabled: false);
      }

      // Get all cached scores
      final scores = await _scoreService.getAllScores();

      // Calculate overall percentage (average of defined Nafila scores)
      final overallPercentage = _calculateOverallPercentage(scores);

      // Calculate total rakats all time
      final totalRakatsAllTime = _calculateTotalRakats(scores);

      CoreLoggingUtility.info(
        'NafilaScoreProvider',
        'build',
        'Loaded Nafila scores: overall=$overallPercentage%, totalRakats=$totalRakatsAllTime',
      );

      return NafilaScoreState(
        scores: scores,
        overallPercentage: overallPercentage,
        totalRakatsAllTime: totalRakatsAllTime,
        isEnabled: true,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaScoreProvider',
        'build',
        'Failed to load Nafila scores: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Calculate overall percentage from scores.
  int _calculateOverallPercentage(Map<NafilaType, NafilaScore> scores) {
    final definedScores = scores.values.where((s) => s.nafilaType.isDefined).toList();
    if (definedScores.isEmpty) return 0;
    
    final totalScore = definedScores.fold(0.0, (sum, score) => sum + score.score);
    return ((totalScore / definedScores.length) * 100).round();
  }

  /// Calculate total rakats from all scores.
  int _calculateTotalRakats(Map<NafilaType, NafilaScore> scores) {
    return scores.values.fold(0, (sum, score) => sum + score.totalRakats);
  }

  /// Recalculate scores for all Nafila types.
  ///
  /// **Validates: Requirements 4.4, 4.5**
  Future<void> recalculateScores() async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'NafilaScoreProvider',
        'recalculateScores',
        'Recalculating all Nafila scores',
      );

      await _scoreService.recalculateAllScores();

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaScoreProvider',
        'recalculateScores',
        'Failed to recalculate scores: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Recalculate score for a specific Nafila type.
  Future<void> recalculateScore(NafilaType type) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'NafilaScoreProvider',
        'recalculateScore',
        'Recalculating score for ${type.englishName}',
      );

      await _scoreService.recalculateScore(type);

      // Refresh state
      if (_isMounted) {
        ref.invalidateSelf();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaScoreProvider',
        'recalculateScore',
        'Failed to recalculate score: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Refresh the Nafila score state.
  Future<void> refresh() async {
    if (!_isMounted) return;
    ref.invalidateSelf();
  }
}

/// Provider for getting the overall Nafila score percentage.
@riverpod
Future<int> overallNafilaScorePercentage(Ref ref) async {
  final scoreState = await ref.watch(nafilaScoreProvider.future);
  return scoreState.overallPercentage;
}

/// Provider for getting the score of a specific Nafila type.
@riverpod
Future<NafilaScore?> nafilaTypeScore(Ref ref, NafilaType type) async {
  final scoreState = await ref.watch(nafilaScoreProvider.future);
  return scoreState.getScore(type);
}

/// Provider for getting total rakats prayed all time.
@riverpod
Future<int> totalNafilaRakats(Ref ref) async {
  final scoreState = await ref.watch(nafilaScoreProvider.future);
  return scoreState.totalRakatsAllTime;
}
