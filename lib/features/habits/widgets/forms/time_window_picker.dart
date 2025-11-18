import 'package:flutter/material.dart';
import '../../models/enums/time_window_mode.dart';

class TimeWindowPicker extends StatelessWidget {
  final bool enabled;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TimeWindowMode? mode;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final ValueChanged<TimeWindowMode> onModeChanged;

  const TimeWindowPicker({
    super.key,
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.onEnabledChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onModeChanged,
  });

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay? initialTime,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Enable Time Window'),
          subtitle: const Text('Set a preferred time range for this habit'),
          value: enabled,
          onChanged: onEnabledChanged,
          contentPadding: EdgeInsets.zero,
        ),
        if (enabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectTime(
                    context,
                    startTime,
                    onStartTimeChanged,
                  ),
                  icon: const Icon(Icons.access_time),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Start Time',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        _formatTimeOfDay(startTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectTime(
                    context,
                    endTime,
                    onEndTimeChanged,
                  ),
                  icon: const Icon(Icons.access_time),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'End Time',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        _formatTimeOfDay(endTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mode',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<TimeWindowMode>(
            segments: const [
              ButtonSegment(
                value: TimeWindowMode.soft,
                label: Text('Soft'),
                icon: Icon(Icons.info_outline),
              ),
              ButtonSegment(
                value: TimeWindowMode.hard,
                label: Text('Hard'),
                icon: Icon(Icons.lock_outline),
              ),
            ],
            selected: mode != null ? {mode!} : {TimeWindowMode.soft},
            onSelectionChanged: (Set<TimeWindowMode> selected) {
              if (selected.isNotEmpty) {
                onModeChanged(selected.first);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            mode == TimeWindowMode.hard
                ? 'Hard mode: Only logs within the time window count'
                : 'Soft mode: Logs outside the window still count, but are tracked separately',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
