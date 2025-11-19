# Reminder System Design Document

## Overview

The Reminder System is a standalone feature module that provides comprehensive notification and alarm capabilities for the Numu app. It supports two types of reminders: standard notifications and full-screen alarms. The system integrates with existing habits and tasks features while maintaining independence as a separate module. Users can create standalone reminders or link them to specific habits and tasks with intelligent scheduling based on habit time windows, active days, and task due dates.

### Key Features

- Two reminder types: notifications and full-screen alarms
- Standalone and linked reminders (habits/tasks)
- Flexible scheduling: one-time, daily, weekly, monthly
- Intelligent habit integration (time windows, active days)
- Task due date reminders with offset support
- Navigation panel integration
- Cross-platform support (iOS and Android)
- Persistent storage with automatic rescheduling

## Architecture

### Module Structure

The reminder system follows the existing project architecture pattern:

```
lib/features/reminders/
├── models/
│   ├── reminder.dart
│   ├── reminder_type.dart
│   ├── reminder_schedule.dart
│   └── reminder_link.dart
├── repositories/
│   └── reminder_repository.dart
├── services/
│   ├── notification_service.dart
│   ├── alarm_service.dart
│   └── reminder_scheduler_service.dart
├── providers/
│   ├── reminder_provider.dart
│   └── reminder_provider.g.dart
├── screens/
│   ├── reminder_list_screen.dart
│   ├── create_reminder_screen.dart
│   └── edit_reminder_screen.dart
└── widgets/
    ├── reminder_list_item.dart
    ├── reminder_type_selector.dart
    ├── reminder_schedule_picker.dart
    └── full_screen_alarm_dialog.dart
```

### Platform Configuration

```
ios/
├── Runner/
│   ├── Info.plist (notification permissions)
│   └── AppDelegate.swift (notification handling)
└── Runner.xcodeproj/ (background modes)

android/
├── app/src/main/
│   ├── AndroidManifest.xml (permissions, channels)
│   └── kotlin/MainActivity.kt (notification handling)
└── app/build.gradle.kts (dependencies)
```

### Documentation

```
DOCs/reminders/
├── reminder_implementation_guide.md
└── real_device_testing.md
```

## Components and Interfaces

### 1. Data Models

#### Reminder Model

```dart
class Reminder {
  final int? id;
  final String title;
  final String? description;
  final ReminderType type; // notification or fullScreenAlarm
  final ReminderSchedule schedule;
  final ReminderLink? link; // null for standalone
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextTriggerTime;
}
```

#### ReminderType Enum

```dart
enum ReminderType {
  notification,
  fullScreenAlarm;
}
```

#### ReminderSchedule Model

```dart
class ReminderSchedule {
  final ScheduleFrequency frequency; // none, daily, weekly, monthly
  final DateTime? specificDateTime; // for one-time reminders
  final TimeOfDay? timeOfDay; // for repeating reminders
  final List<int>? activeWeekdays; // 1-7 for weekly
  final int? dayOfMonth; // for monthly
  final int? minutesBefore; // for offset-based reminders
  final bool useHabitTimeWindow; // inherit from habit
  final bool useHabitActiveDays; // inherit from habit
}
```

#### ReminderLink Model

```dart
class ReminderLink {
  final LinkType type; // habit or task
  final int entityId; // habit_id or task_id
  final String entityName;
  final bool useDefaultText; // "Do [Habit Name]" vs custom
}

enum LinkType {
  habit,
  task;
}
```

### 2. Repository Layer

#### ReminderRepository

Handles all database operations for reminders.

**Key Methods:**
- `Future<int> createReminder(Reminder reminder)` - Insert new reminder
- `Future<Reminder?> getReminderById(int id)` - Fetch single reminder
- `Future<List<Reminder>> getAllReminders()` - Fetch all reminders
- `Future<List<Reminder>> getActiveReminders()` - Fetch active reminders only
- `Future<List<Reminder>> getRemindersByHabitId(int habitId)` - Fetch habit-linked reminders
- `Future<List<Reminder>> getRemindersByTaskId(int taskId)` - Fetch task-linked reminders
- `Future<void> updateReminder(Reminder reminder)` - Update existing reminder
- `Future<void> deleteReminder(int id)` - Delete reminder
- `Future<void> deleteRemindersByHabitId(int habitId)` - Cascade delete for habits
- `Future<void> deleteRemindersByTaskId(int taskId)` - Cascade delete for tasks
- `Future<void> updateNextTriggerTime(int id, DateTime nextTime)` - Update scheduling

**Database Schema:**

```sql
CREATE TABLE reminders (
  reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  reminder_type TEXT NOT NULL, -- 'notification' or 'fullScreenAlarm'
  
  -- Schedule configuration
  frequency TEXT NOT NULL, -- 'none', 'daily', 'weekly', 'monthly'
  specific_date_time TEXT,
  time_of_day TEXT,
  active_weekdays TEXT, -- JSON array
  day_of_month INTEGER,
  minutes_before INTEGER,
  use_habit_time_window INTEGER NOT NULL DEFAULT 0,
  use_habit_active_days INTEGER NOT NULL DEFAULT 0,
  
  -- Link configuration
  link_type TEXT, -- 'habit' or 'task'
  link_entity_id INTEGER,
  link_entity_name TEXT,
  use_default_text INTEGER NOT NULL DEFAULT 1,
  
  -- State
  is_active INTEGER NOT NULL DEFAULT 1,
  next_trigger_time TEXT,
  
  -- Metadata
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX idx_reminders_active ON reminders (is_active);
CREATE INDEX idx_reminders_next_trigger ON reminders (next_trigger_time);
CREATE INDEX idx_reminders_habit_link ON reminders (link_type, link_entity_id);
```

### 3. Service Layer

#### NotificationService

Handles standard system notifications using `flutter_local_notifications` plugin.

**Key Methods:**
- `Future<void> initialize()` - Setup notification channels and permissions
- `Future<bool> requestPermissions()` - Request notification permissions
- `Future<void> showNotification(Reminder reminder)` - Display notification
- `Future<void> scheduleNotification(Reminder reminder, DateTime triggerTime)` - Schedule future notification
- `Future<void> cancelNotification(int reminderId)` - Cancel scheduled notification
- `Future<void> cancelAllNotifications()` - Cancel all notifications

**Platform Configuration:**
- iOS: Request authorization for alerts, sounds, badges
- Android: Create notification channels with importance levels
- Handle notification tap actions to navigate to linked entities

#### AlarmService

Handles full-screen alarms using `flutter_alarm` or similar plugin.

**Key Methods:**
- `Future<void> initialize()` - Setup alarm capabilities
- `Future<void> showAlarm(Reminder reminder)` - Display full-screen alarm
- `Future<void> scheduleAlarm(Reminder reminder, DateTime triggerTime)` - Schedule future alarm
- `Future<void> cancelAlarm(int reminderId)` - Cancel scheduled alarm
- `Future<void> dismissAlarm(int reminderId)` - User dismisses alarm

**Features:**
- Full-screen overlay with dismiss button
- Alarm sound playback
- Vibration support
- Wake screen from sleep
- Prevent dismissal by back button (require explicit action)

#### ReminderSchedulerService

Calculates trigger times and manages reminder scheduling logic.

**Key Methods:**
- `DateTime? calculateNextTriggerTime(Reminder reminder)` - Calculate next trigger
- `Future<void> scheduleReminder(Reminder reminder)` - Schedule with appropriate service
- `Future<void> rescheduleReminder(Reminder reminder)` - Update scheduling
- `Future<void> rescheduleAllReminders()` - Reschedule all active reminders (app launch)
- `Future<void> handleHabitUpdate(int habitId)` - Recalculate habit-linked reminders
- `Future<void> handleTaskUpdate(int taskId)` - Recalculate task-linked reminders

**Scheduling Logic:**

1. **One-Time Reminders:**
   - Use `specificDateTime` directly
   - Mark as inactive after trigger

2. **Daily Reminders:**
   - Trigger at `timeOfDay` every day
   - Calculate next occurrence after current time

3. **Weekly Reminders:**
   - Trigger on specified `activeWeekdays`
   - Calculate next matching weekday

4. **Monthly Reminders:**
   - Trigger on `dayOfMonth`
   - Handle month-end edge cases (e.g., day 31 in February)

5. **Habit-Linked Reminders:**
   - If `useHabitTimeWindow`: use habit's `timeWindowStart` minus `minutesBefore`
   - If `useHabitActiveDays`: only trigger on habit's active weekdays
   - Respect habit's frequency configuration

6. **Task-Linked Reminders:**
   - Calculate: `task.dueDate` minus `minutesBefore`
   - Update when task due date changes
   - Disable if task is completed

### 4. Provider Layer

#### ReminderProvider (Riverpod)

State management for reminders using Riverpod.

**Providers:**
- `reminderNotifierProvider` - Main notifier for reminder list
- `activeRemindersProvider` - Filtered list of active reminders
- `habitRemindersProvider(habitId)` - Reminders for specific habit
- `taskRemindersProvider(taskId)` - Reminders for specific task

**Key Methods:**
- `Future<void> createReminder(Reminder reminder)` - Create and schedule
- `Future<void> updateReminder(Reminder reminder)` - Update and reschedule
- `Future<void> deleteReminder(int id)` - Delete and cancel
- `Future<void> toggleReminderActive(int id)` - Enable/disable
- `Future<void> refresh()` - Reload from database

### 5. Screen Components

#### ReminderListScreen

Displays all reminders with filtering and management options.

**Features:**
- List of all reminders (standalone and linked)
- Visual distinction between notification and alarm types
- Next trigger time display
- Quick toggle for active/inactive
- Swipe actions: edit, delete
- Floating action button to create new reminder
- Empty state with helpful message

#### CreateReminderScreen

Form for creating new reminders.

**Form Fields:**
- Title (text input)
- Description (optional text area)
- Reminder type selector (notification/alarm)
- Link selector (standalone/habit/task)
  - If habit: show habit picker
  - If task: show task picker
- Schedule configuration:
  - Frequency selector (one-time/daily/weekly/monthly)
  - Date/time pickers based on frequency
  - For habits: checkboxes for "use habit time window" and "use habit active days"
  - For tasks: minutes before selector (15, 30, 60, custom)
- Text configuration (for habit-linked):
  - Radio buttons: "Do [Habit Name]" or "Custom text"
  - Custom text input if selected
- Save button

**Validation:**
- Title required
- Valid date/time selection
- For task reminders: ensure task has due date
- For habit time window reminders: ensure habit has time window

#### EditReminderScreen

Similar to CreateReminderScreen but pre-filled with existing data.

**Additional Features:**
- Delete button
- Cancel button (discard changes)
- Update button

### 6. Widget Components

#### ReminderListItem

Displays a single reminder in the list.

**Layout:**
- Icon indicating type (bell for notification, alarm clock for alarm)
- Title and description
- Linked entity badge (if applicable)
- Next trigger time
- Active/inactive toggle switch
- Tap to edit

#### ReminderTypeSelector

Radio button group for selecting reminder type.

**Options:**
- Notification (with icon and description)
- Full-Screen Alarm (with icon and description)

#### ReminderSchedulePicker

Complex widget for configuring reminder schedule.

**Components:**
- Frequency dropdown
- Conditional date/time pickers
- Weekday selector (for weekly)
- Day of month selector (for monthly)
- Minutes before input (for offset-based)
- Habit configuration checkboxes (when applicable)

#### FullScreenAlarmDialog

Full-screen overlay displayed when alarm triggers.

**Layout:**
- Large alarm icon
- Reminder title and description
- Current time display
- Dismiss button (prominent)
- Snooze button (optional future enhancement)

## Data Models

### Database Tables

See Repository Layer section for complete schema.

### Model Relationships

```
Reminder
├── has one ReminderSchedule (embedded)
├── has optional ReminderLink (embedded)
└── references Habit or Task (via link_entity_id)

Habit
└── has many Reminders (one-to-many)

Task
└── has many Reminders (one-to-many)
```

### Data Flow

1. **Creating a Reminder:**
   ```
   User Input → CreateReminderScreen → ReminderProvider
   → ReminderRepository (save) → ReminderSchedulerService (schedule)
   → NotificationService/AlarmService (platform scheduling)
   ```

2. **Reminder Triggers:**
   ```
   Platform Notification → NotificationService (handle)
   → Navigate to linked entity (if applicable)
   → ReminderSchedulerService (calculate next trigger for repeating)
   → ReminderRepository (update next_trigger_time)
   ```

3. **Habit/Task Updates:**
   ```
   Habit/Task Update → ReminderSchedulerService (detect change)
   → ReminderRepository (fetch linked reminders)
   → Recalculate trigger times → Reschedule notifications
   ```

## Error Handling

### Permission Errors

**Scenario:** User denies notification permissions

**Handling:**
- Display informative dialog explaining why permissions are needed
- Provide button to open app settings
- Disable reminder creation until permissions granted
- Show persistent banner in ReminderListScreen

### Scheduling Errors

**Scenario:** Platform fails to schedule notification

**Handling:**
- Log error with details
- Retry scheduling once
- If retry fails, mark reminder as inactive
- Notify user with error message
- Provide option to manually retry

### Data Integrity Errors

**Scenario:** Linked entity (habit/task) is deleted

**Handling:**
- Cascade delete reminders via foreign key constraints
- If constraint fails, implement manual cleanup in repository
- Log orphaned reminders for debugging

### Time Zone Changes

**Scenario:** User changes device time zone

**Handling:**
- Detect time zone change on app launch
- Recalculate all trigger times in new time zone
- Reschedule all active reminders
- Log time zone change event

### Background Execution Limits

**Scenario:** iOS/Android limits background execution

**Handling:**
- Use platform-specific background task APIs
- Schedule notifications up to platform limits (iOS: 64, Android: unlimited)
- Reschedule on app launch to refresh notification queue
- Document limitations in user-facing help

## Testing Strategy

### Unit Tests

**Models:**
- Test model serialization/deserialization
- Test copyWith methods
- Test validation logic

**Repository:**
- Test CRUD operations with mock database
- Test cascade delete behavior
- Test query filters

**Services:**
- Test trigger time calculations
- Test scheduling logic for all frequency types
- Test habit/task integration logic
- Mock platform notification APIs

### Integration Tests

**End-to-End Flows:**
- Create standalone reminder → verify database entry → verify scheduled
- Create habit-linked reminder → verify inherits habit config
- Update habit time window → verify reminders rescheduled
- Delete task → verify reminders cascade deleted
- App restart → verify reminders rescheduled

### Real Device Testing

**iOS Testing:**
1. Build app in Xcode
2. Deploy to physical iPhone
3. Grant notification permissions
4. Create test reminders with near-future trigger times
5. Lock device and wait for notifications
6. Test full-screen alarms
7. Verify background notification delivery
8. Test notification tap navigation

**Android Testing:**
1. Build app with `flutter build apk`
2. Install on physical Android device
3. Grant notification permissions
4. Create test reminders with near-future trigger times
5. Lock device and wait for notifications
6. Test full-screen alarms
7. Verify background notification delivery
8. Test notification tap navigation
9. Test different Android versions (API 26+)

**Test Scenarios:**
- Notification delivery while app is closed
- Notification delivery while app is in background
- Full-screen alarm display and dismissal
- Notification tap opens correct screen
- Multiple reminders trigger correctly
- Repeating reminders reschedule after trigger
- Time zone change handling
- Device restart persistence

### Documentation

Create `DOCs/reminders/real_device_testing.md` with:
- Prerequisites (Xcode, Android Studio, physical devices)
- Step-by-step iOS testing instructions
- Step-by-step Android testing instructions
- Common issues and troubleshooting
- Platform-specific limitations
- Screenshots of expected behavior

## Platform-Specific Implementation

### iOS Configuration

**Info.plist Additions:**
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
<key>NSUserNotificationsUsageDescription</key>
<string>Numu needs notification permissions to send you reminders for your habits and tasks.</string>
```

**AppDelegate.swift:**
- Configure notification categories
- Handle notification responses
- Request authorization on first launch

**Xcode Project Settings:**
- Enable "Background Modes" capability
- Enable "Remote notifications" background mode
- Configure notification service extension (optional for rich notifications)

### Android Configuration

**AndroidManifest.xml Additions:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<application>
  <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
  <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
      <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
  </receiver>
</application>
```

**MainActivity.kt:**
- Configure notification channels
- Handle notification intents
- Request runtime permissions (Android 13+)

**build.gradle.kts:**
- Ensure `compileSdk` >= 33 for notification permissions
- Add notification dependencies if needed

### Dependencies

**pubspec.yaml Additions:**
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
  permission_handler: ^11.0.0
```

## Navigation Integration

### Adding Reminders to Navigation Panel

**Implementation Steps:**

1. **Update NavigationNotifier Default Items:**
   - Add reminders navigation item to `_defaultItems` list
   - Position before settings item
   - Use `Icons.notifications` icon
   - Route: `/reminders`

2. **Create Reminders Route:**
   - Add route definition in router configuration
   - Map to `ReminderListScreen`

3. **Navigation Customizer:**
   - Reminders item appears in customizer automatically
   - Users can toggle visibility
   - Users can reorder (except locked items)
   - Persist preferences via `SettingsRepository`

**Code Changes:**

```dart
// In navigation_provider.dart
static final List<NavigationItem> _defaultItems = [
  // ... existing items ...
  const NavigationItem(
    id: 'reminders',
    label: 'Reminders',
    icon: Icons.notifications,
    route: '/reminders',
    isHome: false,
    isEnabled: true,
    order: 4, // Before settings
  ),
  // ... settings item ...
];
```

### Badge Count (Future Enhancement)

Display count of active reminders in navigation item badge:
- Query count of active reminders
- Update badge when reminders change
- Clear badge when user views reminder list

## Integration with Existing Features

### Habit Integration

**Create Reminder from Habit Screen:**
- Add "Add Reminder" button in habit detail screen
- Pre-fill reminder with habit information
- Default to using habit's time window and active days

**Habit Updates Trigger Reminder Updates:**
- Listen to habit updates in `ReminderSchedulerService`
- Recalculate trigger times for linked reminders
- Reschedule notifications

**Habit Deletion Cascades to Reminders:**
- Database foreign key constraint handles cascade
- Or implement manual cleanup in `HabitRepository.deleteHabit()`

### Task Integration

**Add Reminder in Task Creation:**
- Add "Reminder" section in task creation/edit form
- Toggle to enable reminder
- Dropdown for offset (1 hour, 1 day, custom)
- Save reminder when task is saved

**Task Due Date Updates:**
- Listen to task updates in `ReminderSchedulerService`
- Recalculate trigger times for linked reminders
- Reschedule notifications

**Task Completion:**
- Disable reminders when task is marked complete
- Re-enable if task is marked incomplete

**Task Deletion Cascades to Reminders:**
- Database foreign key constraint handles cascade
- Or implement manual cleanup in `TaskRepository.deleteTask()`

## Performance Considerations

### Database Optimization

- Indexes on frequently queried columns (is_active, next_trigger_time, link_entity_id)
- Batch operations for rescheduling multiple reminders
- Lazy loading of reminder list (pagination if needed)

### Notification Scheduling

- Limit number of scheduled notifications (platform limits)
- Schedule only upcoming reminders (next 7 days)
- Reschedule on app launch to refresh queue
- Use efficient algorithms for trigger time calculation

### Memory Management

- Dispose of streams and listeners properly
- Avoid loading all reminders into memory simultaneously
- Use pagination for large reminder lists

## Security and Privacy

### Data Protection

- Reminders stored in local SQLite database (encrypted at rest by OS)
- No cloud sync (local-only data)
- User can delete all reminders via settings

### Permissions

- Request notification permissions with clear explanation
- Gracefully handle permission denial
- Provide path to grant permissions later

## Future Enhancements

### Phase 2 Features

- Snooze functionality for alarms
- Recurring reminder patterns (e.g., every 2 weeks)
- Location-based reminders
- Smart scheduling (ML-based optimal reminder times)
- Reminder templates
- Bulk operations (delete multiple, reschedule multiple)
- Reminder history and analytics
- Custom notification sounds
- Reminder groups/categories

### Integration Enhancements

- Reminder suggestions based on habit patterns
- Auto-create reminders for new habits
- Reminder effectiveness tracking
- Integration with device calendar
- Voice-activated reminder creation

## Migration Strategy

### Database Migration

Add reminders table in next database version:

```dart
// In database_service.dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  // ... existing migrations ...
  if (oldVersion < 9) {
    await _createReminderTables(db);
  }
}

Future<void> _createReminderTables(Database db) async {
  await db.execute('''
    CREATE TABLE reminders (
      -- schema from Repository section
    )
  ''');
  
  await db.execute('''
    CREATE INDEX idx_reminders_active ON reminders (is_active)
  ''');
  
  // ... other indexes ...
}
```

### Rollout Plan

1. **Phase 1:** Core reminder functionality (standalone reminders)
2. **Phase 2:** Habit integration
3. **Phase 3:** Task integration
4. **Phase 4:** Navigation panel integration
5. **Phase 5:** Full-screen alarms
6. **Phase 6:** Real device testing and refinement

## Success Metrics

### Technical Metrics

- Notification delivery success rate > 95%
- Average trigger time accuracy < 1 minute
- App launch time impact < 100ms
- Database query performance < 50ms

### User Metrics

- Reminder creation rate
- Active reminders per user
- Reminder dismissal rate
- Feature adoption rate
- User retention impact

## Conclusion

The Reminder System design provides a comprehensive, scalable solution for notification and alarm management in the Numu app. By following the existing architecture patterns and integrating seamlessly with habits and tasks, the system enhances user engagement while maintaining code quality and performance standards. The modular design allows for incremental implementation and future enhancements without disrupting existing functionality.
