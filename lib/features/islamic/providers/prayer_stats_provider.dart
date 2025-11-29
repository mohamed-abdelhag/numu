import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/prayer_day_stats.dart';
import '../models/prayer_score.dart';
import '../models/nafila_score.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/nafila_type.dart';
import '../repositories/prayer_repository.dart';
import '../repositories/nafila_repository.dart';
import 'prayer_settings_provider.dart';
import 'prayer_score_provider.dart';
import 'nafila_score_provider.dart';

part 'prayer_stats_provider.g.dart';

/// State class for prayer statistics including calendar view data.
///
/// **Validates: Requirements 4.1, 4.2, 4.3**
class PrayerStatsState {
  final List<PrayerDayStats> dailyStats;
  final Map<PrayerType, PrayerScore> obligatoryScores;
  final Map<NafilaType, NafilaScore> nafilaScores;
  final DateTime selectedMonth;
  final bool isEnabled;
  final bool isLoading;

  const PrayerStatsState({
    this.dailyStats = const [],
    this.obligatoryScores = const {},
    this.nafilaScores = const {},
    required this.selectedMonth,
    this.isEnabled = false,
    this.isLoading = false,
  });

  PrayerStatsState copyWith({
    List<PrayerDayStats>? dailyStats,
    Map<PrayerType, PrayerScore>? obligatoryScores,
    Map<NafilaType, NafilaScore>? nafilaScores,
    DateTime? selectedMonth,
    bool? isEnabled,
    bool? isLoading,
  }) {
    return PrayerStatsState(
      dailyStats: dailyStats ?? this.dailyStats,
      obligatoryScores: obligatoryScores ?? this.obligatoryScores,
      nafilaScores: nafilaScores ?? this.nafilaScores,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get stats for a specific date.
  PrayerDayStats? getStatsForDate(DateTime date) {
    try {
      return dailyStats.firstWhere(
        (stats) =>
            stats.date.year == date.year &&
            stats.date.month == date.month &&
            stats.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get overall obligatory prayer completion rate for the month.
  double get obligatoryCompletionRate {
    if (dailyStats.isEmpty) return 0.0;
    final totalCompleted = dailyStats.fold(
      0,
      (sum, stats) => sum + stats.obligatoryCompletedCount,
    );
    final totalPossible = dailyStats.length * PrayerType.values.length;
    return totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
  }

  /// Get overall Nafila completion rate for the month.
  double get nafilaCompletionRate {
    if (dailyStats.isEmpty) return 0.0;
    final totalCompleted = dailyStats.fold(
      0,
      (sum, stats) => sum + stats.definedNafilaCompletedCount,
    );
    final definedNafilaCount = NafilaType.values.where((t) => t.isDefined).length;
    final totalPossible = dailyStats.length * definedNafilaCount;
    return totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
  }

  /// Get total Nafila rakats for the month.
  int get totalNafilaRakatsForMonth {
    return dailyStats.fold(0, (sum, stats) => sum + stats.totalRakatsNafila);
  }
}

/// Provider for managing prayer statistics and calendar view data.
///
/// **Validates: Requirements 4.1, 4.2, 4.3**
@riverpod
class PrayerStatsNotifier extends _$PrayerStatsNotifier {
  PrayerRepository? _prayerRepository;
  NafilaRepository? _nafilaRepository;
  
  bool _isMounted = true;

  @override
  Future<PrayerStatsState> build() async {
    _prayerRepository = PrayerRepository();
    _nafilaRepository = NafilaRepository();
    _isMounted = true;
    
    ref.onDispose(() {
      _isMounted = false;
      CoreLoggingUtility.info(
        'PrayerStatsProvider',
        'dispose',
        'Provider disposed',
      );
    });
    
    try {
      // Check if prayer system is enabled
      final settings = await ref.watch(prayerSettingsProvider.future);
      if (!settings.isEnabled) {
        return PrayerStatsState(
          selectedMonth: DateTime.now(),
          isEnabled: false,
        );
      }

      // Load current month stats
      final now = DateTime.now();
      final selectedMonth = DateTime(now.year, now.month, 1);
      
      final dailyStats = await _loadStatsForMonth(selectedMonth);

      // Get cached scores
      final prayerScoreState = await ref.watch(prayerScoreProvider.future);
      final nafilaScoreState = await ref.watch(nafilaScoreProvider.future);

      CoreLoggingUtility.info(
        'PrayerStatsProvider',
        'build',
        'Loaded stats for ${dailyStats.length} days in ${selectedMonth.month}/${selectedMonth.year}',
      );

      return PrayerStatsState(
        dailyStats: dailyStats,
        obligatoryScores: prayerScoreState.scores,
        nafilaScores: nafilaScoreState.scores,
        selectedMonth: selectedMonth,
        isEnabled: true,
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerStatsProvider',
        'build',
        'Failed to load prayer stats: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Get prayer repository, ensuring it's initialized.
  PrayerRepository _getPrayerRepository() {
    _prayerRepository ??= PrayerRepository();
    return _prayerRepository!;
  }

  /// Get Nafila repository, ensuring it's initialized.
  NafilaRepository _getNafilaRepository() {
    _nafilaRepository ??= NafilaRepository();
    return _nafilaRepository!;
  }

  /// Load stats for a specific month.
  ///
  /// **Validates: Requirements 4.1, 4.2**
  Future<void> loadStatsForMonth(DateTime month) async {
    if (!_isMounted) return;

    try {
      CoreLoggingUtility.info(
        'PrayerStatsProvider',
        'loadStatsForMonth',
        'Loading stats for ${month.month}/${month.year}',
      );

      final selectedMonth = DateTime(month.year, month.month, 1);
      final dailyStats = await _loadStatsForMonth(selectedMonth);

      if (!_isMounted) return;

      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          dailyStats: dailyStats,
          selectedMonth: selectedMonth,
        ));
      }

      CoreLoggingUtility.info(
        'PrayerStatsProvider',
        'loadStatsForMonth',
        'Loaded stats for ${dailyStats.length} days',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerStatsProvider',
        'loadStatsForMonth',
        'Failed to load stats for month: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Internal method to load stats for a month.
  Future<List<PrayerDayStats>> _loadStatsForMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0); // Last day of month
    
    // Get all prayer events for the month
    final prayerEvents = <DateTime, Map<PrayerType, bool>>{};
    for (final prayerType in PrayerType.values) {
      final events = await _getPrayerRepository().getEventsForPrayer(
        prayerType,
        startDate: startDate,
        endDate: endDate,
      );
      
      for (final event in events) {
        final dateKey = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
        );
        prayerEvents.putIfAbsent(dateKey, () => {});
        prayerEvents[dateKey]![prayerType] = true;
      }
    }

    // Get all Nafila events for the month
    final nafilaEvents = await _getNafilaRepository().getEventsInRange(
      startDate,
      endDate,
    );

    // Group Nafila events by date
    final nafilaByDate = <DateTime, Map<NafilaType, bool>>{};
    final nafilaRakatsByDate = <DateTime, int>{};
    
    for (final event in nafilaEvents) {
      final dateKey = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      nafilaByDate.putIfAbsent(dateKey, () => {});
      nafilaByDate[dateKey]![event.nafilaType] = true;
      nafilaRakatsByDate[dateKey] = (nafilaRakatsByDate[dateKey] ?? 0) + event.rakatCount;
    }

    // Build daily stats for each day in the month
    final dailyStats = <PrayerDayStats>[];
    final today = DateTime.now();
    
    for (var day = startDate;
        !day.isAfter(endDate) && !day.isAfter(today);
        day = day.add(const Duration(days: 1))) {
      final dateKey = DateTime(day.year, day.month, day.day);
      
      // Build obligatory completion map
      final obligatoryCompleted = <PrayerType, bool>{};
      for (final type in PrayerType.values) {
        obligatoryCompleted[type] = prayerEvents[dateKey]?[type] ?? false;
      }

      // Build Nafila completion map (only defined types)
      final nafilaCompleted = <NafilaType, bool>{};
      for (final type in NafilaType.values.where((t) => t.isDefined)) {
        nafilaCompleted[type] = nafilaByDate[dateKey]?[type] ?? false;
      }

      dailyStats.add(PrayerDayStats(
        date: dateKey,
        obligatoryCompleted: obligatoryCompleted,
        nafilaCompleted: nafilaCompleted,
        totalRakatsNafila: nafilaRakatsByDate[dateKey] ?? 0,
      ));
    }

    return dailyStats;
  }

  /// Refresh the prayer stats.
  Future<void> refresh() async {
    if (!_isMounted) return;
    ref.invalidateSelf();
  }
}

/// Provider for getting stats for a specific date.
@riverpod
Future<PrayerDayStats?> prayerDayStats(Ref ref, DateTime date) async {
  final statsState = await ref.watch(prayerStatsProvider.future);
  return statsState.getStatsForDate(date);
}

/// Provider for getting the obligatory completion rate for the selected month.
@riverpod
Future<double> obligatoryCompletionRate(Ref ref) async {
  final statsState = await ref.watch(prayerStatsProvider.future);
  return statsState.obligatoryCompletionRate;
}

/// Provider for getting the Nafila completion rate for the selected month.
@riverpod
Future<double> nafilaCompletionRate(Ref ref) async {
  final statsState = await ref.watch(prayerStatsProvider.future);
  return statsState.nafilaCompletionRate;
}
