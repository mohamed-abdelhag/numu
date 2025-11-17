import 'package:flutter/material.dart';
import '../../models/enums/frequency.dart';

class FrequencySelector extends StatelessWidget {
  final Frequency? value;
  final ValueChanged<Frequency> onChanged;

  const FrequencySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Frequency>(
      segments: const [
        ButtonSegment(
          value: Frequency.daily,
          label: Text('Daily'),
          icon: Icon(Icons.today),
        ),
        ButtonSegment(
          value: Frequency.weekly,
          label: Text('Weekly'),
          icon: Icon(Icons.view_week),
        ),
        ButtonSegment(
          value: Frequency.monthly,
          label: Text('Monthly'),
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: value != null ? {value!} : {},
      onSelectionChanged: (Set<Frequency> selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
    );
  }
}
