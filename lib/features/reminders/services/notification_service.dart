import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/reminder.dart';
import '../models/reminder_link.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service with platform-specific settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for notification tap actions
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    await _createAndroidNotificationChannels();

    _isInitialized = true;
  }

  /// Create Android notification channels with appropriate importance levels
  Future<void> _createAndroidNotificationChannels() async {
    // High importance channel for reminders
    const reminderChannel = AndroidNotificationChannel(
      'reminders_high',
      'Reminders',
      description: 'Notifications for habit and task reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Default channel for general notifications
    const defaultChannel = AndroidNotificationChannel(
      'reminders_default',
      'General Reminders',
      description: 'General reminder notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);
  }

  /// Request notification permissions from the device
  Future<bool> requestPermissions() async {
    // Request iOS permissions
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) return false;
    }

    // Request Android permissions (Android 13+)
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted != true) {
        // Fallback to permission_handler for older Android versions
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    }

    return true;
  }

  /// Display an immediate notification
  Future<void> showNotification(Reminder reminder) async {
    if (!_isInitialized) {
      await initialize();
    }

    final notificationId = reminder.id ?? DateTime.now().millisecondsSinceEpoch;
    final title = _buildNotificationTitle(reminder);
    final body = _buildNotificationBody(reminder);
    final payload = _buildNotificationPayload(reminder);

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'reminders_high',
      'Reminders',
      channelDescription: 'Notifications for habit and task reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule a notification for a future time with timezone support
  Future<void> scheduleNotification(
    Reminder reminder,
    DateTime triggerTime,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    final notificationId = reminder.id ?? DateTime.now().millisecondsSinceEpoch;
    final title = _buildNotificationTitle(reminder);
    final body = _buildNotificationBody(reminder);
    final payload = _buildNotificationPayload(reminder);

    // Convert to timezone-aware datetime
    final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'reminders_high',
      'Reminders',
      channelDescription: 'Notifications for habit and task reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel a specific scheduled notification
  Future<void> cancelNotification(int reminderId) async {
    await _notificationsPlugin.cancel(reminderId);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Build notification title based on reminder configuration
  String _buildNotificationTitle(Reminder reminder) {
    if (reminder.link != null) {
      final link = reminder.link!;
      if (link.useDefaultText) {
        return 'Do ${link.entityName}';
      }
    }
    return reminder.title;
  }

  /// Build notification body
  String _buildNotificationBody(Reminder reminder) {
    if (reminder.description != null && reminder.description!.isNotEmpty) {
      return reminder.description!;
    }

    // Provide context based on link type
    if (reminder.link != null) {
      final link = reminder.link!;
      switch (link.type) {
        case LinkType.habit:
          return 'Time to work on your habit';
        case LinkType.task:
          return 'Task reminder';
      }
    }

    return 'Reminder';
  }

  /// Build notification payload for navigation
  String _buildNotificationPayload(Reminder reminder) {
    if (reminder.link != null) {
      final link = reminder.link!;
      return '${link.type.name}:${link.entityId}';
    }
    return 'reminder:${reminder.id ?? 0}';
  }

  /// Handle notification tap actions
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Parse payload to determine navigation target
    final parts = payload.split(':');
    if (parts.length != 2) return;

    final type = parts[0];
    final entityId = int.tryParse(parts[1]);
    if (entityId == null) return;

    // Navigate to linked entity
    // Note: Navigation will be handled by the app's router
    // This is a placeholder for the navigation logic
    _navigateToEntity(type, entityId);
  }

  /// Navigate to the linked entity (habit or task)
  void _navigateToEntity(String type, int entityId) {
    // This method will be implemented when integrating with the app's navigation
    // For now, it's a placeholder that can be called from the app's main navigation handler
    // The actual navigation will be handled by go_router based on the payload
    
    // Example implementation:
    // switch (type) {
    //   case 'habit':
    //     router.go('/habits/$entityId');
    //     break;
    //   case 'task':
    //     router.go('/tasks/$entityId');
    //     break;
    //   case 'reminder':
    //     router.go('/reminders');
    //     break;
    // }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final enabled = await androidImplementation.areNotificationsEnabled();
      return enabled ?? false;
    }

    // Check iOS
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final settings = await iosImplementation.requestPermissions(
        alert: false,
        badge: false,
        sound: false,
      );
      return settings ?? false;
    }

    return false;
  }

  /// Get pending notification requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
