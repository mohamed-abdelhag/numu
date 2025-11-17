import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;

  static const List<String> commonColors = [
    '0xFFE57373', // Red
    '0xFFBA68C8', // Purple
    '0xFF64B5F6', // Blue
    '0xFF4DB6AC', // Teal
    '0xFF81C784', // Green
    '0xFFFFD54F', // Yellow
    '0xFFFF8A65', // Orange
    '0xFF90A4AE', // Blue Grey
  ];

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commonColors.map((colorHex) {
        final isSelected = colorHex == selectedColor;
        return InkWell(
          onTap: () => onColorSelected(colorHex),
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(int.parse(colorHex)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
