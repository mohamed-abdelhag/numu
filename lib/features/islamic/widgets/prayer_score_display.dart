import 'package:flutter/material.dart';
import '../models/prayer_score.dart';
import '../models/enums/prayer_type.dart';

/// A widget for visualizing prayer score and streaks.
///
/// **Validates: Requirements 6.6**
class PrayerScoreDisplay extends StatelessWidget {
  final Map<PrayerType, PrayerScore> scores;
  final double overallScore;
  final double? averageJamaahRate;

  const PrayerScoreDisplay({
    super.key,
    required this.scores,
    required this.overallScore,
    this.averageJamaahRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overallPercentage = (overallScore * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Prayer Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Overall score and Jamaah rate row
          Row(
            children: [
              // Overall score
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.speed,
                  label: 'Overall Score',
                  value: '$overallPercentage%',
                  color: _getScoreColor(overallPercentage),
                ),
              ),
              const SizedBox(width: 12),
              // Jamaah rate
              if (averageJamaahRate != null)
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.groups,
                    label: 'Jamaah Rate',
                    value: '${(averageJamaahRate! * 100).round()}%',
                    color: Colors.green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Individual prayer scores
          Text(
            'Individual Prayers',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Prayer score list
          ...PrayerType.values.map((type) => _buildPrayerScoreRow(
                context,
                type,
                scores[type],
              )),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerScoreRow(
    BuildContext context,
    PrayerType type,
    PrayerScore? score,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = score?.percentage ?? 0;
    final currentStreak = score?.currentStreak ?? 0;
    final longestStreak = score?.longestStreak ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Prayer name
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.englishName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  type.arabicName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(percentage),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getScoreColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Streak info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: Color(0xFFE67E22),
                ),
                const SizedBox(width: 4),
                Text(
                  '$currentStreak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE67E22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (longestStreak > 0) ...[
                  Text(
                    ' / $longestStreak',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFE67E22).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.lightGreen;
    } else if (percentage >= 40) {
      return Colors.orange;
    } else if (percentage >= 20) {
      return Colors.deepOrange;
    } else {
      return Colors.grey;
    }
  }
}
