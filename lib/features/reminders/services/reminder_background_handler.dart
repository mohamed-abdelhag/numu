import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/reminder_repository.dart';
import 'reminder_scheduler_service.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for handling background reminder tasks
/// 
/// This service manages:
/// - Marking one-time reminders as inactive after delivery
/// - Scheduling next occurrence for repeating reminders
/// - Detecting and handling timezone changes
/// - App lifecycle state changes
class ReminderBackgroundHandler {
  static final ReminderBackgroundHandler _instance = 
      ReminderBackgroundHandler._internal();
  factory ReminderBackgroundHandler() => _instance;
  ReminderBackgroundHandler._internal();

  final ReminderRepository _reminderRepository = ReminderRepository();
  late final ReminderSchedulerService _schedulerService;
  late final NotificationService _notificationService;
  late final AlarmService _alarmService;

  bool _isInitialized = false;
  String? _lastKnownTimezone;
  Timer? _timezoneCheckTimer;

  /// Initialize the background handler
  Future<void> initialize({
    ReminderSchedulerService? schedulerService,
    NotificationService? notificationService,
    AlarmService? alarmService,
  }) async {
    if (_isInitialized) return;

    _notificationService = notificationService ?? NotificationService();
    _alarmService = alarmService ?? AlarmService();
    _schedulerService = schedulerService ?? ReminderSchedulerService(
      reminderRepository: _reminderRepository,
      notificationService: _notificationService,
      alarmService: _alarmService,
    );

    // Set up notification delivery callback
    _notificationService.setOnNotificationDelivered(_handleNotificationDelivered);

    // Store current timezone
    _lastKnownTimezone = DateTime.now().timeZoneName;

    // Start timezone monitoring
    _startTimezoneMonitoring();

    _isInitialized = true;

    CoreLoggingUtility.info(
      'ReminderBackgroundHandler',
      'initialize',
      'Background handler initialized with timezone: $_lastKnownTimezone',
    );
  }

  /// Handle notification delivery
  /// 
  /// Called when a notification is delivered to mark one-time reminders
  /// as inactive and schedule next occurrence for repeating reminders
  Future<void> _handleNotificationDelivered(int reminderId) async {
    try {
      CoreLoggingUtility.info(
        'ReminderBackgroundHandler',
        '_handleNotificationDelivered',
        'Handling notification delivery for reminder ID: $reminderId',
      );

      final reminder = await _reminderRepository.getReminderById(reminderId);
      if (reminder == null) {
        CoreLoggingUtility.warning(
          'ReminderBackgroundHandler',
          '_handleNotificationDelivered',
          'Reminder not found: $reminderId',
        );
        return;
      }

      // Mark one-time reminders as inactive
      await _schedulerService.markOneTimeReminderAsInactive(reminderId);

      // Schedule next occurrence for repeating reminders
      await _schedulerService.scheduleNextOccurrence(reminderId);

      CoreLoggingUtility.info(
        'ReminderBackgroundHandler',
        '_handleNotificationDelivered',
        'Successfully processed notification delivery for reminder: ${reminder.title}',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ReminderBackgroundHandler',
        '_handleNotificationDelivered',
        'Failed to handle notification delivery for reminder $reminderId: $e\n$stackTrace',
      );
    }
  }

  /// Start monitoring for timezone changes
  void _startTimezoneMonitoring() {
    // Check timezone every 5 minutes
    _timezoneCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkTimezoneChange(),
    );

    CoreLoggingUtility.info(
      'ReminderBackgroundHandler',
      '_startTimezoneMonitoring',
      'Started timezone monitoring',
    );
  }

  /// Check if timezone has changed and reschedule reminders if needed
  Future<void> _checkTimezoneChange() async {
    final currentTimezone = DateTime.now().timeZoneName;

    if (currentTimezone != _lastKnownTimezone) {
      CoreLoggingUtility.info(
        'ReminderBackgroundHandler',
        '_checkTimezoneChange',
        'Timezone changed from $_lastKnownTimezone to $currentTimezone',
      );

      _lastKnownTimezone = currentTimezone;

      // Reschedule all reminders with new timezone
      await handleTimezoneChange();
    }
  }

  /// Handle timezone change by rescheduling all active reminders
  Future<void> handleTimezoneChange() async {
    try {
      CoreLoggingUtility.info(
        'ReminderBackgroundHandler',
        'handleTimezoneChange',
        'Rescheduling all reminders due to timezone change',
      );

      await _schedulerService.rescheduleAllReminders();

      CoreLoggingUtility.info(
        'ReminderBackgroundHandler',
        'handleTimezoneChange',
        'Successfully rescheduled all reminders',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ReminderBackgroundHandler',
        'handleTimezoneChange',
        'Failed to reschedule reminders after timezone change: $e\n$stackTrace',
      );
    }
  }

  /// Handle app lifecycle state changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    CoreLoggingUtility.info(
      'ReminderBackgroundHandler',
      'handleAppLifecycleChange',
      'App lifecycle state changed to: $state',
    );

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check for timezone changes
        await _checkTimezoneChange();
        break;
      
      case AppLifecycleState.paused:
        // App going to background - nothing to do
        break;
      
      case AppLifecycleState.inactive:
        // App is inactive - nothing to do
        break;
      
      case AppLifecycleState.detached:
        // App is detached - nothing to do
        break;
      
      case AppLifecycleState.hidden:
        // App is hidden - nothing to do
        break;
    }
  }

  /// Manually trigger a check for timezone changes
  Future<void> checkTimezone() async {
    await _checkTimezoneChange();
  }

  /// Dispose resources
  void dispose() {
    _timezoneCheckTimer?.cancel();
    _timezoneCheckTimer = null;
    _isInitialized = false;

    CoreLoggingUtility.info(
      'ReminderBackgroundHandler',
      'dispose',
      'Background handler disposed',
    );
  }
}
