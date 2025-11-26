import 'package:flutter/material.dart';

/// A header widget displaying daily prayer score and completion count.
///
/// **Validates: Requirements 6.5**
class PrayerProgressHeader extends StatelessWidget {
  final int completedCount;
  final int totalPrayers;
  final int scorePercentage;

  const PrayerProgressHeader({
    super.key,
    required this.completedCount,
    this.totalPrayers = 5,
    required this.scorePercentage,
  });

  String get _motivationalMessage {
    if (completedCount == totalPrayers) {
      return 'All prayers completed!';
    } else if (completedCount >= 4) {
      return 'Almost there!';
    } else if (completedCount >= 2) {
      return 'Keep going!';
    } else if (completedCount >= 1) {
      return 'Good start!';
    } else {
      return 'Start your day with prayer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = completedCount / totalPrayers;

    return Container(
      padding: const EdgeInsets.all(20),
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
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mosque,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Prayers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Completion count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProgressColor(progress).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount/$totalPrayers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(progress),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Score and motivational message
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score display
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 18,
                    color: _getScoreColor(scorePercentage),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Score: $scorePercentage%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(scorePercentage),
                    ),
                  ),
                ],
              ),
              // Motivational message
              Text(
                _motivationalMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return Colors.green;
    } else if (progress >= 0.8) {
      return Colors.lightGreen;
    } else if (progress >= 0.6) {
      return Colors.blue;
    } else if (progress >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
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
