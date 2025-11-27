import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../../core/widgets/shell/numu_app_bar.dart';
import '../models/enums/calculation_method.dart';
import '../models/enums/prayer_type.dart';
import '../providers/prayer_settings_provider.dart';
import '../services/prayer_location_service.dart';

/// Screen for configuring Islamic Prayer System settings.
/// Allows configuration of calculation method, time window, and reminders.
/// Handles location permission prompts.
///
/// **Validates: Requirements 8.3, 8.4, 8.5, 8.6**
class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  ConsumerState<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen> {
  final PrayerLocationService _locationService = PrayerLocationService();
  bool _isCheckingLocation = false;

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('PrayerSettingsScreen', 'build', 'Building prayer settings screen');
    
    final settingsAsync = ref.watch(prayerSettingsProvider);

    return Scaffold(
      body: Column(
        children: [
          NumuAppBar(
            title: 'Prayer Settings',
            showDrawerButton: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildErrorState(context, error),
              data: (settings) => _buildSettingsContent(context, settings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, dynamic settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable/Disable toggle
          _buildEnableSection(context, settings),
          const SizedBox(height: 24),

          // Only show other settings if enabled
          if (settings.isEnabled) ...[
            // Location section
            _buildLocationSection(context, settings),
            const SizedBox(height: 24),

            // Calculation method
            _buildCalculationMethodSection(context, settings),
            const SizedBox(height: 24),

            // Time window
            _buildTimeWindowSection(context, settings),
            const SizedBox(height: 24),

            // Reminders
            _buildRemindersSection(context, settings),
          ],
        ],
      ),
    );
  }


  Widget _buildEnableSection(BuildContext context, dynamic settings) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Islamic Prayer System',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: const Text('Enable Prayer Tracking'),
            subtitle: Text(
              settings.isEnabled
                  ? 'Track your five daily prayers'
                  : 'Enable to start tracking your prayers',
            ),
            value: settings.isEnabled,
            onChanged: (value) => _toggleEnabled(value),
            secondary: Icon(
              Icons.mosque,
              color: settings.isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context, dynamic settings) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              FutureBuilder<bool>(
                future: _locationService.hasLocationPermission(),
                builder: (context, snapshot) {
                  final hasPermission = snapshot.data ?? false;
                  
                  return ListTile(
                    leading: Icon(
                      hasPermission ? Icons.location_on : Icons.location_off,
                      color: hasPermission ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      hasPermission ? 'Location Access Granted' : 'Location Access Required',
                    ),
                    subtitle: Text(
                      hasPermission
                          ? 'Prayer times are calculated based on your location'
                          : 'Grant location access for accurate prayer times',
                    ),
                    trailing: _isCheckingLocation
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : hasPermission
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : TextButton(
                                onPressed: _requestLocationPermission,
                                child: const Text('Grant'),
                              ),
                  );
                },
              ),
              if (settings.lastLatitude != null && settings.lastLongitude != null)
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: const Text('Last Known Location'),
                  subtitle: Text(
                    'Lat: ${settings.lastLatitude!.toStringAsFixed(4)}, '
                    'Lng: ${settings.lastLongitude!.toStringAsFixed(4)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _updateLocation,
                    tooltip: 'Update location',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationMethodSection(BuildContext context, dynamic settings) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Different methods are used in different regions',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: CalculationMethod.values.map((method) {
              final isSelected = settings.calculationMethod == method;
              return RadioListTile<CalculationMethod>(
                title: Text(method.displayName),
                value: method,
                groupValue: settings.calculationMethod,
                onChanged: (value) {
                  if (value != null) {
                    _setCalculationMethod(value);
                  }
                },
                secondary: isSelected
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeWindowSection(BuildContext context, dynamic settings) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Window',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Duration after prayer time during which completion is tracked',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time Window Duration'),
                    Text(
                      '${settings.timeWindowMinutes} minutes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: settings.timeWindowMinutes.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  label: '${settings.timeWindowMinutes} min',
                  onChanged: (value) {
                    _setTimeWindow(value.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '15 min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '120 min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildRemindersSection(BuildContext context, dynamic settings) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prayer Reminders',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure reminders for each prayer',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: PrayerType.values.map((type) {
              final isEnabled = settings.reminderEnabled[type] ?? true;
              final offset = settings.reminderOffsetMinutes[type] ?? 15;

              return ExpansionTile(
                leading: Icon(
                  isEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: Row(
                  children: [
                    Text(type.englishName),
                    const SizedBox(width: 8),
                    Text(
                      type.arabicName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  isEnabled ? '$offset min before' : 'Disabled',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Reminder'),
                          value: isEnabled,
                          onChanged: (value) => _setReminderEnabled(type, value),
                        ),
                        if (isEnabled) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Remind me'),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: offset,
                                items: [5, 10, 15, 20, 30, 45, 60].map((minutes) {
                                  return DropdownMenuItem<int>(
                                    value: minutes,
                                    child: Text('$minutes min'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _setReminderOffset(type, value);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text('before prayer time'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Failed to load settings',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(prayerSettingsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEnabled(bool enabled) async {
    CoreLoggingUtility.info(
      'PrayerSettingsScreen',
      '_toggleEnabled',
      'Toggling prayer system to: $enabled',
    );

    try {
      await ref.read(prayerSettingsProvider.notifier).setEnabled(enabled);

      if (enabled && mounted) {
        // Check location permission when enabling
        final hasPermission = await _locationService.hasLocationPermission();
        if (!hasPermission) {
          _showLocationPermissionDialog();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? 'Prayer tracking enabled' : 'Prayer tracking disabled',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_toggleEnabled',
        'Failed to toggle enabled state: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      final isPermanentlyDenied = await _locationService.isLocationPermissionPermanentlyDenied();
      
      if (isPermanentlyDenied) {
        if (mounted) {
          _showOpenSettingsDialog();
        }
        return;
      }

      final granted = await _locationService.requestLocationPermission();

      if (granted) {
        await _updateLocation();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission granted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_requestLocationPermission',
        'Failed to request location permission: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
        });
      }
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        await ref.read(prayerSettingsProvider.notifier).setLastLocation(
          location.latitude,
          location.longitude,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get current location'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_updateLocation',
        'Failed to update location: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
        });
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('Location Required'),
          ],
        ),
        content: const Text(
          'The Islamic Prayer System needs your location to calculate accurate prayer times for your area.\n\n'
          'Would you like to grant location permission?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission has been permanently denied. '
          'Please open app settings to grant location access for accurate prayer times.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _locationService.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _setCalculationMethod(CalculationMethod method) async {
    CoreLoggingUtility.info(
      'PrayerSettingsScreen',
      '_setCalculationMethod',
      'Setting calculation method to: ${method.displayName}',
    );

    try {
      await ref.read(prayerSettingsProvider.notifier).setCalculationMethod(method);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calculation method set to ${method.displayName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_setCalculationMethod',
        'Failed to set calculation method: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setTimeWindow(int minutes) async {
    CoreLoggingUtility.info(
      'PrayerSettingsScreen',
      '_setTimeWindow',
      'Setting time window to: $minutes minutes',
    );

    try {
      await ref.read(prayerSettingsProvider.notifier).setTimeWindowMinutes(minutes);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_setTimeWindow',
        'Failed to set time window: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setReminderEnabled(PrayerType type, bool enabled) async {
    CoreLoggingUtility.info(
      'PrayerSettingsScreen',
      '_setReminderEnabled',
      'Setting reminder for ${type.englishName} to: $enabled',
    );

    try {
      await ref.read(prayerSettingsProvider.notifier).setReminderEnabled(type, enabled);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_setReminderEnabled',
        'Failed to set reminder enabled: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setReminderOffset(PrayerType type, int minutes) async {
    CoreLoggingUtility.info(
      'PrayerSettingsScreen',
      '_setReminderOffset',
      'Setting reminder offset for ${type.englishName} to: $minutes minutes',
    );

    try {
      await ref.read(prayerSettingsProvider.notifier).setReminderOffset(type, minutes);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerSettingsScreen',
        '_setReminderOffset',
        'Failed to set reminder offset: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
