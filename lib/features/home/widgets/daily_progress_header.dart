import 'package:flutter/material.dart';

class DailyProgressHeader extends StatelessWidget {
  final String userName;
  final int habitCount;
  final int taskCount;
  final int completionPercentage;

  const DailyProgressHeader({
    super.key,
    required this.userName,
    required this.habitCount,
    required this.taskCount,
    required this.completionPercentage,
  });

  String get _motivationalMessage {
    if (completionPercentage == 100) {
      return 'Done for the day';
    } else if (completionPercentage >= 76) {
      return 'Going well';
    } else if (completionPercentage >= 26) {
      return 'Almost there';
    } else {
      return "Let's get started";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
          // Welcome message
          Text(
            'Welcome, $userName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Summary count
          Text(
            '$habitCount habits and $taskCount tasks',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercentage / 100,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(theme),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Percentage and motivational message
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completionPercentage%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(theme),
                ),
              ),
              Text(
                _motivationalMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(ThemeData theme) {
    if (completionPercentage == 100) {
      return Colors.green;
    } else if (completionPercentage >= 76) {
      return Colors.blue;
    } else if (completionPercentage >= 26) {
      return Colors.orange;
    } else {
      return theme.colorScheme.primary;
    }
  }
}
