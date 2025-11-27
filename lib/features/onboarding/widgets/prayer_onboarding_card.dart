import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../islamic/providers/prayer_settings_provider.dart';
import '../../islamic/services/prayer_location_service.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Interactive onboarding card for the Islamic Prayer System.
/// Allows users to enable/disable prayer tracking and handles location permission.
///
/// **Validates: Requirements 10.1, 10.2, 10.3**
class PrayerOnboardingCard extends ConsumerStatefulWidget {
  const PrayerOnboardingCard({super.key});

  @override
  ConsumerState<PrayerOnboardingCard> createState() =>
      _PrayerOnboardingCardState();
}

class _PrayerOnboardingCardState extends ConsumerState<PrayerOnboardingCard> {
  bool _isEnabled = false;
  bool _isRequestingPermission = false;
  bool _hasLocationPermission = false;
  String? _permissionMessage;

  final PrayerLocationService _locationService = PrayerLocationService();

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Check if prayer system is already enabled
    final settingsAsync = ref.read(prayerSettingsProvider);
    settingsAsync.whenData((settings) {
      if (mounted) {
        setState(() {
          _isEnabled = settings.isEnabled;
        });
      }
    });

    // Check current location permission status
    final hasPermission = await _locationService.hasLocationPermission();
    if (mounted) {
      setState(() {
        _hasLocationPermission = hasPermission;
      });
    }
  }

  Future<void> _onToggleChanged(bool value) async {
    setState(() {
      _isEnabled = value;
      _permissionMessage = null;
    });

    if (value) {
      // User wants to enable prayer tracking
      await _handleEnablePrayer();
    } else {
      // User wants to disable prayer tracking
      await _handleDisablePrayer();
    }
  }

  /// Handle enabling the Islamic Prayer System.
  /// Requests location permission with explanation.
  ///
  /// **Validates: Requirements 10.2**
  Future<void> _handleEnablePrayer() async {
    CoreLoggingUtility.info(
      'PrayerOnboardingCard',
      '_handleEnablePrayer',
      'User enabled prayer tracking in onboarding',
    );

    // Check if we already have location permission
    if (_hasLocationPermission) {
      await _enablePrayerSystem();
      return;
    }

    // Request location permission
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final granted = await _locationService.requestLocationPermission();

      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
          _hasLocationPermission = granted;
        });

        if (granted) {
          await _enablePrayerSystem();
          setState(() {
            _permissionMessage = 'Location permission granted. Prayer times will be calculated for your location.';
          });
        } else {
          // Permission denied - check if permanently denied
          final isPermanentlyDenied =
              await _locationService.isLocationPermissionPermanentlyDenied();

          setState(() {
            _isEnabled = false; // Revert toggle
            if (isPermanentlyDenied) {
              _permissionMessage =
                  'Location permission is required for accurate prayer times. Please enable it in your device settings.';
            } else {
              _permissionMessage =
                  'Location permission is needed to calculate prayer times for your area. You can enable this later in Settings.';
            }
          });

          CoreLoggingUtility.info(
            'PrayerOnboardingCard',
            '_handleEnablePrayer',
            'Location permission denied, prayer system not enabled',
          );
        }
      }
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerOnboardingCard',
        '_handleEnablePrayer',
        'Error requesting location permission: $e',
      );

      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
          _isEnabled = false;
          _permissionMessage =
              'Unable to request location permission. You can enable prayer tracking later in Settings.';
        });
      }
    }
  }

  Future<void> _enablePrayerSystem() async {
    try {
      await ref.read(prayerSettingsProvider.notifier).setEnabled(true);

      CoreLoggingUtility.info(
        'PrayerOnboardingCard',
        '_enablePrayerSystem',
        'Prayer system enabled successfully',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerOnboardingCard',
        '_enablePrayerSystem',
        'Failed to enable prayer system: $e',
      );

      if (mounted) {
        setState(() {
          _isEnabled = false;
          _permissionMessage =
              'Unable to enable prayer tracking. Please try again later in Settings.';
        });
      }
    }
  }

  /// Handle disabling the Islamic Prayer System.
  ///
  /// **Validates: Requirements 10.3**
  Future<void> _handleDisablePrayer() async {
    CoreLoggingUtility.info(
      'PrayerOnboardingCard',
      '_handleDisablePrayer',
      'User disabled prayer tracking in onboarding',
    );

    try {
      await ref.read(prayerSettingsProvider.notifier).setEnabled(false);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerOnboardingCard',
        '_handleDisablePrayer',
        'Failed to disable prayer system: $e',
      );
    }
  }

  Future<void> _openSettings() async {
    await _locationService.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mosque_outlined,
              size: 80,
              color: theme.primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Islamic Prayer Tracking',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            'Track your five daily prayers (Salah) with automatic prayer time calculations based on your location.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Features list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem(
                  icon: Icons.access_time,
                  text: 'Accurate prayer times for your location',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.trending_up,
                  text: 'Track your prayer consistency and streaks',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.notifications_outlined,
                  text: 'Get reminders before each prayer',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: Icons.groups_outlined,
                  text: 'Log congregation (Jamaah) prayers',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Toggle switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Prayer Tracking',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requires location permission',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isRequestingPermission)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _isEnabled,
                    onChanged: _onToggleChanged,
                  ),
              ],
            ),
          ),

          // Permission message
          if (_permissionMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasLocationPermission
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasLocationPermission
                      ? Colors.green[200]!
                      : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasLocationPermission
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: _hasLocationPermission
                        ? Colors.green[700]
                        : Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _permissionMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _hasLocationPermission
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Show settings button if permission was denied
            if (!_hasLocationPermission && !_isEnabled) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open Settings'),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // Skip note
          Text(
            'You can always enable or disable this feature later in Settings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
