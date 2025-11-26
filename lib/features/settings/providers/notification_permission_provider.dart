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
@Riverpod(keepAlive: true)
class NotificationPermission extends _$NotificationPermission {
  @override
  Future<NotificationPermissionStatus> build() async {
    return await _checkPermissionStatus();
  }

  /// Check the current notification permission status
  Future<NotificationPermissionStatus> _checkPermissionStatus() async {
    try {
      CoreLoggingUtility.info(
        'NotificationPermission',
        '_checkPermissionStatus',
        'Checking notification permission status',
      );

      // First check using NotificationService
      final notificationService = NotificationService();
      final isEnabled = await notificationService.areNotificationsEnabled();

      if (isEnabled) {
        CoreLoggingUtility.info(
          'NotificationPermission',
          '_checkPermissionStatus',
          'Notifications are enabled',
        );
        return NotificationPermissionStatus.granted;
      }

      // If not enabled, check the detailed permission status
      final status = await Permission.notification.status;

      CoreLoggingUtility.info(
        'NotificationPermission',
        '_checkPermissionStatus',
        'Permission status: $status',
      );

      if (status.isPermanentlyDenied) {
        return NotificationPermissionStatus.permanentlyDenied;
      } else if (status.isDenied) {
        return NotificationPermissionStatus.denied;
      } else if (status.isGranted) {
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
  Future<bool> requestPermissions() async {
    try {
      CoreLoggingUtility.info(
        'NotificationPermission',
        'requestPermissions',
        'Requesting notification permissions',
      );

      final notificationService = NotificationService();
      final granted = await notificationService.requestPermissions();

      CoreLoggingUtility.info(
        'NotificationPermission',
        'requestPermissions',
        'Permission request result: $granted',
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
      return false;
    }
  }

  /// Open app settings for the user to manually enable permissions
  Future<bool> openSettings() async {
    try {
      CoreLoggingUtility.info(
        'NotificationPermission',
        'openSettings',
        'Opening app settings',
      );

      final opened = await openAppSettings();

      CoreLoggingUtility.info(
        'NotificationPermission',
        'openSettings',
        'App settings opened: $opened',
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
  Future<void> refresh() async {
    CoreLoggingUtility.info(
      'NotificationPermission',
      'refresh',
      'Refreshing permission status',
    );

    state = const AsyncValue.loading();
    state = AsyncValue.data(await _checkPermissionStatus());
  }
}
