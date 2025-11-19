# Implementation Plan

- [x] 1. Set up project structure and dependencies
  - Create `lib/features/reminders/` folder structure with models, repositories, services, providers, screens, and widgets subfolders
  - Add required dependencies to `pubspec.yaml`: `flutter_local_notifications: ^17.0.0`, `timezone: ^0.9.0`, `permission_handler: ^11.0.0`
  - Run `flutter pub get` to install dependencies
  - _Requirements: 16.1, 16.2, 16.3_

- [x] 2. Create data models
  - Create `lib/features/reminders/models/reminder_type.dart` with enum for notification and fullScreenAlarm types
  - Create `lib/features/reminders/models/reminder_schedule.dart` with ScheduleFrequency enum and ReminderSchedule class containing frequency, date/time fields, active weekdays, and habit/task integration flags
  - Create `lib/features/reminders/models/reminder_link.dart` with LinkType enum and ReminderLink class for habit/task associations
  - Create `lib/features/reminders/models/reminder.dart` with complete Reminder model including all fields from design (id, title, description, type, schedule, link, isActive, timestamps, nextTriggerTime)
  - Add toMap() and fromMap() methods for database serialization in all models
  - _Requirements: 1.3, 2.1, 3.1, 4.1, 13.1_

- [x] 3. Implement database schema and repository
  - Update `lib/core/services/database_service.dart` to add reminders table constant and migration to version 9
  - Create reminders table with all fields from design: reminder_id, title, description, reminder_type, schedule fields (frequency, specific_date_time, time_of_day, active_weekdays, day_of_month, minutes_before, use_habit_time_window, use_habit_active_days), link fields (link_type, link_entity_id, link_entity_name, use_default_text), state fields (is_active, next_trigger_time), and metadata (created_at, updated_at)
  - Create indexes: idx_reminders_active, idx_reminders_next_trigger, idx_reminders_habit_link
  - Create `lib/features/reminders/repositories/reminder_repository.dart` with all CRUD methods: createReminder, getReminderById, getAllReminders, getActiveReminders, getRemindersByHabitId, getRemindersByTaskId, updateReminder, deleteReminder, deleteRemindersByHabitId, deleteRemindersByTaskId, updateNextTriggerTime
  - _Requirements: 1.5, 9.2, 9.4, 12.1_

- [x] 4. Implement notification service
  - Create `lib/features/reminders/services/notification_service.dart` with flutter_local_notifications integration
  - Implement initialize() method to set up notification channels for Android and iOS
  - Implement requestPermissions() method to request notification permissions from the device
  - Implement showNotification() method to display immediate notifications
  - Implement scheduleNotification() method to schedule future notifications with timezone support
  - Implement cancelNotification() and cancelAllNotifications() methods
  - Configure Android notification channels with appropriate importance levels
  - Configure iOS notification categories and authorization options
  - Handle notification tap actions to navigate to linked entities
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 5. Implement alarm service
  - Create `lib/features/reminders/services/alarm_service.dart` for full-screen alarm functionality
  - Implement initialize() method to set up alarm capabilities
  - Implement showAlarm() method to display full-screen alarm interface
  - Implement scheduleAlarm() method to schedule future alarms
  - Implement cancelAlarm() and dismissAlarm() methods
  - Configure alarm to wake screen, play sound, and require explicit dismissal
  - _Requirements: 13.2, 13.3, 13.4, 13.5_

- [-] 6. Implement reminder scheduler service
  - Create `lib/features/reminders/services/reminder_scheduler_service.dart` with scheduling logic
  - Implement calculateNextTriggerTime() method with logic for one-time, daily, weekly, and monthly reminders
  - Implement scheduleReminder() method to delegate to NotificationService or AlarmService based on reminder type
  - Implement rescheduleReminder() method to update existing scheduled reminders
  - Implement rescheduleAllReminders() method for app launch initialization
  - Implement handleHabitUpdate() method to recalculate habit-linked reminder trigger times when habit time windows or active days change
  - Implement handleTaskUpdate() method to recalculate task-linked reminder trigger times when task due dates change
  - Add logic to handle habit time window integration (use timeWindowStart minus minutesBefore)
  - Add logic to handle habit active days integration (only trigger on habit's active weekdays)
  - Add logic to handle task due date offsets (task.dueDate minus minutesBefore)
  - _Requirements: 2.3, 2.4, 3.2, 3.3, 3.5, 5.3, 5.4, 6.3, 6.4, 10.2, 10.3, 10.4, 10.5, 18.3, 19.3, 20.3_

- [ ] 7. Create Riverpod providers
  - Create `lib/features/reminders/providers/reminder_provider.dart` using riverpod_annotation
  - Implement ReminderNotifier class extending AsyncNotifier with state management for reminder list
  - Implement createReminder() method to create reminder in repository and schedule via scheduler service
  - Implement updateReminder() method to update reminder in repository and reschedule
  - Implement deleteReminder() method to delete from repository and cancel scheduled notifications
  - Implement toggleReminderActive() method to enable/disable reminders
  - Implement refresh() method to reload reminders from database
  - Create activeRemindersProvider to filter only active reminders
  - Create habitRemindersProvider(habitId) family provider for habit-specific reminders
  - Create taskRemindersProvider(taskId) family provider for task-specific reminders
  - Run `dart run build_runner build` to generate provider code
  - _Requirements: 1.5, 8.4, 9.2, 9.3_

- [ ] 8. Build reminder list screen
  - Create `lib/features/reminders/screens/reminder_list_screen.dart` as main reminders interface
  - Display list of all reminders using ListView with reminder list items
  - Show visual distinction between notification and alarm types using icons
  - Display next trigger time for each reminder
  - Add quick toggle switch for active/inactive state
  - Implement swipe actions for edit and delete
  - Add floating action button to navigate to create reminder screen
  - Show empty state widget when no reminders exist with helpful message
  - Add filter options to show all/active/inactive reminders
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 9. Build create reminder screen
  - Create `lib/features/reminders/screens/create_reminder_screen.dart` with form for new reminders
  - Add title text input field (required)
  - Add description text area (optional)
  - Add reminder type selector widget for notification vs full-screen alarm
  - Add link selector with options: standalone, link to habit, link to task
  - Add habit picker dropdown when habit link is selected
  - Add task picker dropdown when task link is selected
  - Add frequency selector with options: one-time, daily, weekly, monthly
  - Add date/time pickers that adapt based on selected frequency
  - Add weekday selector for weekly reminders
  - Add day of month selector for monthly reminders
  - Add "use habit time window" checkbox when habit is linked and has time window
  - Add "use habit active days" checkbox when habit is linked
  - Add "minutes before" input for task reminders and habit time window reminders
  - Add text configuration for habit-linked reminders: radio buttons for "Do [Habit Name]" vs custom text
  - Add custom text input field when custom text option is selected
  - Implement form validation: title required, valid date/time, task must have due date for task reminders, habit must have time window for time window reminders
  - Add save button that creates reminder via provider and navigates back
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 3.1, 3.2, 3.4, 4.2, 4.3, 5.1, 5.2, 6.1, 6.2, 10.1, 18.1, 18.2, 19.1, 19.2, 20.1, 20.2_

- [ ] 10. Build edit reminder screen
  - Create `lib/features/reminders/screens/edit_reminder_screen.dart` similar to create screen
  - Pre-fill all form fields with existing reminder data
  - Allow modification of all reminder properties
  - Add delete button to remove reminder
  - Add cancel button to discard changes
  - Add update button to save changes via provider
  - Implement same validation as create screen
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 11. Create reminder list item widget
  - Create `lib/features/reminders/widgets/reminder_list_item.dart` for displaying individual reminders
  - Show icon indicating type: bell icon for notification, alarm clock icon for full-screen alarm
  - Display title and description
  - Show linked entity badge if reminder is linked to habit or task
  - Display next trigger time in human-readable format
  - Add active/inactive toggle switch
  - Make item tappable to navigate to edit screen
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 12. Create reminder type selector widget
  - Create `lib/features/reminders/widgets/reminder_type_selector.dart` for type selection
  - Display radio button group with notification and full-screen alarm options
  - Show icon and description for each type
  - Handle selection state changes
  - _Requirements: 13.1_

- [ ] 13. Create reminder schedule picker widget
  - Create `lib/features/reminders/widgets/reminder_schedule_picker.dart` for schedule configuration
  - Add frequency dropdown with options: None, Daily, Weekly, Monthly
  - Show conditional date/time pickers based on selected frequency
  - Add weekday selector for weekly frequency
  - Add day of month selector for monthly frequency
  - Add minutes before input for offset-based reminders
  - Add checkboxes for habit configuration options when applicable
  - Handle state changes and validation
  - _Requirements: 5.1, 5.2, 6.1, 6.2, 10.1_

- [ ] 14. Create full-screen alarm dialog widget
  - Create `lib/features/reminders/widgets/full_screen_alarm_dialog.dart` for alarm display
  - Design full-screen overlay with large alarm icon
  - Display reminder title and description prominently
  - Show current time
  - Add prominent dismiss button
  - Prevent dismissal by back button (require explicit dismiss action)
  - Integrate with alarm service for sound playback
  - _Requirements: 13.3, 13.4, 13.5_

- [ ] 15. Configure iOS platform for notifications and alarms
  - Update `ios/Runner/Info.plist` to add UIBackgroundModes with remote-notification
  - Add NSUserNotificationsUsageDescription with permission explanation text
  - Update `ios/Runner/AppDelegate.swift` to configure notification categories and handle notification responses
  - Open Xcode project and enable "Background Modes" capability
  - Enable "Remote notifications" background mode in Xcode
  - _Requirements: 14.1, 14.3, 14.5_

- [ ] 16. Configure Android platform for notifications and alarms
  - Update `android/app/src/main/AndroidManifest.xml` to add permissions: POST_NOTIFICATIONS, VIBRATE, WAKE_LOCK, USE_FULL_SCREEN_INTENT, SCHEDULE_EXACT_ALARM
  - Add notification receivers in AndroidManifest.xml: ScheduledNotificationReceiver and ScheduledNotificationBootReceiver with BOOT_COMPLETED intent filter
  - Update `android/app/src/main/kotlin/MainActivity.kt` to configure notification channels and handle notification intents
  - Ensure `android/app/build.gradle.kts` has compileSdk >= 33 for notification permissions
  - _Requirements: 14.2, 14.4_

- [ ] 17. Integrate reminders with navigation system
  - Update `lib/core/providers/navigation_provider.dart` to add reminders navigation item to _defaultItems list
  - Set reminders item properties: id='reminders', label='Reminders', icon=Icons.notifications, route='/reminders', order=4 (before settings)
  - Update `lib/app/router/router.dart` to add reminders route in ShellRoute
  - Map '/reminders' route to ReminderListScreen
  - Add nested routes for create and edit reminder screens
  - _Requirements: 17.1, 17.2, 17.3, 17.5_

- [ ] 18. Integrate reminders with habits feature
  - Update habit detail screen to add "Add Reminder" button
  - Implement navigation from habit detail to create reminder screen with habit pre-selected
  - Update habit repository delete method to call reminder repository deleteRemindersByHabitId on habit deletion
  - Add listener in reminder scheduler service to detect habit updates and call handleHabitUpdate
  - _Requirements: 2.3, 2.4, 3.3, 5.3, 6.3, 18.3, 19.3_

- [ ] 19. Integrate reminders with tasks feature
  - Update task creation/edit screens to add reminder section with toggle, offset dropdown, and enable/disable option
  - Save reminder when task is saved if reminder is enabled
  - Update task repository delete method to call reminder repository deleteRemindersByTaskId on task deletion
  - Add listener in reminder scheduler service to detect task due date updates and call handleTaskUpdate
  - Disable reminders when task is marked complete, re-enable when marked incomplete
  - _Requirements: 2.3, 2.4, 20.2, 20.3, 20.4, 20.5_

- [ ] 20. Implement app initialization and background handling
  - Update app initialization in main.dart to initialize notification service and alarm service
  - Call rescheduleAllReminders() on app launch to refresh notification queue
  - Implement time zone change detection and trigger rescheduleAllReminders()
  - Handle notification tap actions to navigate to correct screen based on linked entity
  - Implement logic to mark one-time reminders as inactive after they trigger
  - _Requirements: 11.5, 12.2, 12.3, 12.4, 12.5_

- [ ] 21. Create documentation for real device testing
  - Create `DOCs/reminders/` folder
  - Create `DOCs/reminders/reminder_implementation_guide.md` with architecture overview and implementation details
  - Create `DOCs/reminders/real_device_testing.md` with iOS and Android testing instructions
  - Document prerequisites: Xcode, Android Studio, physical devices
  - Add step-by-step iOS testing instructions including build, deploy, and test scenarios
  - Add step-by-step Android testing instructions including build, install, and test scenarios
  - Document common issues and troubleshooting steps
  - Document platform-specific limitations (iOS: 64 notification limit, Android: unlimited)
  - Add test scenarios: background delivery, app closed delivery, full-screen alarms, notification tap navigation, repeating reminders, time zone changes, device restart persistence
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ] 22. Write unit tests for core functionality
  - Write tests for reminder model serialization and deserialization
  - Write tests for reminder repository CRUD operations with mock database
  - Write tests for reminder scheduler service trigger time calculations for all frequency types
  - Write tests for habit and task integration logic in scheduler service
  - Mock platform notification APIs for service tests
  - _Requirements: 2.3, 3.3, 5.4, 6.4, 10.2, 10.3, 10.4, 10.5_

- [ ] 23. Write integration tests for end-to-end flows
  - Write test for creating standalone reminder and verifying database entry and scheduling
  - Write test for creating habit-linked reminder and verifying it inherits habit configuration
  - Write test for updating habit time window and verifying reminders are rescheduled
  - Write test for deleting task and verifying reminders are cascade deleted
  - Write test for app restart and verifying reminders are rescheduled
  - _Requirements: 2.4, 3.3, 9.4, 12.2, 12.3_
