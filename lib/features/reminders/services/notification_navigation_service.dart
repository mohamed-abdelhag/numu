import 'package:go_router/go_router.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for handling navigation from notification taps
/// 
/// This service provides a centralized way to navigate to different screens
/// when users tap on notifications or alarms.
class NotificationNavigationService {
  static final NotificationNavigationService _instance = 
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  GoRouter? _router;

  /// Initialize the navigation service with the app's router
  void initialize(GoRouter router) {
    _router = router;
    CoreLoggingUtility.info(
      'NotificationNavigationService',
      'initialize',
      'Navigation service initialized',
    );
  }

  /// Handle notification tap by parsing payload and navigating to appropriate screen
  /// 
  /// Payload format: "type:entityId" or "alarm:type:entityId:reminderId"
  /// Examples:
  /// - "habit:123" -> Navigate to habit detail screen
  /// - "task:456" -> Navigate to task detail screen
  /// - "reminder:789" -> Navigate to reminders list
  /// - "alarm:habit:123:789" -> Navigate to habit detail screen
  void handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      CoreLoggingUtility.warning(
        'NotificationNavigationService',
        'handleNotificationTap',
        'Received empty payload',
      );
      return;
    }

    if (_router == null) {
      CoreLoggingUtility.error(
        'NotificationNavigationService',
        'handleNotificationTap',
        'Router not initialized',
      );
      return;
    }

    try {
      final parts = payload.split(':');
      
      // Handle alarm payload format: "alarm:type:entityId:reminderId"
      if (parts[0] == 'alarm' && parts.length >= 4) {
        final type = parts[1];
        final entityId = int.tryParse(parts[2]);
        
        if (entityId != null) {
          _navigateToEntity(type, entityId);
        }
        return;
      }

      // Handle standard payload format: "type:entityId"
      if (parts.length >= 2) {
        final type = parts[0];
        final entityId = int.tryParse(parts[1]);
        
        if (entityId != null) {
          _navigateToEntity(type, entityId);
        }
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NotificationNavigationService',
        'handleNotificationTap',
        'Failed to parse payload "$payload": $e\n$stackTrace',
      );
    }
  }

  /// Navigate to the appropriate screen based on entity type
  void _navigateToEntity(String type, int entityId) {
    if (_router == null) return;

    try {
      switch (type) {
        case 'habit':
          _router!.go('/habits/$entityId');
          CoreLoggingUtility.info(
            'NotificationNavigationService',
            '_navigateToEntity',
            'Navigating to habit detail: $entityId',
          );
          break;
        
        case 'task':
          _router!.go('/tasks/$entityId');
          CoreLoggingUtility.info(
            'NotificationNavigationService',
            '_navigateToEntity',
            'Navigating to task detail: $entityId',
          );
          break;
        
        case 'reminder':
          _router!.go('/reminders');
          CoreLoggingUtility.info(
            'NotificationNavigationService',
            '_navigateToEntity',
            'Navigating to reminders list',
          );
          break;
        
        default:
          CoreLoggingUtility.warning(
            'NotificationNavigationService',
            '_navigateToEntity',
            'Unknown entity type: $type',
          );
          // Default to reminders list
          _router!.go('/reminders');
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NotificationNavigationService',
        '_navigateToEntity',
        'Failed to navigate to $type:$entityId: $e\n$stackTrace',
      );
    }
  }

  /// Navigate to a specific route
  void navigateTo(String route) {
    if (_router == null) {
      CoreLoggingUtility.error(
        'NotificationNavigationService',
        'navigateTo',
        'Router not initialized',
      );
      return;
    }

    try {
      _router!.go(route);
      CoreLoggingUtility.info(
        'NotificationNavigationService',
        'navigateTo',
        'Navigating to: $route',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NotificationNavigationService',
        'navigateTo',
        'Failed to navigate to $route: $e\n$stackTrace',
      );
    }
  }
}
