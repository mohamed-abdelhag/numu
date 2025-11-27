import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../reminders/services/notification_service.dart';

part 'notification_permission_provider.g.dart';

/// Enum representing the notification permission status
enum NotificationPermissionStatus {
  /// Notifications are enabled
  granted,
  /// Notifications are denied but can be requested
  denied,
  /// Notifications are permanently denied (user must go to settings)
  permanentlyDenied,
  /// Permission status is unknown or being checked
  unknown,
}

/// Provider for managing notification permission status
/// Works on both Android (13+) and iOS
@Riverpod(keepAlive: true)
class NotificationPermission extends _$NotificationPermission {
  @override
  Future<NotificationPermissionStatus> build() async {
    return await _checkPermissionStatus();
  }

  /// Check the current notification permission status
  /// Handles both Android and iOS platforms
  Future<NotificationPermissionStatus> _checkPermissionStatus() async {
    try {
      final platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown');
      
      CoreLoggingUtility.info(
        'NotificationPermission',
        '_checkPermissionStatus',
        'Checking notification permission status on $platform',
      );

      // First check using NotificationService (platform-specific implementation)
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      final isEnabled = await notificationService.areNotificationsEnabled();

      CoreLoggingUtility.info(
        'NotificationPermission',
        '_checkPermissionStatus',
        'NotificationService.areNotificationsEnabled() returned: $isEnabled on $platform',
      );

      if (isEnabled) {
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications are enabled on $platform',
        );
        return NotificationPermissionStatus.granted;
      }

      // If not enabled, check the detailed permission status using permission_handler
      // This works on both Android (13+) and iOS
      final status = await Permission.notification.status;

      CoreLoggingUtility.info(
        'NotificationPermission',
        '_checkPermissionStatus',
        'Permission.notification.status: $status on $platform',
      );

      if (status.isPermanentlyDenied) {
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications are permanently denied on $platform - user must go to settings',
        );
        return NotificationPermissionStatus.permanentlyDenied;
      } else if (status.isDenied) {
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications are denied but can be requested on $platform',
        );
        return NotificationPermissionStatus.denied;
      } else if (status.isGranted) {
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications permission is granted on $platform',
        );
        return NotificationPermissionStatus.granted;
      } else if (status.isRestricted) {
        // iOS specific: parental controls or device policy
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications are restricted (parental controls) on $platform',
        );
        return NotificationPermissionStatus.permanentlyDenied;
      } else if (status.isLimited) {
        // Limited permission state
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications have limited permission on $platform',
        );
        return NotificationPermissionStatus.granted;
      } else if (status.isProvisional) {
        // iOS provisional authorization
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications have provisional authorization on $platform',
        );
        return NotificationPermissionStatus.granted;
      }

      return NotificationPermissionStatus.unknown;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NotificationPermission',
        '_checkPermissionStatus',
        'Failed to check permission status: $e\nStack trace: $stackTrace',
      );
      return NotificationPermissionStatus.unknown;
    }
  }

  /// Request notification permissions
  /// Handles both Android (13+) and iOS permission flows
  Future<bool> requestPermissions() async {
    try {
      final platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown');
      
      CoreLoggingUtility.info(
        'NotificationPermission',
        'requestPermissions',
        'Requesting notification permissions on $platform',
      );

      final notificationService = NotificationService();
      await notificationService.initialize();
      
      final granted = await notificationService.requestPermissions();

      CoreLoggingUtility.info(
        'NotificationPermission',
        'requestPermissions',
        'Permission request result on $platform: $granted',
      );

      // Refresh the status after requesting
      await refresh();

      return granted;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NotificationPermission',
        'requestPermissions',
        'Failed to request permissions: $e\nStack trace: $stackTrace',
      );
      
      // Still try to refresh the status
      await refresh();
      
      return false;
    }
  }

  /// Open app settings for the user to manually enable permissions
  /// Works on both Android and iOS
  Future<bool> openSettings() async {
    try {
      final platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown');
      
      CoreLoggingUtility.info(
        'NotificationPermission',
        'openSettings',
        'Opening app settings on $platform',
      );

      final opened = await openAppSettings();

      CoreLoggingUtility.info(
        'NotificationPermission',
        'openSettings',
        'App settings opened on $platform: $opened',
      );

      // Schedule a refresh after user returns from settings
      // This gives time for the user to change settings and return
      Future.delayed(const Duration(seconds: 1), () {
        refresh();
      });

      return opened;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NotificationPermission',
        'openSettings',
        'Failed to open app settings: $e\nStack trace: $stackTrace',
      );
      return false;
    }
  }

  /// Refresh the permission status
  /// Call this after user returns from settings or after requesting permissions
  Future<void> refresh() async {
    final platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown');
    
    CoreLoggingUtility.info(
      'NotificationPermission',
      'refresh',
      'Refreshing permission status on $platform',
    );

    state = const AsyncValue.loading();
    state = AsyncValue.data(await _checkPermissionStatus());
    
    CoreLoggingUtility.info(
      'NotificationPermission',
      'refresh',
      'Permission status refreshed on $platform: ${state.value}',
    );
  }
}
