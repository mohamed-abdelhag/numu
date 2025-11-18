import 'package:flutter/material.dart';

class QualityLayerToggle extends StatelessWidget {
  final bool enabled;
  final String? label;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onLabelChanged;

  const QualityLayerToggle({
    super.key,
    required this.enabled,
    required this.label,
    required this.onEnabledChanged,
    required this.onLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Enable Quality Layer'),
          subtitle: const Text('Track an additional quality criteria'),
          value: enabled,
          onChanged: onEnabledChanged,
          contentPadding: EdgeInsets.zero,
        ),
        if (enabled) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: label,
            decoration: const InputDecoration(
              labelText: 'Quality Label',
              hintText: 'e.g., "Stretched after", "Read 30+ pages"',
              border: OutlineInputBorder(),
              helperText: 'Describe what makes this habit "quality"',
            ),
            onChanged: onLabelChanged,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }
}
