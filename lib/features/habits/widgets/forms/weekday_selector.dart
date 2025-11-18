import 'package:flutter/material.dart';
import '../../models/enums/active_days_mode.dart';

class WeekdaySelector extends StatelessWidget {
  final ActiveDaysMode mode;
  final List<int>? selectedWeekdays;
  final ValueChanged<ActiveDaysMode> onModeChanged;
  final ValueChanged<List<int>> onWeekdaysChanged;

  const WeekdaySelector({
    super.key,
    required this.mode,
    required this.selectedWeekdays,
    required this.onModeChanged,
    required this.onWeekdaysChanged,
  });

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  void _toggleWeekday(int weekday) {
    final current = List<int>.from(selectedWeekdays ?? []);
    if (current.contains(weekday)) {
      current.remove(weekday);
    } else {
      current.add(weekday);
    }
    current.sort();
    onWeekdaysChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ActiveDaysMode>(
          segments: const [
            ButtonSegment(
              value: ActiveDaysMode.all,
              label: Text('All Days'),
              icon: Icon(Icons.calendar_today),
            ),
            ButtonSegment(
              value: ActiveDaysMode.selected,
              label: Text('Selected Days'),
              icon: Icon(Icons.event_available),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (Set<ActiveDaysMode> selected) {
            if (selected.isNotEmpty) {
              onModeChanged(selected.first);
            }
          },
        ),
        if (mode == ActiveDaysMode.selected) ...[
          const SizedBox(height: 16),
          Text(
            'Active Days',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1; // 1-7 for Monday-Sunday
              final isSelected = selectedWeekdays?.contains(weekday) ?? false;
              
              return FilterChip(
                label: Text(_weekdayLabels[index]),
                selected: isSelected,
                onSelected: (selected) => _toggleWeekday(weekday),
                showCheckmark: true,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the days when this habit applies',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
