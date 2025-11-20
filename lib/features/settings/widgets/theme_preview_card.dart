import 'package:flutter/material.dart';
import '../../../app/theme/theme_registry.dart';
import '../../../core/utils/core_logging_utility.dart';

/// A card widget that displays a preview of a theme with color swatches
/// and selection state. Used in the theme selector screen.
class ThemePreviewCard extends StatelessWidget {
  final ThemeInfo themeInfo;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.themeInfo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Get the current brightness to show appropriate theme variant
      final brightness = Theme.of(context).brightness;
      
      // Build the theme to extract color scheme with error handling
      final themeData = themeInfo.themeBuilder(const TextTheme(), brightness);
      final colorScheme = themeData.colorScheme;
      
      return _buildPreviewCard(context, colorScheme);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemePreviewCard',
        'build',
        'Failed to build theme preview for ${themeInfo.id}: $e\nStack trace: $stackTrace',
      );
      
      // Return error state card
      return _buildErrorCard(context);
    }
  }
  
  /// Builds the normal preview card with theme colors
  Widget _buildPreviewCard(BuildContext context, ColorScheme colorScheme) {

    return Semantics(
      label: '${themeInfo.displayName} theme',
      hint: isSelected ? 'Currently selected' : 'Tap to preview this theme',
      button: true,
      selected: isSelected,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color swatches showing primary, secondary, and tertiary colors
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: colorScheme.primary,
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: colorScheme.secondary,
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: colorScheme.tertiary,
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: colorScheme.onTertiary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Theme name and selection indicator
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        themeInfo.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                        size: 24,
                        semanticLabel: 'Selected',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds an error state card when theme building fails
  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                themeInfo.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Failed to load',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
