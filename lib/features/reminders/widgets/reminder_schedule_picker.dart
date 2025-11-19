import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reminder_schedule.dart';
import '../models/reminder_link.dart';

class ReminderSchedulePicker extends StatelessWidget {
  final ReminderSchedule schedule;
  final ReminderLink? link;
  final ValueChanged<ReminderSchedule> onScheduleChanged;

  const ReminderSchedulePicker({
    super.key,
    required this.schedule,
    this.link,
    required this.onScheduleChanged,
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

  void _updateSchedule({
    ScheduleFrequency? frequency,
    DateTime? specificDateTime,
    TimeOfDay? timeOfDay,
    List<int>? activeWeekdays,
    int? dayOfMonth,
    int? minutesBefore,
    bool? useHabitTimeWindow,
    bool? useHabitActiveDays,
  }) {
    onScheduleChanged(
      schedule.copyWith(
        frequency: frequency,
        specificDateTime: specificDateTime,
        timeOfDay: timeOfDay,
        activeWeekdays: activeWeekdays,
        dayOfMonth: dayOfMonth,
        minutesBefore: minutesBefore,
        useHabitTimeWindow: useHabitTimeWindow,
        useHabitActiveDays: useHabitActiveDays,
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: schedule.specificDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: schedule.specificDateTime != null
            ? TimeOfDay.fromDateTime(schedule.specificDateTime!)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _updateSchedule(specificDateTime: dateTime);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: schedule.timeOfDay ?? TimeOfDay.now(),
    );
    if (picked != null) {
      _updateSchedule(timeOfDay: picked);
    }
  }

  void _toggleWeekday(int weekday) {
    final current = List<int>.from(schedule.activeWeekdays ?? []);
    if (current.contains(weekday)) {
      current.remove(weekday);
    } else {
      current.add(weekday);
    }
    current.sort();
    _updateSchedule(activeWeekdays: current);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select date and time';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Select time';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildFrequencySelector(context),
        const SizedBox(height: 16),
        _buildScheduleConfiguration(context),
      ],
    );
  }

  Widget _buildFrequencySelector(BuildContext context) {
    return SegmentedButton<ScheduleFrequency>(
      segments: const [
        ButtonSegment(
          value: ScheduleFrequency.none,
          label: Text('Once'),
          icon: Icon(Icons.event),
        ),
        ButtonSegment(
          value: ScheduleFrequency.daily,
          label: Text('Daily'),
          icon: Icon(Icons.today),
        ),
        ButtonSegment(
          value: ScheduleFrequency.weekly,
          label: Text('Weekly'),
          icon: Icon(Icons.view_week),
        ),
        ButtonSegment(
          value: ScheduleFrequency.monthly,
          label: Text('Monthly'),
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: {schedule.frequency},
      onSelectionChanged: (Set<ScheduleFrequency> selected) {
        if (selected.isNotEmpty) {
          _updateSchedule(frequency: selected.first);
        }
      },
    );
  }

  Widget _buildScheduleConfiguration(BuildContext context) {
    switch (schedule.frequency) {
      case ScheduleFrequency.none:
        return _buildOneTimeConfiguration(context);
      case ScheduleFrequency.daily:
        return _buildDailyConfiguration(context);
      case ScheduleFrequency.weekly:
        return _buildWeeklyConfiguration(context);
      case ScheduleFrequency.monthly:
        return _buildMonthlyConfiguration(context);
    }
  }

  Widget _buildOneTimeConfiguration(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _selectDateTime(context),
          icon: const Icon(Icons.calendar_today),
          label: Text(_formatDateTime(schedule.specificDateTime)),
        ),
        const SizedBox(height: 8),
        Text(
          'Select when this reminder should trigger',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildDailyConfiguration(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _selectTime(context),
          icon: const Icon(Icons.access_time),
          label: Text(_formatTimeOfDay(schedule.timeOfDay)),
        ),
        const SizedBox(height: 8),
        Text(
          'Reminder will trigger every day at this time',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (link?.type == LinkType.habit) ...[
          const SizedBox(height: 16),
          _buildHabitConfiguration(context),
        ],
        if (link?.type == LinkType.task) ...[
          const SizedBox(height: 16),
          _buildMinutesBeforeInput(context),
        ],
      ],
    );
  }

  Widget _buildWeeklyConfiguration(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _selectTime(context),
          icon: const Icon(Icons.access_time),
          label: Text(_formatTimeOfDay(schedule.timeOfDay)),
        ),
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
            final weekday = index + 1;
            final isSelected = schedule.activeWeekdays?.contains(weekday) ?? false;

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
          'Select the days when this reminder should trigger',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (link?.type == LinkType.habit) ...[
          const SizedBox(height: 16),
          _buildHabitConfiguration(context),
        ],
        if (link?.type == LinkType.task) ...[
          const SizedBox(height: 16),
          _buildMinutesBeforeInput(context),
        ],
      ],
    );
  }

  Widget _buildMonthlyConfiguration(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _selectTime(context),
          icon: const Icon(Icons.access_time),
          label: Text(_formatTimeOfDay(schedule.timeOfDay)),
        ),
        const SizedBox(height: 16),
        Text(
          'Day of Month',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: schedule.dayOfMonth?.toString() ?? '',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _DayOfMonthInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Day',
              hintText: '1-31',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final day = int.tryParse(value);
              if (day != null && day >= 1 && day <= 31) {
                _updateSchedule(dayOfMonth: day);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reminder will trigger on this day each month',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (link?.type == LinkType.habit) ...[
          const SizedBox(height: 16),
          _buildHabitConfiguration(context),
        ],
        if (link?.type == LinkType.task) ...[
          const SizedBox(height: 16),
          _buildMinutesBeforeInput(context),
        ],
      ],
    );
  }

  Widget _buildHabitConfiguration(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habit Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Use habit time window'),
          subtitle: const Text('Trigger at the habit\'s scheduled time'),
          value: schedule.useHabitTimeWindow,
          onChanged: (value) {
            _updateSchedule(useHabitTimeWindow: value ?? false);
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Use habit active days'),
          subtitle: const Text('Only trigger on habit\'s active days'),
          value: schedule.useHabitActiveDays,
          onChanged: (value) {
            _updateSchedule(useHabitActiveDays: value ?? false);
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (schedule.useHabitTimeWindow) ...[
          const SizedBox(height: 8),
          _buildMinutesBeforeInput(context),
        ],
      ],
    );
  }

  Widget _buildMinutesBeforeInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minutes Before',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: schedule.minutesBefore?.toString() ?? '',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  hintText: '0-1440',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null && minutes >= 0 && minutes <= 1440) {
                    _updateSchedule(minutesBefore: minutes);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickMinutesButton(context, 15),
                  const SizedBox(height: 4),
                  _buildQuickMinutesButton(context, 30),
                  const SizedBox(height: 4),
                  _buildQuickMinutesButton(context, 60),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          link?.type == LinkType.task
              ? 'Remind this many minutes before the task due date'
              : 'Remind this many minutes before the habit time window',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickMinutesButton(BuildContext context, int minutes) {
    final isSelected = schedule.minutesBefore == minutes;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _updateSchedule(minutesBefore: minutes),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }
}

class _DayOfMonthInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value > 31) {
      return oldValue;
    }

    return newValue;
  }
}
