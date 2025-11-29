import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../../core/widgets/shell/numu_app_bar.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/prayer_status.dart';
import '../models/enums/nafila_type.dart';
import '../models/nafila_event.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_schedule_provider.dart';
import '../providers/prayer_score_provider.dart';
import '../providers/nafila_provider.dart';
import '../services/nafila_time_service.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_progress_header.dart';
import '../widgets/prayer_log_dialog.dart';
import '../widgets/prayer_edit_dialog.dart';
import '../widgets/next_prayer_countdown.dart';
import '../widgets/prayer_score_display.dart';
import '../widgets/nafila_indicator_card.dart';
import '../widgets/nafila_log_dialog.dart';
import '../widgets/nafila_edit_dialog.dart';

/// Main screen displaying all five prayers with status, progress header, and statistics.
/// Handles prayer logging via dialog.
///
/// **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6**
class IslamicPrayerScreen extends ConsumerStatefulWidget {
  const IslamicPrayerScreen({super.key});

  @override
  ConsumerState<IslamicPrayerScreen> createState() => _IslamicPrayerScreenState();
}

class _IslamicPrayerScreenState extends ConsumerState<IslamicPrayerScreen> {
  bool _showStatistics = false;

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('IslamicPrayerScreen', 'build', 'Building prayer screen');
    
    final prayerAsync = ref.watch(prayerProvider);
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final scoreAsync = ref.watch(prayerScoreProvider);
    final nafilaAsync = ref.watch(nafilaProvider);

    return Column(
      children: [
        NumuAppBar(
          title: 'Prayers',
          actions: [
            // Add custom Nafila button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add custom Nafila',
              onPressed: () => _showNafilaLogDialog(
                NafilaType.custom,
                null,
                null,
              ),
            ),
            // Statistics screen navigation button
            // **Validates: Requirements 8.1, 8.2**
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Prayer statistics',
              onPressed: () => context.push('/prayers/statistics'),
            ),
            // Toggle inline statistics view
            IconButton(
              icon: Icon(_showStatistics ? Icons.list : Icons.analytics_outlined),
              tooltip: _showStatistics ? 'Show prayers' : 'Show quick stats',
              onPressed: () {
                setState(() {
                  _showStatistics = !_showStatistics;
                });
              },
            ),
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Prayer settings',
              onPressed: () => context.push('/prayers/settings'),
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: prayerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildErrorState(context, error),
              data: (prayerState) {
                if (!prayerState.isEnabled) {
                  return _buildDisabledState(context);
                }

                return scheduleAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _buildErrorState(context, error),
                  data: (scheduleState) {
                    // Get Nafila state (default to empty if loading/error)
                    final nafilaState = nafilaAsync.when(
                      data: (state) => state,
                      loading: () => const NafilaState(),
                      error: (_, __) => const NafilaState(),
                    );
                    
                    return scoreAsync.when(
                      loading: () => _buildPrayerContent(
                        context,
                        prayerState,
                        scheduleState,
                        null,
                        nafilaState,
                      ),
                      error: (_, __) => _buildPrayerContent(
                        context,
                        prayerState,
                        scheduleState,
                        null,
                        nafilaState,
                      ),
                      data: (scoreState) => _buildPrayerContent(
                        context,
                        prayerState,
                        scheduleState,
                        scoreState,
                        nafilaState,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPrayerContent(
    BuildContext context,
    PrayerState prayerState,
    PrayerScheduleState scheduleState,
    PrayerScoreState? scoreState,
    NafilaState nafilaState,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress header
          PrayerProgressHeader(
            completedCount: prayerState.completedCount,
            scorePercentage: scoreState?.overallPercentage ?? 0,
          ),
          const SizedBox(height: 16),

          // Next prayer countdown
          NextPrayerCountdown(
            nextPrayer: scheduleState.nextPrayer,
            nextPrayerTime: scheduleState.nextPrayer != null && scheduleState.schedule != null
                ? scheduleState.schedule!.getTimeForPrayer(scheduleState.nextPrayer!)
                : null,
          ),
          const SizedBox(height: 16),

          // Compact stats summary for honest self-improvement
          if (scoreState != null && !_showStatistics)
            _buildCompactStatsSummary(context, scoreState),
          const SizedBox(height: 16),

          // Show either prayer list or statistics
          if (_showStatistics && scoreState != null)
            _buildStatisticsView(scoreState)
          else
            _buildPrayerList(context, prayerState, scheduleState, nafilaState),

          // Offline mode indicator
          if (scheduleState.isOfflineMode) ...[
            const SizedBox(height: 16),
            _buildOfflineIndicator(context),
          ],

          // Error message if any
          if (scheduleState.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildWarningMessage(context, scheduleState.errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerList(
    BuildContext context,
    PrayerState prayerState,
    PrayerScheduleState scheduleState,
    NafilaState nafilaState,
  ) {
    final theme = Theme.of(context);
    final timeService = NafilaTimeService();

    // Get custom Nafila events sorted by timestamp for chronological display
    final customNafilaEvents = List<NafilaEvent>.from(nafilaState.customNafilaEvents)
      ..sort((a, b) => a.eventTimestamp.compareTo(b.eventTimestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Prayers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Build prayer list with Nafila indicators interspersed
        ..._buildPrayerListWithNafila(
          context,
          prayerState,
          scheduleState,
          nafilaState,
          timeService,
          customNafilaEvents,
        ),
      ],
    );
  }

  /// Build the prayer list with Nafila indicators positioned between appropriate prayers.
  ///
  /// **Validates: Requirements 1.1, 3.1, 3.3**
  List<Widget> _buildPrayerListWithNafila(
    BuildContext context,
    PrayerState prayerState,
    PrayerScheduleState scheduleState,
    NafilaState nafilaState,
    NafilaTimeService timeService,
    List<NafilaEvent> customNafilaEvents,
  ) {
    final widgets = <Widget>[];
    final schedule = scheduleState.schedule;

    for (final prayerType in PrayerType.values) {
      final status = prayerState.statuses[prayerType] ?? PrayerStatus.pending;
      final prayerTime = schedule?.getTimeForPrayer(prayerType);
      final event = prayerState.todayEvents
          .where((e) => e.prayerType == prayerType)
          .firstOrNull;

      // Add Sunnah Fajr indicator AFTER Fajr card (between Fajr and sunrise)
      if (prayerType == PrayerType.fajr) {
        // First add the Fajr prayer card
        widgets.add(PrayerCard(
          prayerType: prayerType,
          prayerTime: prayerTime,
          status: status,
          onTap: !status.isCompleted
              ? () => _showLogDialog(prayerType, prayerTime)
              : null,
          onEditTap: status.isCompleted && event != null
              ? () => _showEditDialog(prayerType, event, prayerTime)
              : null,
        ));

        // Then add Sunnah Fajr indicator
        widgets.add(_buildNafilaIndicator(
          NafilaType.sunnahFajr,
          nafilaState,
          schedule != null ? timeService.getSunnahFajrWindow(schedule) : null,
        ));

        // Add any custom Nafila events that fall in the Sunnah Fajr window
        if (schedule != null) {
          final (fajrStart, fajrEnd) = timeService.getSunnahFajrWindow(schedule);
          widgets.addAll(_buildCustomNafilaInWindow(
            customNafilaEvents,
            fajrStart,
            fajrEnd,
          ));
        }

        continue; // Skip the default card addition below
      }

      // Add Duha indicator BEFORE Dhuhr card (between sunrise and Dhuhr)
      if (prayerType == PrayerType.dhuhr) {
        // Add Duha indicator before Dhuhr
        widgets.add(_buildNafilaIndicator(
          NafilaType.duha,
          nafilaState,
          schedule != null ? timeService.getDuhaWindow(schedule) : null,
        ));

        // Add any custom Nafila events that fall in the Duha window
        if (schedule != null) {
          final (duhaStart, duhaEnd) = timeService.getDuhaWindow(schedule);
          widgets.addAll(_buildCustomNafilaInWindow(
            customNafilaEvents,
            duhaStart,
            duhaEnd,
          ));
        }
      }

      // Add the prayer card
      widgets.add(PrayerCard(
        prayerType: prayerType,
        prayerTime: prayerTime,
        status: status,
        onTap: !status.isCompleted
            ? () => _showLogDialog(prayerType, prayerTime)
            : null,
        onEditTap: status.isCompleted && event != null
            ? () => _showEditDialog(prayerType, event, prayerTime)
            : null,
      ));

      // Add Shaf'i/Witr indicator AFTER Isha card
      if (prayerType == PrayerType.isha) {
        widgets.add(_buildNafilaIndicator(
          NafilaType.shafiWitr,
          nafilaState,
          schedule != null ? timeService.getShafiWitrWindow(schedule, null) : null,
        ));

        // Add any custom Nafila events that fall in the Shaf'i/Witr window
        if (schedule != null) {
          final (witrStart, witrEnd) = timeService.getShafiWitrWindow(schedule, null);
          widgets.addAll(_buildCustomNafilaInWindow(
            customNafilaEvents,
            witrStart,
            witrEnd,
          ));
        }
      }
    }

    return widgets;
  }

  /// Build a Nafila indicator card for a defined Sunnah prayer type.
  Widget _buildNafilaIndicator(
    NafilaType type,
    NafilaState nafilaState,
    (DateTime, DateTime)? timeWindow,
  ) {
    final isCompleted = nafilaState.isCompleted(type);
    final rakats = nafilaState.getRakatsForType(type);
    final events = nafilaState.getEventsForType(type);
    final existingEvent = events.isNotEmpty ? events.first : null;

    return NafilaIndicatorCard(
      type: type,
      isCompleted: isCompleted,
      rakatCount: isCompleted ? rakats : null,
      onTap: () => _showNafilaLogDialog(
        type,
        timeWindow?.$1,
        timeWindow?.$2,
      ),
      onEditTap: isCompleted && existingEvent != null
          ? () => _showNafilaEditDialog(
              existingEvent,
              timeWindow?.$1,
              timeWindow?.$2,
            )
          : null,
    );
  }

  /// Build custom Nafila cards for events that fall within a specific time window.
  List<Widget> _buildCustomNafilaInWindow(
    List<NafilaEvent> customEvents,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final widgets = <Widget>[];

    for (final event in customEvents) {
      final eventTime = event.actualPrayerTime ?? event.eventTimestamp;
      
      // Only show custom events in their appropriate time slot
      if (_isTimeInWindow(eventTime, windowStart, windowEnd)) {
        widgets.add(_buildCustomNafilaCard(event));
      }
    }

    return widgets;
  }

  /// Check if a time falls within a window (handles midnight crossing).
  bool _isTimeInWindow(DateTime time, DateTime start, DateTime end) {
    // Handle window crossing midnight
    if (end.isBefore(start)) {
      return !time.isBefore(start) || time.isBefore(end);
    }
    return !time.isBefore(start) && time.isBefore(end);
  }

  /// Build a card for a custom Nafila event.
  Widget _buildCustomNafilaCard(NafilaEvent event) {
    return NafilaIndicatorCard(
      type: NafilaType.custom,
      isCompleted: true,
      rakatCount: event.rakatCount,
      onTap: null,
      onEditTap: () => _showNafilaEditDialog(event, null, null),
    );
  }

  /// Compact stats summary for the prayer screen
  /// Shows quick stats for honest self-improvement tracking
  Widget _buildCompactStatsSummary(BuildContext context, PrayerScoreState scoreState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                Icons.trending_up,
                '${scoreState.overallPercentage}%',
                'Score',
              ),
              _buildStatItem(
                context,
                Icons.local_fire_department,
                scoreState.averageCurrentStreak.toStringAsFixed(1),
                'Avg Streak',
              ),
              _buildStatItem(
                context,
                Icons.groups,
                '${scoreState.averageJamaahPercentage}%',
                'Jamaah',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track honestly — this is for your improvement, not to impress',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Single stat item widget
  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsView(PrayerScoreState scoreState) {
    return PrayerScoreDisplay(
      scores: scoreState.scores,
      overallScore: scoreState.overallScore,
      averageJamaahRate: scoreState.averageJamaahRate,
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode - using cached prayer times',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mosque_outlined,
              size: 80,
              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Islamic Prayer System Disabled',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enable the Islamic Prayer System in settings to start tracking your daily prayers.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/prayers/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load prayers',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    CoreLoggingUtility.info('IslamicPrayerScreen', '_refreshData', 'Refreshing prayer data');
    ref.invalidate(prayerProvider);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(prayerScoreProvider);
  }

  void _showLogDialog(PrayerType prayerType, DateTime? scheduledTime) {
    CoreLoggingUtility.info(
      'IslamicPrayerScreen',
      '_showLogDialog',
      'Opening log dialog for ${prayerType.englishName}',
    );

    showDialog(
      context: context,
      builder: (context) => PrayerLogDialog(
        prayerType: prayerType,
        scheduledTime: scheduledTime,
      ),
    );
  }

  void _showEditDialog(PrayerType prayerType, dynamic existingEvent, DateTime? scheduledTime) {
    CoreLoggingUtility.info(
      'IslamicPrayerScreen',
      '_showEditDialog',
      'Opening edit dialog for ${prayerType.englishName}',
    );

    showDialog(
      context: context,
      builder: (context) => PrayerEditDialog(
        prayerType: prayerType,
        existingEvent: existingEvent,
        scheduledTime: scheduledTime,
      ),
    );
  }

  /// Show dialog for logging a Nafila prayer.
  ///
  /// **Validates: Requirements 1.2, 2.1**
  void _showNafilaLogDialog(
    NafilaType nafilaType,
    DateTime? windowStart,
    DateTime? windowEnd,
  ) {
    CoreLoggingUtility.info(
      'IslamicPrayerScreen',
      '_showNafilaLogDialog',
      'Opening Nafila log dialog for ${nafilaType.englishName}',
    );

    showDialog(
      context: context,
      builder: (context) => NafilaLogDialog(
        type: nafilaType,
        scheduledWindowStart: windowStart,
        scheduledWindowEnd: windowEnd,
      ),
    );
  }

  /// Show dialog for editing an existing Nafila event.
  ///
  /// **Validates: Requirements 2.2**
  void _showNafilaEditDialog(
    NafilaEvent existingEvent,
    DateTime? windowStart,
    DateTime? windowEnd,
  ) {
    CoreLoggingUtility.info(
      'IslamicPrayerScreen',
      '_showNafilaEditDialog',
      'Opening Nafila edit dialog for ${existingEvent.nafilaType.englishName}',
    );

    showDialog(
      context: context,
      builder: (context) => NafilaEditDialog(
        existingEvent: existingEvent,
        scheduledWindowStart: windowStart,
        scheduledWindowEnd: windowEnd,
      ),
    );
  }
}
