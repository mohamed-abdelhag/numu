import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_registry.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../providers/theme_config_provider.dart';
import '../widgets/theme_preview_card.dart';

/// Screen for browsing and selecting color themes with live preview
/// Allows users to preview themes instantly and save their selection
class ThemeSelectorScreen extends ConsumerStatefulWidget {
  const ThemeSelectorScreen({super.key});

  @override
  ConsumerState<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends ConsumerState<ThemeSelectorScreen> {
  String? _previewThemeId;
  String? _originalThemeId;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Store original theme for revert capability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(themeConfigProvider).value;
      if (config != null && mounted) {
        setState(() {
          _originalThemeId = config.colorSchemeId;
          _previewThemeId = _originalThemeId;
        });
        
        CoreLoggingUtility.info(
          'ThemeSelectorScreen',
          'initState',
          'Initialized with theme: $_originalThemeId',
        );
      }
    });
  }

  /// Handles the back button press with unsaved changes check
  Future<bool> _handleBackButton() async {
    if (_hasUnsavedChanges && _originalThemeId != null) {
      CoreLoggingUtility.info(
        'ThemeSelectorScreen',
        '_handleBackButton',
        'User attempting to leave with unsaved changes',
      );
      
      final shouldLeave = await _showUnsavedChangesDialog();
      
      if (shouldLeave == true) {
        // Revert to original theme before leaving
        await _revertToOriginalTheme();
        return true;
      }
      return false;
    }
    return true;
  }

  /// Shows a dialog asking the user to confirm leaving without saving
  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => const UnsavedChangesDialog(),
    );
  }

  /// Reverts the theme to the original selection
  Future<void> _revertToOriginalTheme() async {
    final originalId = _originalThemeId;
    if (_previewThemeId != null && originalId != null && _previewThemeId != originalId) {
      try {
        CoreLoggingUtility.info(
          'ThemeSelectorScreen',
          '_revertToOriginalTheme',
          'Reverting theme from $_previewThemeId to $originalId',
        );
        
        await ref.read(themeConfigProvider.notifier).setColorScheme(originalId);
        
        CoreLoggingUtility.info(
          'ThemeSelectorScreen',
          '_revertToOriginalTheme',
          'Successfully reverted to original theme',
        );
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'ThemeSelectorScreen',
          '_revertToOriginalTheme',
          'Failed to revert theme: $e\nStack trace: $stackTrace',
        );
      }
    }
  }

  /// Previews a theme by applying it instantly
  void _previewTheme(String themeId) async {
    if (_previewThemeId == themeId) {
      return; // Already previewing this theme
    }

    try {
      CoreLoggingUtility.info(
        'ThemeSelectorScreen',
        '_previewTheme',
        'Previewing theme: $themeId',
      );

      setState(() {
        _previewThemeId = themeId;
        _hasUnsavedChanges = _originalThemeId != null && themeId != _originalThemeId;
      });

      // Apply theme instantly for preview
      await ref.read(themeConfigProvider.notifier).setColorScheme(themeId);

      CoreLoggingUtility.info(
        'ThemeSelectorScreen',
        '_previewTheme',
        'Successfully applied preview theme',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeSelectorScreen',
        '_previewTheme',
        'Failed to preview theme: $e\nStack trace: $stackTrace',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to preview theme. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _previewTheme(themeId),
            ),
          ),
        );
      }
    }
  }

  /// Saves the selected theme and navigates back to settings
  Future<void> _saveTheme() async {
    if (_isSaving || _previewThemeId == null) {
      return; // Prevent multiple save operations or saving when no theme selected
    }

    setState(() {
      _isSaving = true;
    });

    try {
      CoreLoggingUtility.info(
        'ThemeSelectorScreen',
        '_saveTheme',
        'Saving theme selection: $_previewThemeId',
      );

      // The theme is already applied from preview, just update the original reference
      setState(() {
        _originalThemeId = _previewThemeId;
        _hasUnsavedChanges = false;
      });

      CoreLoggingUtility.info(
        'ThemeSelectorScreen',
        '_saveTheme',
        'Theme successfully saved',
      );

      if (mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Theme saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to settings after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeSelectorScreen',
        '_saveTheme',
        'Failed to save theme: $e\nStack trace: $stackTrace',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save theme. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveTheme,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(themeConfigProvider);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _handleBackButton();
          if (shouldPop && mounted) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Theme'),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: _isSaving ? null : _saveTheme,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
          ],
        ),
        body: configAsync.when(
          data: (config) => _buildThemeGrid(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(error),
        ),
      ),
    );
  }

  /// Builds the grid of theme preview cards
  Widget _buildThemeGrid() {
    final themes = ThemeRegistry.getAllThemes();
    
    // Initialize theme IDs if not already set
    if (_previewThemeId == null || _originalThemeId == null) {
      final config = ref.read(themeConfigProvider).value;
      if (config != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _originalThemeId = config.colorSchemeId;
              _previewThemeId = _originalThemeId;
            });
          }
        });
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final themeInfo = themes[index];
        return ThemePreviewCard(
          themeInfo: themeInfo,
          isSelected: _previewThemeId == themeInfo.id,
          onTap: () => _previewTheme(themeInfo.id),
        );
      },
    );
  }

  /// Builds the error state UI
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load themes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(themeConfigProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog shown when user attempts to leave with unsaved changes
class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text(
        'You have unsaved theme changes. Do you want to discard them and go back?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    );
  }
}
