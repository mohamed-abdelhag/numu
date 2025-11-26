import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/enums/prayer_type.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_settings.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for managing prayer reminders.
/// Integrates with the notification system to schedule prayer-specific notifications.
class PrayerReminderService {
  static final PrayerReminderService _instance = PrayerReminderService._internal();
  factory PrayerReminderService() => _instance;
  PrayerReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Base notification ID for prayer reminders (to avoid conflicts with other notifications)
  /// Each prayer type gets a unique ID: baseId + prayerType.index
  static const int _basePrayerNotificationId = 100000;

  /// Android notification channel for prayer reminders
  static const String _prayerChannelId = 'prayer_reminders';
  static const String _prayerChannelName = 'Prayer Reminders';
  static const String _prayerChannelDescription = 'Notifications for Islamic prayer times';

  /// Initialize the prayer reminder service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Create Android notification channel for prayers
    const prayerChannel = AndroidNotificationChannel(
      _prayerChannelId,
      _prayerChannelName,
      description: _prayerChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(prayerChannel);

    _isInitialized = true;
    CoreLoggingUtility.info(
      'PrayerReminderService',
      'initialize',
      'Prayer reminder service initialized',
    );
  }


  /// Get the notification ID for a specific prayer type
  int _getNotificationId(PrayerType type) {
    return _basePrayerNotificationId + type.index;
  }

  /// Calculate the reminder time based on prayer time and offset
  /// Returns the prayer time minus the offset duration
  static DateTime calculateReminderTime(DateTime prayerTime, int offsetMinutes) {
    return prayerTime.subtract(Duration(minutes: offsetMinutes));
  }

  /// Schedule reminders for all prayers based on today's schedule
  /// Only schedules reminders for prayers that are enabled in settings
  Future<void> scheduleAllPrayerReminders(
    PrayerSchedule schedule,
    PrayerSettings settings,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    CoreLoggingUtility.info(
      'PrayerReminderService',
      'scheduleAllPrayerReminders',
      'Scheduling reminders for ${schedule.date}',
    );

    for (final prayerType in PrayerType.values) {
      if (settings.isReminderEnabled(prayerType)) {
        final prayerTime = schedule.getTimeForPrayer(prayerType);
        final offsetMinutes = settings.getReminderOffset(prayerType);
        await schedulePrayerReminder(prayerType, prayerTime, offsetMinutes);
      } else {
        // Cancel any existing reminder for disabled prayers
        await cancelPrayerReminder(prayerType);
      }
    }
  }

  /// Schedule a reminder for a specific prayer
  Future<void> schedulePrayerReminder(
    PrayerType prayerType,
    DateTime prayerTime,
    int offsetMinutes,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    final reminderTime = calculateReminderTime(prayerTime, offsetMinutes);
    final now = DateTime.now();

    // Don't schedule if the reminder time has already passed
    if (reminderTime.isBefore(now)) {
      CoreLoggingUtility.info(
        'PrayerReminderService',
        'schedulePrayerReminder',
        'Skipping ${prayerType.englishName} reminder - time has passed',
      );
      return;
    }

    final notificationId = _getNotificationId(prayerType);
    final title = '${prayerType.englishName} Prayer';
    final body = _buildReminderBody(prayerType, prayerTime, offsetMinutes);
    final payload = 'prayer:${prayerType.name}';

    // Convert to timezone-aware datetime
    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      _prayerChannelId,
      _prayerChannelName,
      channelDescription: _prayerChannelDescription,
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

    try {
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

      CoreLoggingUtility.info(
        'PrayerReminderService',
        'schedulePrayerReminder',
        'Scheduled ${prayerType.englishName} reminder for $reminderTime',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerReminderService',
        'schedulePrayerReminder',
        'Failed to schedule ${prayerType.englishName} reminder: $e',
      );
    }
  }

  /// Build the notification body text
  String _buildReminderBody(PrayerType prayerType, DateTime prayerTime, int offsetMinutes) {
    final timeStr = _formatTime(prayerTime);
    if (offsetMinutes > 0) {
      return '${prayerType.arabicName} prayer time is at $timeStr ($offsetMinutes min)';
    }
    return '${prayerType.arabicName} prayer time is now at $timeStr';
  }

  /// Format time as HH:MM AM/PM
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }


  /// Update reminder for a specific prayer when prayer time changes
  Future<void> updatePrayerReminder(
    PrayerType prayerType,
    DateTime prayerTime,
    int offsetMinutes,
    bool isEnabled,
  ) async {
    if (!isEnabled) {
      await cancelPrayerReminder(prayerType);
      return;
    }

    // Cancel existing and reschedule with new time
    await cancelPrayerReminder(prayerType);
    await schedulePrayerReminder(prayerType, prayerTime, offsetMinutes);
  }

  /// Cancel reminder for a specific prayer
  Future<void> cancelPrayerReminder(PrayerType prayerType) async {
    final notificationId = _getNotificationId(prayerType);
    await _notificationsPlugin.cancel(notificationId);

    CoreLoggingUtility.info(
      'PrayerReminderService',
      'cancelPrayerReminder',
      'Cancelled ${prayerType.englishName} reminder',
    );
  }

  /// Cancel all prayer reminders
  Future<void> cancelAllPrayerReminders() async {
    for (final prayerType in PrayerType.values) {
      await cancelPrayerReminder(prayerType);
    }

    CoreLoggingUtility.info(
      'PrayerReminderService',
      'cancelAllPrayerReminders',
      'Cancelled all prayer reminders',
    );
  }

  /// Reschedule all prayer reminders when prayer times change
  /// (e.g., new day or location change)
  Future<void> rescheduleAllPrayerReminders(
    PrayerSchedule schedule,
    PrayerSettings settings,
  ) async {
    CoreLoggingUtility.info(
      'PrayerReminderService',
      'rescheduleAllPrayerReminders',
      'Rescheduling all prayer reminders',
    );

    // Cancel all existing reminders first
    await cancelAllPrayerReminders();

    // Schedule new reminders based on updated schedule
    await scheduleAllPrayerReminders(schedule, settings);
  }

  /// Get pending prayer notification requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingPrayerReminders() async {
    final allPending = await _notificationsPlugin.pendingNotificationRequests();
    return allPending.where((notification) {
      return notification.id >= _basePrayerNotificationId &&
          notification.id < _basePrayerNotificationId + PrayerType.values.length;
    }).toList();
  }

  /// Check if a specific prayer reminder is scheduled
  Future<bool> isPrayerReminderScheduled(PrayerType prayerType) async {
    final notificationId = _getNotificationId(prayerType);
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.any((notification) => notification.id == notificationId);
  }

  /// Get reminder settings for a specific prayer from PrayerSettings
  PrayerReminderSettings getReminderSettings(
    PrayerType prayerType,
    PrayerSettings settings,
  ) {
    return PrayerReminderSettings(
      prayerType: prayerType,
      isEnabled: settings.isReminderEnabled(prayerType),
      offsetMinutes: settings.getReminderOffset(prayerType),
    );
  }
}

/// Simple data class for prayer reminder settings
class PrayerReminderSettings {
  final PrayerType prayerType;
  final bool isEnabled;
  final int offsetMinutes;

  const PrayerReminderSettings({
    required this.prayerType,
    required this.isEnabled,
    required this.offsetMinutes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerReminderSettings &&
        other.prayerType == prayerType &&
        other.isEnabled == isEnabled &&
        other.offsetMinutes == offsetMinutes;
  }

  @override
  int get hashCode => Object.hash(prayerType, isEnabled, offsetMinutes);

  @override
  String toString() {
    return 'PrayerReminderSettings(prayerType: $prayerType, isEnabled: $isEnabled, offsetMinutes: $offsetMinutes)';
  }
}
