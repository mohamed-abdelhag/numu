import 'package:flutter/material.dart';
import '../../models/enums/tracking_type.dart';

class TrackingTypeSelector extends StatelessWidget {
  final TrackingType? value;
  final ValueChanged<TrackingType> onChanged;

  const TrackingTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrackingType>(
      segments: const [
        ButtonSegment(
          value: TrackingType.binary,
          label: Text('Yes/No'),
          icon: Icon(Icons.check),
        ),
        ButtonSegment(
          value: TrackingType.value,
          label: Text('Value'),
          icon: Icon(Icons.numbers),
        ),
      ],
      selected: value != null ? {value!} : {},
      onSelectionChanged: (Set<TrackingType> selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
    );
  }
}
