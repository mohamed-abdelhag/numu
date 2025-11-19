import 'package:flutter/material.dart';
import '../../models/enums/goal_type.dart';

class GoalTypeSelector extends StatelessWidget {
  final GoalType? value;
  final ValueChanged<GoalType> onChanged;

  const GoalTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<GoalType>(
      segments: const [
        ButtonSegment(
          value: GoalType.minimum,
          label: Text('Minimum'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: GoalType.maximum,
          label: Text('Maximum'),
          icon: Icon(Icons.arrow_downward),
        ),
      ],
      selected: value != null ? {value!} : {},
      onSelectionChanged: (Set<GoalType> selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
    );
  }
}
