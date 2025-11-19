import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';
import '../models/reminder_link.dart';
import 'notification_navigation_service.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for managing full-screen alarms
/// 
/// This service handles intrusive full-screen alarms that require explicit
/// user dismissal. Alarms wake the screen, play sound, and display a
/// full-screen interface.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  
  // Callback for when alarm is triggered
  Function(Reminder)? _onAlarmTriggered;
  
  // Store active alarms for dismissal tracking
  final Map<int, Reminder> _activeAlarms = {};

  /// Initialize the alarm service with platform-specific settings
  Future<void> initialize({Function(Reminder)? onAlarmTriggered}) async {
    if (_isInitialized) return;

    _onAlarmTriggered = onAlarmTriggered;

    // Android initialization settings with full-screen intent
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: true, // For critical alarms on iOS
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for alarm tap actions
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onAlarmTapped,
    );

    // Create Android alarm notification channel
    await _createAndroidAlarmChannel();

    _isInitialized = true;
  }

  /// Create Android notification channel for alarms with full-screen intent
  Future<void> _createAndroidAlarmChannel() async {
    // Maximum importance channel for full-screen alarms
    const alarmChannel = AndroidNotificationChannel(
      'alarms_critical',
      'Alarms',
      description: 'Full-screen alarms for critical reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000),
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
  }

  /// Display a full-screen alarm immediately
  /// 
  /// This method shows an alarm notification that will trigger the full-screen
  /// alarm interface. The alarm requires explicit dismissal.
  Future<void> showAlarm(Reminder reminder) async {
    if (!_isInitialized) {
      await initialize();
    }

    final alarmId = reminder.id ?? DateTime.now().millisecondsSinceEpoch;
    final title = _buildAlarmTitle(reminder);
    final body = _buildAlarmBody(reminder);
    final payload = _buildAlarmPayload(reminder);

    // Store active alarm
    _activeAlarms[alarmId] = reminder;

    // Android notification details with full-screen intent
    final androidDetails = AndroidNotificationDetails(
      'alarms_critical',
      'Alarms',
      channelDescription: 'Full-screen alarms for critical reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      enableLights: true,
      ledColor: const Color(0xFFFF0000),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true, // Enable full-screen intent
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true, // Prevent swipe dismissal
      autoCancel: false, // Require explicit dismissal
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    // iOS notification details with critical alert
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.aiff',
      interruptionLevel: InterruptionLevel.critical,
      threadIdentifier: 'alarms',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      alarmId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    // Trigger callback to show full-screen UI
    if (_onAlarmTriggered != null) {
      _onAlarmTriggered!(reminder);
    }
  }

  /// Schedule a full-screen alarm for a future time
  /// 
  /// The alarm will trigger at the specified time with full-screen display,
  /// sound, and vibration.
  Future<void> scheduleAlarm(
    Reminder reminder,
    DateTime triggerTime,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    final alarmId = reminder.id ?? DateTime.now().millisecondsSinceEpoch;
    final title = _buildAlarmTitle(reminder);
    final body = _buildAlarmBody(reminder);
    final payload = _buildAlarmPayload(reminder);

    // Convert to timezone-aware datetime
    final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);

    // Android notification details with full-screen intent
    final androidDetails = AndroidNotificationDetails(
      'alarms_critical',
      'Alarms',
      channelDescription: 'Full-screen alarms for critical reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      enableLights: true,
      ledColor: const Color(0xFFFF0000),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
    );

    // iOS notification details with critical alert
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.aiff',
      interruptionLevel: InterruptionLevel.critical,
      threadIdentifier: 'alarms',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      alarmId,
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

  /// Cancel a scheduled alarm
  /// 
  /// Removes the alarm from the notification queue and prevents it from
  /// triggering.
  Future<void> cancelAlarm(int reminderId) async {
    await _notificationsPlugin.cancel(reminderId);
    _activeAlarms.remove(reminderId);
  }

  /// Dismiss an active alarm
  /// 
  /// This method is called when the user explicitly dismisses an alarm.
  /// It cancels the notification and removes it from active alarms.
  Future<void> dismissAlarm(int reminderId) async {
    await _notificationsPlugin.cancel(reminderId);
    _activeAlarms.remove(reminderId);
  }

  /// Cancel all scheduled alarms
  Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
    _activeAlarms.clear();
  }

  /// Get an active alarm by ID
  Reminder? getActiveAlarm(int reminderId) {
    return _activeAlarms[reminderId];
  }

  /// Check if an alarm is currently active
  bool isAlarmActive(int reminderId) {
    return _activeAlarms.containsKey(reminderId);
  }

  /// Get all active alarms
  List<Reminder> getActiveAlarms() {
    return _activeAlarms.values.toList();
  }

  /// Build alarm title based on reminder configuration
  String _buildAlarmTitle(Reminder reminder) {
    if (reminder.link != null) {
      final link = reminder.link!;
      if (link.useDefaultText) {
        return 'Do ${link.entityName}';
      }
    }
    return reminder.title;
  }

  /// Build alarm body
  String _buildAlarmBody(Reminder reminder) {
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

    return 'Alarm';
  }

  /// Build alarm payload for navigation
  String _buildAlarmPayload(Reminder reminder) {
    if (reminder.link != null) {
      final link = reminder.link!;
      return 'alarm:${link.type.name}:${link.entityId}:${reminder.id ?? 0}';
    }
    return 'alarm:reminder:0:${reminder.id ?? 0}';
  }

  /// Handle alarm tap actions
  void _onAlarmTapped(NotificationResponse response) {
    final payload = response.payload;
    
    CoreLoggingUtility.info(
      'AlarmService',
      '_onAlarmTapped',
      'Alarm tapped with payload: $payload',
    );

    if (payload == null || payload.isEmpty) return;

    // Parse payload to determine navigation target
    final parts = payload.split(':');
    if (parts.length < 4) {
      // Delegate to navigation service for standard format
      NotificationNavigationService().handleNotificationTap(payload);
      return;
    }

    final prefix = parts[0]; // 'alarm'
    // parts[1] is type: 'habit', 'task', or 'reminder'
    final entityId = int.tryParse(parts[2]);
    final reminderId = int.tryParse(parts[3]);

    if (prefix != 'alarm' || entityId == null || reminderId == null) return;

    // Get the reminder from active alarms
    final reminder = _activeAlarms[reminderId];
    
    // Trigger callback to show full-screen UI
    if (reminder != null && _onAlarmTriggered != null) {
      _onAlarmTriggered!(reminder);
    }

    // Delegate to navigation service
    NotificationNavigationService().handleNotificationTap(payload);
  }

  /// Request permissions for critical alarms (iOS)
  Future<bool> requestCriticalAlarmPermission() async {
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      return granted ?? false;
    }

    return true; // Android doesn't need special permission
  }

  /// Check if alarm permissions are granted
  Future<bool> areAlarmPermissionsGranted() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check Android exact alarm permission
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final canScheduleExactAlarms = 
          await androidImplementation.canScheduleExactNotifications();
      return canScheduleExactAlarms ?? false;
    }

    // Check iOS critical alert permission
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      // iOS doesn't provide a direct way to check critical permission
      // We'll assume it's granted if basic permissions are granted
      final settings = await iosImplementation.requestPermissions(
        alert: false,
        badge: false,
        sound: false,
        critical: false,
      );
      return settings ?? false;
    }

    return false;
  }

  /// Get pending alarm requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
