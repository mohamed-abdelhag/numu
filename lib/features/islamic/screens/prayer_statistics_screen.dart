import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/shell/numu_app_bar.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/nafila_type.dart';
import '../models/prayer_score.dart';
import '../models/nafila_score.dart';
import '../models/prayer_day_stats.dart';
import '../providers/prayer_stats_provider.dart';
import '../widgets/prayer_calendar_view.dart';

/// Dedicated screen for comprehensive prayer statistics.
/// Displays calendar view and detailed statistics for all prayer types.
///
/// **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 8.2, 8.3**
class PrayerStatisticsScreen extends ConsumerStatefulWidget {
  const PrayerStatisticsScreen({super.key});

  @override
  ConsumerState<PrayerStatisticsScreen> createState() =>
      _PrayerStatisticsScreenState();
}

class _PrayerStatisticsScreenState extends ConsumerState<PrayerStatisticsScreen> {
  PrayerDayStats? _selectedDayStats;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(prayerStatsProvider);

    return Column(
      children: [
        const NumuAppBar(
          title: 'Prayer Statistics',
        ),
        Expanded(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(context, error),
            data: (statsState) {
              if (!statsState.isEnabled) {
                return _buildDisabledState(context);
              }
              return _buildContent(context, statsState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, PrayerStatsState statsState) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(prayerStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar view at top
            PrayerCalendarView(
              onDayTapped: (date) => _showDayDetails(context, statsState, date),
            ),
            const SizedBox(height: 24),

            // Selected day details (if any)
            if (_selectedDayStats != null) ...[
              _buildSelectedDayCard(context, _selectedDayStats!),
              const SizedBox(height: 24),
            ],

            // Monthly summary
            _buildMonthlySummary(context, statsState),
            const SizedBox(height: 24),

            // Obligatory prayer statistics
            _buildObligatoryStats(context, statsState),
            const SizedBox(height: 24),

            // Nafila prayer statistics
            _buildNafilaStats(context, statsState),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Show details for a selected day.
  void _showDayDetails(
    BuildContext context,
    PrayerStatsState statsState,
    DateTime date,
  ) {
    final dayStats = statsState.getStatsForDate(date);
    setState(() {
      _selectedDayStats = dayStats;
    });
  }

  /// Build card showing selected day details.
  Widget _buildSelectedDayCard(BuildContext context, PrayerDayStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = _formatDate(stats.date);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedDayStats = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Obligatory prayers
            Text(
              'Obligatory Prayers',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PrayerType.values.map((type) {
                final completed = stats.isObligatoryCompleted(type);
                return _buildPrayerChip(
                  context,
                  type.englishName,
                  completed,
                  colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Nafila prayers
            Text(
              'Nafila Prayers',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NafilaType.values
                  .where((t) => t.isDefined)
                  .map((type) {
                final completed = stats.isNafilaCompleted(type);
                return _buildPrayerChip(
                  context,
                  type.englishName,
                  completed,
                  Colors.green,
                );
              }).toList(),
            ),
            if (stats.totalRakatsNafila > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Total Nafila Rakats: ${stats.totalRakatsNafila}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a chip showing prayer completion status.
  Widget _buildPrayerChip(
    BuildContext context,
    String label,
    bool completed,
    Color activeColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: completed
            ? activeColor.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? activeColor
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: completed
                ? activeColor
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: completed
                      ? activeColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }


  /// Build monthly summary section.
  Widget _buildMonthlySummary(BuildContext context, PrayerStatsState statsState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final obligatoryRate = (statsState.obligatoryCompletionRate * 100).round();
    final nafilaRate = (statsState.nafilaCompletionRate * 100).round();
    final totalRakats = statsState.totalNafilaRakatsForMonth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.mosque,
                    '$obligatoryRate%',
                    'Obligatory',
                    colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.star,
                    '$nafilaRate%',
                    'Nafila',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.format_list_numbered,
                    '$totalRakats',
                    'Rakats',
                    Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single summary item.
  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build obligatory prayer statistics section.
  ///
  /// **Validates: Requirements 4.3, 4.4**
  Widget _buildObligatoryStats(BuildContext context, PrayerStatsState statsState) {
    final theme = Theme.of(context);
    final scores = statsState.obligatoryScores;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obligatory Prayers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (scores.isEmpty)
              Text(
                'No prayer data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...PrayerType.values.map((type) {
                final score = scores[type];
                return _buildPrayerStatRow(
                  context,
                  type.englishName,
                  type.arabicName,
                  score,
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Build a row showing prayer statistics.
  Widget _buildPrayerStatRow(
    BuildContext context,
    String englishName,
    String arabicName,
    PrayerScore? score,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  englishName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  arabicName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (score != null) ...[
            _buildStatBadge(context, '${score.percentage}%', 'Score'),
            const SizedBox(width: 8),
            _buildStatBadge(
              context,
              '${score.currentStreak}',
              'Streak',
              icon: Icons.local_fire_department,
            ),
          ] else
            Text(
              'No data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }


  /// Build Nafila prayer statistics section.
  ///
  /// **Validates: Requirements 4.4, 4.5, 4.6**
  Widget _buildNafilaStats(BuildContext context, PrayerStatsState statsState) {
    final theme = Theme.of(context);
    final scores = statsState.nafilaScores;

    // Count custom Nafila completions
    final customScore = scores[NafilaType.custom];
    final customCount = customScore?.totalCompletions ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nafila Prayers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (scores.isEmpty)
              Text(
                'No Nafila data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              // Defined Sunnah prayers
              ...NafilaType.values
                  .where((t) => t.isDefined)
                  .map((type) {
                final score = scores[type];
                return _buildNafilaStatRow(context, type, score);
              }),
              // Custom Nafila summary
              if (customCount > 0) ...[
                const Divider(height: 24),
                _buildCustomNafilaSummary(context, customScore!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Build a row showing Nafila statistics.
  Widget _buildNafilaStatRow(
    BuildContext context,
    NafilaType type,
    NafilaScore? score,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.englishName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type.arabicName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (score != null) ...[
            _buildStatBadge(context, '${score.percentage}%', 'Score'),
            const SizedBox(width: 8),
            _buildStatBadge(
              context,
              '${score.totalRakats}',
              'Rakats',
              icon: Icons.format_list_numbered,
            ),
            const SizedBox(width: 8),
            _buildStatBadge(
              context,
              '${score.currentStreak}',
              'Streak',
              icon: Icons.local_fire_department,
            ),
          ] else
            Text(
              'No data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  /// Build custom Nafila summary.
  Widget _buildCustomNafilaSummary(BuildContext context, NafilaScore score) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Nafila',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'نافلة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildStatBadge(
          context,
          '${score.totalCompletions}',
          'Sessions',
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(width: 8),
        _buildStatBadge(
          context,
          '${score.totalRakats}',
          'Rakats',
          icon: Icons.format_list_numbered,
        ),
      ],
    );
  }

  /// Build a small stat badge.
  Widget _buildStatBadge(
    BuildContext context,
    String value,
    String label, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: colorScheme.primary),
                const SizedBox(width: 2),
              ],
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display.
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
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
              Icons.bar_chart_outlined,
              size: 80,
              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Prayer System Disabled',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enable the Islamic Prayer System in settings to view statistics.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
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
              'Failed to load statistics',
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
              onPressed: () => ref.invalidate(prayerStatsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
