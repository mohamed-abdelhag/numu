# Reminder System Implementation Guide

## Overview

The Reminder System is a comprehensive notification and alarm feature for the Numu app. It provides users with the ability to create standalone reminders or link them to habits and tasks, with intelligent scheduling based on habit time windows, active days, and task due dates.

## Architecture

### Module Structure

The reminder system follows the project's feature-based architecture:

```
lib/features/reminders/
├── models/              # Data models
│   ├── reminder.dart
│   ├── reminder_type.dart
│   ├── reminder_schedule.dart
│   └── reminder_link.dart
├── repositories/        # Database operations
│   └── reminder_repository.dart
├── services/           # Business logic
│   ├── notification_service.dart
│   ├── alarm_service.dart
│   └── reminder_scheduler_service.dart
├── providers/          # State management (Riverpod)
│   ├── reminder_provider.dart
│   └── reminder_provider.g.dart
├── screens/            # UI screens
│   ├── reminder_list_screen.dart
│   ├── create_reminder_screen.dart
│   └── edit_reminder_screen.dart
└── widgets/            # Reusable UI components
    ├── reminder_list_item.dart
    ├── reminder_type_selector.dart
    ├── reminder_schedule_picker.dart
    └── full_screen_alarm_dialog.dart
```

## Core Components

### 1. Data Models

#### Reminder Model
The main data model containing all reminder information:
- **id**: Unique identifier
- **title**: Reminder text
- **description**: Optional additional details
- **type**: ReminderType (notification or fullScreenAlarm)
- **schedule**: ReminderSchedule configuration
- **link**: Optional ReminderLink to habit/task
- **isActive**: Enable/disable state
- **createdAt/updatedAt**: Timestamps
- **nextTriggerTime**: Calculated next trigger

#### ReminderType Enum
- `notification`: Standard system notification
- `fullScreenAlarm`: Intrusive full-screen alarm

#### ReminderSchedule Model
Defines when and how often the reminder triggers:
- **frequency**: ScheduleFrequency (none, daily, weekly, monthly)
- **specificDateTime**: For one-time reminders
- **timeOfDay**: For repeating reminders
- **activeWeekdays**: Days of week for weekly reminders
- **dayOfMonth**: Day for monthly reminders
- **minutesBefore**: Offset for task/habit reminders
- **useHabitTimeWindow**: Inherit habit's time window
- **useHabitActiveDays**: Inherit habit's active days

#### ReminderLink Model
Links reminder to habit or task:
- **type**: LinkType (habit or task)
- **entityId**: ID of linked entity
- **entityName**: Name for display
- **useDefaultText**: Use "Do [Name]" vs custom text

### 2. Repository Layer

**ReminderRepository** handles all database operations:

**Key Methods:**
- `createReminder()`: Insert new reminder
- `getReminderById()`: Fetch single reminder
- `getAllReminders()`: Fetch all reminders
- `getActiveReminders()`: Fetch only active reminders
- `getRemindersByHabitId()`: Fetch habit-linked reminders
- `getRemindersByTaskId()`: Fetch task-linked reminders
- `updateReminder()`: Update existing reminder
- `deleteReminder()`: Delete reminder
- `deleteRemindersByHabitId()`: Cascade delete for habits
- `deleteRemindersByTaskId()`: Cascade delete for tasks
- `updateNextTriggerTime()`: Update scheduling

**Database Schema:**
```sql
CREATE TABLE reminders (
  reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  reminder_type TEXT NOT NULL,
  frequency TEXT NOT NULL,
  specific_date_time TEXT,
  time_of_day TEXT,
  active_weekdays TEXT,
  day_of_month INTEGER,
  minutes_before INTEGER,
  use_habit_time_window INTEGER NOT NULL DEFAULT 0,
  use_habit_active_days INTEGER NOT NULL DEFAULT 0,
  link_type TEXT,
  link_entity_id INTEGER,
  link_entity_name TEXT,
  use_default_text INTEGER NOT NULL DEFAULT 1,
  is_active INTEGER NOT NULL DEFAULT 1,
  next_trigger_time TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### 3. Service Layer

#### NotificationService
Manages standard system notifications using `flutter_local_notifications`:
- Initialize notification channels (Android) and categories (iOS)
- Request notification permissions
- Show immediate notifications
- Schedule future notifications with timezone support
- Cancel scheduled notifications
- Handle notification tap actions

#### AlarmService
Manages full-screen alarms:
- Display full-screen alarm interface
- Play alarm sound
- Wake screen from sleep
- Require explicit dismissal
- Schedule future alarms

#### ReminderSchedulerService
Calculates trigger times and manages scheduling:
- Calculate next trigger time based on frequency
- Handle one-time, daily, weekly, monthly patterns
- Integrate with habit time windows and active days
- Integrate with task due dates and offsets
- Reschedule reminders on app launch
- Handle habit/task updates

**Scheduling Logic:**

1. **One-Time Reminders**: Use specificDateTime directly, mark inactive after trigger
2. **Daily Reminders**: Trigger at timeOfDay every day
3. **Weekly Reminders**: Trigger on specified activeWeekdays
4. **Monthly Reminders**: Trigger on dayOfMonth (handle month-end edge cases)
5. **Habit-Linked**: Use habit's timeWindowStart minus minutesBefore, respect active days
6. **Task-Linked**: Use task.dueDate minus minutesBefore

### 4. Provider Layer

**ReminderProvider** (Riverpod) manages state:
- `reminderNotifierProvider`: Main notifier for reminder list
- `activeRemindersProvider`: Filtered active reminders
- `habitRemindersProvider(habitId)`: Habit-specific reminders
- `taskRemindersProvider(taskId)`: Task-specific reminders

**Key Methods:**
- `createReminder()`: Create and schedule
- `updateReminder()`: Update and reschedule
- `deleteReminder()`: Delete and cancel
- `toggleReminderActive()`: Enable/disable
- `refresh()`: Reload from database

### 5. Screen Components

#### ReminderListScreen
Main interface displaying all reminders:
- List view with reminder items
- Visual distinction between types (icons)
- Next trigger time display
- Quick toggle for active/inactive
- Swipe actions (edit, delete)
- FAB to create new reminder
- Empty state message

#### CreateReminderScreen
Form for creating new reminders:
- Title and description inputs
- Reminder type selector
- Link selector (standalone/habit/task)
- Entity pickers (habit/task)
- Schedule configuration
- Text configuration for habit-linked
- Form validation
- Save button

#### EditReminderScreen
Similar to create screen with pre-filled data:
- All fields editable
- Delete button
- Cancel button
- Update button

## Data Flow

### Creating a Reminder
```
User Input → CreateReminderScreen → ReminderProvider
→ ReminderRepository (save) → ReminderSchedulerService (schedule)
→ NotificationService/AlarmService (platform scheduling)
```

### Reminder Triggers
```
Platform Notification → NotificationService (handle)
→ Navigate to linked entity (if applicable)
→ ReminderSchedulerService (calculate next trigger for repeating)
→ ReminderRepository (update next_trigger_time)
```

### Habit/Task Updates
```
Habit/Task Update → ReminderSchedulerService (detect change)
→ ReminderRepository (fetch linked reminders)
→ Recalculate trigger times → Reschedule notifications
```

## Platform Configuration

### iOS Setup

**Info.plist:**
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
- Request authorization

**Xcode Project:**
- Enable "Background Modes" capability
- Enable "Remote notifications" background mode

### Android Setup

**AndroidManifest.xml:**
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
- Ensure compileSdk >= 33

## Dependencies

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
  permission_handler: ^11.0.0
```

## Integration with Existing Features

### Habit Integration
- "Add Reminder" button in habit detail screen
- Pre-fill reminder with habit information
- Listen to habit updates and reschedule reminders
- Cascade delete reminders when habit is deleted

### Task Integration
- Reminder section in task creation/edit forms
- Toggle to enable reminder with offset selector
- Listen to task due date updates and reschedule
- Disable reminders when task is completed
- Cascade delete reminders when task is deleted

### Navigation Integration
- Reminders item in navigation panel
- Route: `/reminders`
- Icon: `Icons.notifications`
- Position: Before settings

## Error Handling

### Permission Errors
- Display informative dialog
- Provide button to open app settings
- Disable reminder creation until granted
- Show persistent banner

### Scheduling Errors
- Log error with details
- Retry scheduling once
- Mark reminder as inactive if retry fails
- Notify user with error message

### Time Zone Changes
- Detect on app launch
- Recalculate all trigger times
- Reschedule all active reminders

### Background Execution Limits
- Use platform-specific background task APIs
- Schedule up to platform limits (iOS: 64, Android: unlimited)
- Reschedule on app launch to refresh queue

## Performance Considerations

- Database indexes on frequently queried columns
- Batch operations for rescheduling
- Lazy loading of reminder list
- Efficient trigger time calculation algorithms
- Proper disposal of streams and listeners

## Security and Privacy

- Local SQLite database (encrypted at rest by OS)
- No cloud sync (local-only data)
- Clear permission explanations
- User can delete all reminders

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Repository CRUD operations
- Trigger time calculations
- Habit/task integration logic

### Integration Tests
- End-to-end reminder creation
- Habit-linked reminder inheritance
- Cascade delete behavior
- App restart rescheduling

### Real Device Tests
See `real_device_testing.md` for detailed instructions.

## Future Enhancements

- Snooze functionality
- Location-based reminders
- Smart scheduling (ML-based)
- Reminder templates
- Custom notification sounds
- Reminder analytics
- Voice-activated creation
