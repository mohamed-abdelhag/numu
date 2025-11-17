import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final String? selectedIcon;
  final ValueChanged<String> onIconSelected;

  static const List<String> commonIcons = [
    '🏃', '💧', '📚', '🧘', '🍎', '💪', '🎯', '✍️',
    '🚶', '🏋️', '🧠', '❤️', '🌙', '☀️', '🎨', '🎵',
    '🍽️', '💤', '🚴', '🏊', '⚽', '🎮', '📱', '💻',
  ];

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commonIcons.map((icon) {
        final isSelected = icon == selectedIcon;
        return InkWell(
          onTap: () => onIconSelected(icon),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
