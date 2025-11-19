import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/app.dart';
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:numu/features/reminders/services/notification_service.dart';
import 'package:numu/features/reminders/services/alarm_service.dart';
import 'package:numu/features/reminders/services/reminder_scheduler_service.dart';
import 'package:numu/features/reminders/services/reminder_background_handler.dart';

void main() async {
  // ...no FFI initialization needed for mobile...
  WidgetsFlutterBinding.ensureInitialized();
  
  // Basic debug print to show app started before the shared logging utility
  debugPrint('Initializing the core logging utility');
  CoreLoggingUtility.init();
  CoreLoggingUtility.info('main dart file','initialised the logging utility','main starting app runApp');
  
  // Initialize timezone database for reminder scheduling
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(tz.local.name));
  CoreLoggingUtility.info('main dart file', 'timezone', 'Initialized timezone: ${tz.local.name}');
  
  // Initialize notification and alarm services
  final notificationService = NotificationService();
  final alarmService = AlarmService();
  
  try {
    await notificationService.initialize();
    CoreLoggingUtility.info('main dart file', 'notifications', 'Notification service initialized');
    
    await alarmService.initialize();
    CoreLoggingUtility.info('main dart file', 'alarms', 'Alarm service initialized');
    
    // Initialize scheduler service
    final schedulerService = ReminderSchedulerService(
      notificationService: notificationService,
      alarmService: alarmService,
    );
    
    // Initialize background handler for lifecycle and timezone management
    final backgroundHandler = ReminderBackgroundHandler();
    await backgroundHandler.initialize(
      schedulerService: schedulerService,
      notificationService: notificationService,
      alarmService: alarmService,
    );
    CoreLoggingUtility.info('main dart file', 'reminders', 'Background handler initialized');
    
    // Reschedule all active reminders on app launch
    await schedulerService.rescheduleAllReminders();
    CoreLoggingUtility.info('main dart file', 'reminders', 'All active reminders rescheduled');
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'main dart file',
      'reminder initialization',
      'Failed to initialize reminder services: $e\n$stackTrace',
    );
  }
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(sharedPreferences);
  
  // Ensure Flutter framework is fully initialized before starting app
  // This prevents navigation issues during app startup
  await Future.delayed(Duration.zero);
  CoreLoggingUtility.info('main dart file', 'initialization', 'All services initialized, starting app');
  
  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: const MyApp(),
    ),
  );
}

