import 'package:flutter/material.dart';
import '../models/reminder_type.dart';

class ReminderTypeSelector extends StatelessWidget {
  final ReminderType? value;
  final ValueChanged<ReminderType> onChanged;

  const ReminderTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ReminderType>(
          segments: const [
            ButtonSegment(
              value: ReminderType.notification,
              label: Text('Notification'),
              icon: Icon(Icons.notifications),
            ),
            ButtonSegment(
              value: ReminderType.fullScreenAlarm,
              label: Text('Alarm'),
              icon: Icon(Icons.alarm),
            ),
          ],
          selected: value != null ? {value!} : {},
          onSelectionChanged: (Set<ReminderType> selected) {
            if (selected.isNotEmpty) {
              onChanged(selected.first);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildDescription(context),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    String description;
    if (value == ReminderType.notification) {
      description = 'Standard notification in the notification tray';
    } else if (value == ReminderType.fullScreenAlarm) {
      description = 'Full-screen alarm requiring dismissal';
    } else {
      description = 'Select a reminder type';
    }

    return Text(
      description,
      style: textStyle,
    );
  }
}
