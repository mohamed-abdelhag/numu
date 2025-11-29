import 'package:flutter/material.dart';
import '../models/enums/prayer_type.dart';
import '../models/enums/prayer_status.dart';

/// A card widget displaying a single prayer with its name, time, and status.
///
/// **Validates: Requirements 6.1, 6.2**
class PrayerCard extends StatelessWidget {
  final PrayerType prayerType;
  final DateTime? prayerTime;
  final PrayerStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const PrayerCard({
    super.key,
    required this.prayerType,
    this.prayerTime,
    required this.status,
    this.onTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = status.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: _getBackgroundColor(colorScheme),
      child: InkWell(
        onTap: isCompleted ? onEditTap : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Prayer icon/indicator
              _buildStatusIndicator(colorScheme),
              const SizedBox(width: 16),

              // Prayer name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prayer name (English and Arabic)
                    Row(
                      children: [
                        Text(
                          prayerType.englishName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(colorScheme),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prayerType.arabicName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _getTextColor(colorScheme).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Prayer time
                    Text(
                      prayerTime != null ? _formatTime(prayerTime!) : '--:--',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getTextColor(colorScheme).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge with edit hint for completed prayers
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(context),
                  if (isCompleted && onEditTap != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to edit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    IconData icon;
    Color color;

    switch (status) {
      case PrayerStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PrayerStatus.completedLate:
        icon = Icons.check_circle;
        color = Colors.orange;
        break;
      case PrayerStatus.missed:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case PrayerStatus.pending:
        icon = Icons.access_time;
        color = colorScheme.primary;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case PrayerStatus.completed:
        label = 'Completed';
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green;
        break;
      case PrayerStatus.completedLate:
        label = 'Late';
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange;
        break;
      case PrayerStatus.missed:
        label = 'Missed';
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red;
        break;
      case PrayerStatus.pending:
        label = 'Pending';
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.15);
        textColor = theme.colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (status) {
      case PrayerStatus.completed:
        return Colors.green.withValues(alpha: 0.05);
      case PrayerStatus.completedLate:
        return Colors.orange.withValues(alpha: 0.05);
      case PrayerStatus.missed:
        return Colors.red.withValues(alpha: 0.05);
      case PrayerStatus.pending:
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    return colorScheme.onSurface;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
