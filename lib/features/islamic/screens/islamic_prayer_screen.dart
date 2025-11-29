import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../../core/widgets/shell/numu_app_bar.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/prayer_status.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_schedule_provider.dart';
import '../providers/prayer_score_provider.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_progress_header.dart';
import '../widgets/prayer_log_dialog.dart';
import '../widgets/prayer_edit_dialog.dart';
import '../widgets/next_prayer_countdown.dart';
import '../widgets/prayer_score_display.dart';

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

    return Column(
      children: [
        NumuAppBar(
          title: 'Prayers',
          actions: [
            // Toggle statistics view
            IconButton(
              icon: Icon(_showStatistics ? Icons.list : Icons.bar_chart),
              tooltip: _showStatistics ? 'Show prayers' : 'Show statistics',
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
                    return scoreAsync.when(
                      loading: () => _buildPrayerContent(
                        context,
                        prayerState,
                        scheduleState,
                        null,
                      ),
                      error: (_, __) => _buildPrayerContent(
                        context,
                        prayerState,
                        scheduleState,
                        null,
                      ),
                      data: (scoreState) => _buildPrayerContent(
                        context,
                        prayerState,
                        scheduleState,
                        scoreState,
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
            _buildPrayerList(context, prayerState, scheduleState),

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
  ) {
    final theme = Theme.of(context);

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
        ...PrayerType.values.map((type) {
          final status = prayerState.statuses[type] ?? PrayerStatus.pending;
          final prayerTime = scheduleState.schedule?.getTimeForPrayer(type);
          final event = prayerState.todayEvents
              .where((e) => e.prayerType == type)
              .firstOrNull;

          return PrayerCard(
            prayerType: type,
            prayerTime: prayerTime,
            status: status,
            onTap: !status.isCompleted
                ? () => _showLogDialog(type, prayerTime)
                : null,
            onEditTap: status.isCompleted && event != null
                ? () => _showEditDialog(type, event, prayerTime)
                : null,
          );
        }),
      ],
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
}
