import 'package:flutter/material.dart';
import '../models/enums/nafila_type.dart';

/// A thin indicator card widget displaying a Nafila prayer status.
///
/// Shows a compact green card with the Nafila type name, checkmark when completed,
/// and rakat count. Displays in a muted/inactive state when not completed.
///
/// **Validates: Requirements 3.1, 3.2, 3.4**
class NafilaIndicatorCard extends StatelessWidget {
  final NafilaType type;
  final bool isCompleted;
  final int? rakatCount;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const NafilaIndicatorCard({
    super.key,
    required this.type,
    required this.isCompleted,
    this.rakatCount,
    this.onTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      color: _getBackgroundColor(colorScheme),
      child: InkWell(
        onTap: isCompleted ? onEditTap : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Status indicator icon
              _buildStatusIndicator(colorScheme),
              const SizedBox(width: 12),

              // Nafila name (English and Arabic)
              Expanded(
                child: Row(
                  children: [
                    Text(
                      type.englishName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(colorScheme),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.arabicName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getTextColor(colorScheme).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Rakat count and status badge
              if (isCompleted && rakatCount != null) ...[
                _buildRakatBadge(theme),
                const SizedBox(width: 8),
              ],
              _buildStatusBadge(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    if (isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.check,
          color: Colors.green,
          size: 18,
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.radio_button_unchecked,
        color: colorScheme.onSurface.withValues(alpha: 0.4),
        size: 18,
      ),
    );
  }

  Widget _buildRakatBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$rakatCount ركعة',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, ColorScheme colorScheme) {
    if (isCompleted) {
      return Icon(
        Icons.edit_outlined,
        size: 16,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Tap to log',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isCompleted) {
      return Colors.green.withValues(alpha: 0.08);
    }
    return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isCompleted) {
      return colorScheme.onSurface;
    }
    return colorScheme.onSurface.withValues(alpha: 0.6);
  }
}
