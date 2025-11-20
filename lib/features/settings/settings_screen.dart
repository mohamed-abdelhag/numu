import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/providers/navigation_provider.dart';
import 'package:numu/core/models/navigation_item.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import 'package:numu/features/settings/providers/user_profile_provider.dart';
import 'package:numu/features/habits/providers/habits_provider.dart';
import 'package:numu/features/settings/widgets/profile_section.dart';
import 'package:numu/features/settings/providers/theme_config_provider.dart';
import 'package:numu/features/settings/screens/theme_selector_screen.dart';
import 'package:numu/app/theme/theme_registry.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoreLoggingUtility.info('SettingsScreen', 'build', 'Building settings screen');
    
    final themeAsync = ref.watch(themeProvider);
    
    return Column(
      children: [
        const NumuAppBar(
          title: 'Settings',
        ),
        Expanded(
          child: themeAsync.when(
            data: (themeMode) => _buildSettingsContent(context, ref, themeMode),
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading settings...'),
                ],
              ),
            ),
            error: (error, stackTrace) {
              CoreLoggingUtility.error(
                'SettingsScreen',
                'build',
                'Error loading theme: $error\nStack trace: $stackTrace',
              );
              // Show error state with retry option
              return _buildErrorState(
                context,
                ref,
                'Failed to load theme settings',
                error.toString(),
                () => ref.invalidate(themeProvider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    final navigationAsync = ref.watch(navigationProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section at the top
          const ProfileSection(),
          const SizedBox(height: 24),
          _buildAppearanceSection(context, ref, currentThemeMode),
          const SizedBox(height: 24),
          userProfileAsync.when(
            data: (profile) => _buildPreferencesSection(context, ref, profile),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading preferences...'),
                  ],
                ),
              ),
            ),
            error: (error, stackTrace) {
              CoreLoggingUtility.error(
                'SettingsScreen',
                '_buildSettingsContent',
                'Error loading user profile: $error\nStack trace: $stackTrace',
              );
              return _buildErrorState(
                context,
                ref,
                'Failed to load preferences',
                error.toString(),
                () => ref.invalidate(userProfileProvider),
              );
            },
          ),
          const SizedBox(height: 24),
          navigationAsync.when(
            data: (navigationItems) => _buildNavigationSection(context, ref, navigationItems),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading navigation settings...'),
                  ],
                ),
              ),
            ),
            error: (error, stackTrace) {
              CoreLoggingUtility.error(
                'SettingsScreen',
                '_buildSettingsContent',
                'Error loading navigation items: $error\nStack trace: $stackTrace',
              );
              return _buildErrorState(
                context,
                ref,
                'Failed to load navigation settings',
                error.toString(),
                () => ref.invalidate(navigationProvider),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(themeConfigProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Mode',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) async {
                    final selectedMode = newSelection.first;
                    CoreLoggingUtility.info(
                      'SettingsScreen',
                      '_buildAppearanceSection',
                      'Theme mode changed to: ${selectedMode.name}',
                    );
                    
                    try {
                      // Update theme mode through provider
                      await ref.read(themeProvider.notifier).setThemeMode(selectedMode);
                      
                      // Show success feedback
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Theme changed to ${_getThemeModeName(selectedMode)}'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      CoreLoggingUtility.error(
                        'SettingsScreen',
                        '_buildAppearanceSection',
                        'Failed to save theme preference: $e',
                      );
                      
                      // Show error feedback with retry option
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save theme: ${e.toString()}'),
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red,
                            action: SnackBarAction(
                              label: 'Retry',
                              textColor: Colors.white,
                              onPressed: () async {
                                try {
                                  await ref.read(themeProvider.notifier).setThemeMode(selectedMode);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Theme saved successfully'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (retryError) {
                                  CoreLoggingUtility.error(
                                    'SettingsScreen',
                                    '_buildAppearanceSection',
                                    'Retry failed: $retryError',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Retry failed: ${retryError.toString()}'),
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Color Theme subsection
                Text(
                  'Color Theme',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                configAsync.when(
                  data: (config) {
                    final themeInfo = ThemeRegistry.getTheme(config.colorSchemeId);
                    return ListTile(
                      leading: Icon(
                        Icons.palette,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(themeInfo.displayName),
                      subtitle: const Text('Tap to change color theme'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        CoreLoggingUtility.info(
                          'SettingsScreen',
                          '_buildAppearanceSection',
                          'Navigating to theme selector',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemeSelectorScreen(),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const ListTile(
                    leading: Icon(Icons.palette),
                    title: Text('Loading...'),
                    trailing: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, stackTrace) {
                    CoreLoggingUtility.error(
                      'SettingsScreen',
                      '_buildAppearanceSection',
                      'Error loading color theme: $error',
                    );
                    return ListTile(
                      leading: Icon(
                        Icons.error,
                        color: theme.colorScheme.error,
                      ),
                      title: const Text('Error loading color theme'),
                      subtitle: Text(error.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          CoreLoggingUtility.info(
                            'SettingsScreen',
                            '_buildAppearanceSection',
                            'Retrying color theme load',
                          );
                          ref.invalidate(themeConfigProvider);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System default';
    }
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref, dynamic profile) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Week Starts On'),
                subtitle: Text(
                  profile != null 
                    ? _getDayName(profile.startOfWeek)
                    : 'Monday',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWeekStartPicker(context, ref, profile),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayName(int dayNumber) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    
    if (dayNumber < 1 || dayNumber > 7) {
      return 'Monday'; // Default fallback
    }
    
    return days[dayNumber - 1];
  }

  Future<void> _showWeekStartPicker(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) async {
    if (profile == null) {
      CoreLoggingUtility.warning(
        'SettingsScreen',
        '_showWeekStartPicker',
        'Cannot change week start: no user profile found',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please create a profile first'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final theme = Theme.of(context);
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Week Starts On'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayNumber = index + 1;
              final isSelected = profile.startOfWeek == dayNumber;
              
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  days[index],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                onTap: () => Navigator.pop(context, dayNumber),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (selected != null && selected != profile.startOfWeek) {
      CoreLoggingUtility.info(
        'SettingsScreen',
        '_showWeekStartPicker',
        'Week start changed from ${profile.startOfWeek} to $selected',
      );
      
      try {
        final updatedProfile = profile.copyWith(
          startOfWeek: selected,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
        
        CoreLoggingUtility.info(
          'SettingsScreen',
          '_showWeekStartPicker',
          'Successfully updated week start preference',
        );
        
        // Invalidate habit providers to trigger recalculation with new week start
        ref.invalidate(habitsProvider);
        
        CoreLoggingUtility.info(
          'SettingsScreen',
          '_showWeekStartPicker',
          'Invalidated habit providers for recalculation',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Week now starts on ${_getDayName(selected)}'),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'SettingsScreen',
          '_showWeekStartPicker',
          'Failed to update week start preference: $e\n$stackTrace',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Failed to update week start'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _showWeekStartPicker(context, ref, profile),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildNavigationSection(BuildContext context, WidgetRef ref, List<NavigationItem> navigationItems) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Side Panel',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Reorder and toggle navigation items. Home and Settings are always visible.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                _buildReorderableNavigationList(context, ref, navigationItems),
                const SizedBox(height: 16),
                _buildSaveButton(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableNavigationList(BuildContext context, WidgetRef ref, List<NavigationItem> items) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        CoreLoggingUtility.info(
          'SettingsScreen',
          '_buildReorderableNavigationList',
          'Reordering item from $oldIndex to $newIndex',
        );
        ref.read(navigationProvider.notifier).reorderItems(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return NavigationItemTile(
          key: ValueKey(item.id),
          item: item,
          onToggle: (value) {
            CoreLoggingUtility.info(
              'SettingsScreen',
              '_buildReorderableNavigationList',
              'Toggling visibility for ${item.id}: $value',
            );
            ref.read(navigationProvider.notifier).toggleItemVisibility(item.id);
          },
        );
      },
    );
  }

  Widget _buildSaveButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: Consumer(
        builder: (context, ref, child) {
          final navigationAsync = ref.watch(navigationProvider);
          final isLoading = navigationAsync.isLoading;
          
          return ElevatedButton.icon(
            onPressed: isLoading ? null : () => _saveNavigationChanges(context, ref),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isLoading ? 'Saving...' : 'Save Navigation Changes'),
          );
        },
      ),
    );
  }

  /// Saves navigation changes with error handling and retry mechanism
  Future<void> _saveNavigationChanges(BuildContext context, WidgetRef ref) async {
    try {
      CoreLoggingUtility.info(
        'SettingsScreen',
        '_saveNavigationChanges',
        'Saving navigation changes',
      );
      
      await ref.read(navigationProvider.notifier).saveChanges();
      
      CoreLoggingUtility.info(
        'SettingsScreen',
        '_saveNavigationChanges',
        'Navigation changes saved successfully',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Navigation preferences saved successfully'),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsScreen',
        '_saveNavigationChanges',
        'Failed to save navigation changes: $e\nStack trace: $stackTrace',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Failed to save navigation changes'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _retryNavigationSave(context, ref),
            ),
          ),
        );
      }
    }
  }

  /// Retries saving navigation changes
  Future<void> _retryNavigationSave(BuildContext context, WidgetRef ref) async {
    try {
      CoreLoggingUtility.info(
        'SettingsScreen',
        '_retryNavigationSave',
        'Retrying navigation save',
      );
      
      await ref.read(navigationProvider.notifier).saveChanges();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Navigation preferences saved successfully'),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (retryError, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsScreen',
        '_retryNavigationSave',
        'Retry failed: $retryError\nStack trace: $stackTrace',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Retry failed'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  retryError.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

  /// Builds an error state widget with retry functionality
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String title,
    String errorMessage,
    VoidCallback onRetry,
  ) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                CoreLoggingUtility.info(
                  'SettingsScreen',
                  '_buildErrorState',
                  'Retrying after error: $title',
                );
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

/// Widget for displaying a single navigation item in the reorderable list
class NavigationItemTile extends StatelessWidget {
  final NavigationItem item;
  final ValueChanged<bool> onToggle;

  const NavigationItemTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = item.isLocked;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: isLocked 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Icon(
              item.icon,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        title: Row(
          children: [
            Text(item.label),
            if (isLocked) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.lock,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
        trailing: Checkbox(
          value: item.isEnabled,
          onChanged: isLocked ? null : (value) {
            if (value != null) {
              onToggle(value);
            }
          },
        ),
        enabled: !isLocked,
      ),
    );
  }
}
