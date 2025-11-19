import 'package:flutter/material.dart';

/// A widget that displays a due date badge with color coding and visual indicators
/// 
/// Features:
/// - Color-coded based on urgency (overdue, today, soon, normal)
/// - Warning icon for overdue tasks
/// - Relative date formatting ("Today", "Tomorrow") or absolute dates
/// - Handles null due dates gracefully
class DueDateBadge extends StatelessWidget {
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;

  const DueDateBadge({
    super.key,
    required this.dueDate,
    required this.isCompleted,
    required this.isOverdue,
    required this.isDueToday,
    required this.isDueSoon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine badge color and icon based on state
    final badgeColor = _getBadgeColor(theme);
    final icon = _getBadgeIcon();
    final dateText = _getDateText();

    return Semantics(
      label: _getSemanticLabel(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              dateText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get badge color based on task state
  Color _getBadgeColor(ThemeData theme) {
    if (isCompleted) {
      // Muted color for completed tasks
      return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }
    
    if (isOverdue) {
      // Red for overdue tasks
      return theme.colorScheme.error;
    }
    
    if (isDueToday) {
      // Orange for tasks due today
      return Colors.orange;
    }
    
    if (isDueSoon) {
      // Amber for tasks due soon (within 3 days)
      return Colors.amber.shade700;
    }
    
    // Default blue for future tasks
    return theme.colorScheme.primary;
  }

  /// Get appropriate icon for the badge
  IconData _getBadgeIcon() {
    if (dueDate == null) {
      return Icons.event_outlined;
    }
    
    if (isOverdue && !isCompleted) {
      return Icons.warning_amber_rounded;
    }
    
    if (isDueToday) {
      return Icons.today;
    }
    
    return Icons.event;
  }

  /// Get formatted date text
  String _getDateText() {
    if (dueDate == null) {
      return 'No due date';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final difference = due.difference(today).inDays;

    // Relative dates for recent/near dates
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    
    // For overdue tasks
    if (difference < -1 && difference >= -7) {
      return '${-difference} days ago';
    }
    
    // For upcoming tasks
    if (difference > 1 && difference <= 7) {
      return 'In $difference days';
    }

    // Absolute date format for older/distant dates
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dueDate!.month - 1];
    final day = dueDate!.day;
    
    if (dueDate!.year == now.year) {
      return '$month $day';
    } else {
      return '$month $day, ${dueDate!.year}';
    }
  }

  /// Get semantic label for screen readers
  String _getSemanticLabel() {
    if (dueDate == null) {
      return 'No due date set';
    }
    
    if (isCompleted) {
      return 'Due date was ${_getDateText()}';
    }
    
    if (isOverdue) {
      return 'Overdue: ${_getDateText()}';
    }
    
    if (isDueToday) {
      return 'Due today';
    }
    
    if (isDueSoon) {
      return 'Due soon: ${_getDateText()}';
    }
    
    return 'Due ${_getDateText()}';
  }
}
