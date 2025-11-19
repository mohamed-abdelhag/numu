import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../models/reminder_type.dart';
import '../models/reminder_link.dart';

/// Widget displaying a single reminder in the list
/// Shows reminder type icon, title, description, linked entity badge,
/// next trigger time, and active/inactive toggle
/// Tapping navigates to the edit reminder screen
class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon indicating reminder type
              _buildTypeIcon(context),
              const SizedBox(width: 16),

              // Reminder info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      reminder.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: reminder.isActive
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description (if present)
                    if (reminder.description != null &&
                        reminder.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: reminder.isActive
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Linked entity badge and next trigger time
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Linked entity badge
                        if (reminder.link != null)
                          _buildLinkedEntityBadge(context),

                        // Next trigger time
                        if (reminder.nextTriggerTime != null)
                          _buildNextTriggerBadge(context),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Active/inactive toggle switch
              Switch(
                value: reminder.isActive,
                onChanged: onToggleActive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build icon indicating reminder type
  Widget _buildTypeIcon(BuildContext context) {
    final theme = Theme.of(context);
    final icon = reminder.type == ReminderType.notification
        ? Icons.notifications
        : Icons.alarm;
    final color = reminder.isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  /// Build linked entity badge
  Widget _buildLinkedEntityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final link = reminder.link!;
    final icon = link.type == LinkType.habit
        ? Icons.track_changes
        : Icons.task_alt;
    final label = link.entityName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Build next trigger time badge
  Widget _buildNextTriggerBadge(BuildContext context) {
    final theme = Theme.of(context);
    final triggerTime = reminder.nextTriggerTime!;
    final formattedTime = _formatNextTriggerTime(triggerTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            formattedTime,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Format next trigger time in human-readable format
  String _formatNextTriggerTime(DateTime triggerTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final triggerDate = DateTime(
      triggerTime.year,
      triggerTime.month,
      triggerTime.day,
    );

    final timeStr = _formatTime(triggerTime);

    if (triggerDate == today) {
      return 'Today at $timeStr';
    } else if (triggerDate == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else if (triggerTime.difference(now).inDays < 7) {
      final dayName = _getDayName(triggerTime.weekday);
      return '$dayName at $timeStr';
    } else {
      final dateStr = _formatDate(triggerTime);
      return '$dateStr at $timeStr';
    }
  }

  /// Format time as "h:mm AM/PM"
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Format date as "MMM d"
  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dateTime.month - 1];
    return '$month ${dateTime.day}';
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }
}
