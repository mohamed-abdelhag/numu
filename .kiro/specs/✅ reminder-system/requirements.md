# Requirements Document

## Introduction

This feature implements a comprehensive reminder system as a standalone feature module that allows users to create notifications and full-screen alarms for tasks and habits. The system supports two reminder types: standard notifications and intrusive full-screen alarms. Reminders can be standalone or linked to specific habits and tasks, with intelligent scheduling based on habit time windows, active days, and task due dates. The system includes platform-specific configurations for iOS and Android, integrates with the navigation customizer for side panel access, and provides flexible scheduling options including custom repeat patterns, time-based triggers, and offset-based reminders. The reminder system is organized in its own feature folder following the project's architecture patterns.

## Glossary

- **Reminder System**: A standalone feature module that manages scheduled notifications and alarms for tasks and habits
- **Reminder**: A scheduled notification or alarm that alerts the user about a task or habit
- **Notification Reminder**: A standard system notification that appears in the notification tray
- **Full-Screen Alarm**: An intrusive alarm that displays a full-screen interface requiring user interaction to dismiss
- **One-Time Reminder**: A reminder that triggers once at a specific date and time
- **Repeating Reminder**: A reminder that triggers multiple times based on a schedule
- **Reminder List Screen**: The interface displaying all user-created reminders
- **Linked Reminder**: A reminder associated with a specific habit or task
- **Standalone Reminder**: A reminder created independently without linking to a habit or task
- **Custom Text**: User-defined text for a reminder notification
- **Time Window**: A specific time range during which a reminder should trigger
- **Repeat Pattern**: The schedule defining when a repeating reminder triggers (daily, weekly, monthly)
- **Due Date Reminder**: A reminder for a task that triggers before the task's due date
- **Notification Service**: The system component that delivers reminder notifications to the user
- **Platform Configuration**: Native iOS and Android setup required for notifications and alarms
- **Navigation Customizer**: The interface that allows users to add or remove features from the side panel

## Requirements

### Requirement 1

**User Story:** As a user, I want to create standalone reminders, so that I can receive notifications for any purpose

#### Acceptance Criteria

1. WHEN the user navigates to the Reminder List Screen, THE Reminder List Screen SHALL provide a button to create a new reminder
2. WHEN the user clicks the create button, THE Reminder List Screen SHALL navigate to the Create Reminder Screen
3. THE Create Reminder Screen SHALL provide an input field for custom reminder text
4. THE Create Reminder Screen SHALL provide a date and time picker for scheduling the reminder
5. WHEN the user saves the reminder, THE Reminder Repository SHALL save the reminder to Persistent Storage

### Requirement 2

**User Story:** As a user, I want to create one-time reminders for tasks, so that I receive a notification before the task is due

#### Acceptance Criteria

1. WHEN the user creates a reminder for a task, THE Create Reminder Screen SHALL allow linking to a specific task
2. THE Create Reminder Screen SHALL display a time offset selector (e.g., 1 hour before, 1 day before)
3. WHEN a task is linked, THE Reminder System SHALL calculate the reminder time based on the task's due date and the selected offset
4. WHEN the task's due date changes, THE Reminder System SHALL automatically update the reminder time
5. THE Notification Service SHALL trigger the reminder at the calculated time

### Requirement 3

**User Story:** As a user, I want to create repeating reminders for habits, so that I receive regular notifications to maintain my habits

#### Acceptance Criteria

1. WHEN the user creates a reminder for a habit, THE Create Reminder Screen SHALL allow linking to a specific habit
2. THE Create Reminder Screen SHALL provide options to use the habit's repeat pattern or define a custom pattern
3. WHEN using the habit's pattern, THE Reminder System SHALL inherit the habit's frequency (daily, weekly, monthly)
4. WHEN using a custom pattern, THE Create Reminder Screen SHALL allow the user to specify repeat frequency and days
5. THE Notification Service SHALL trigger the reminder according to the selected repeat pattern

### Requirement 4

**User Story:** As a user, I want reminders linked to habits to show the habit name or custom text, so that I know what action to take

#### Acceptance Criteria

1. WHEN the user creates a reminder linked to a habit, THE Create Reminder Screen SHALL provide two text options
2. THE Create Reminder Screen SHALL offer a default option: "Do [Habit Name]"
3. THE Create Reminder Screen SHALL offer a custom text option where the user can enter any text
4. WHEN the user selects the default option, THE Notification Service SHALL display "Do [Habit Name]" in the notification
5. WHEN the user selects custom text, THE Notification Service SHALL display the user-entered text in the notification

### Requirement 5

**User Story:** As a user, I want to configure time windows for habit reminders, so that I receive notifications at appropriate times

#### Acceptance Criteria

1. WHEN the user creates a repeating reminder for a habit, THE Create Reminder Screen SHALL provide a time window selector
2. THE Create Reminder Screen SHALL allow the user to specify a start time and end time for the reminder
3. WHEN a habit has a time window configured, THE Create Reminder Screen SHALL offer to use the habit's time window
4. THE Notification Service SHALL trigger the reminder within the specified time window
5. WHEN no time window is specified, THE Notification Service SHALL trigger the reminder at a default time

### Requirement 6

**User Story:** As a user, I want to specify which days repeating reminders should trigger, so that reminders align with my habit schedule

#### Acceptance Criteria

1. WHEN the user creates a repeating reminder, THE Create Reminder Screen SHALL provide a day selector for weekly reminders
2. THE Create Reminder Screen SHALL allow selection of specific days of the week (Monday through Sunday)
3. WHEN a habit has specific active days configured, THE Create Reminder Screen SHALL offer to use the habit's active days
4. THE Notification Service SHALL trigger the reminder only on selected days
5. WHEN no specific days are selected for daily reminders, THE Notification Service SHALL trigger every day

### Requirement 7

**User Story:** As a user, I want to view all my reminders in one place, so that I can manage my notifications

#### Acceptance Criteria

1. THE Reminder List Screen SHALL display all reminders (standalone and linked)
2. THE Reminder List Screen SHALL show reminder text, schedule, and linked habit/task (if any)
3. THE Reminder List Screen SHALL indicate whether each reminder is one-time or repeating
4. THE Reminder List Screen SHALL display the next scheduled trigger time for each reminder
5. THE Reminder List Screen SHALL provide options to edit or delete each reminder

### Requirement 8

**User Story:** As a user, I want to edit existing reminders, so that I can adjust notification schedules as my needs change

#### Acceptance Criteria

1. WHEN the user selects a reminder to edit, THE Reminder List Screen SHALL navigate to the Edit Reminder Screen
2. THE Edit Reminder Screen SHALL pre-fill all fields with current reminder data
3. THE Edit Reminder Screen SHALL allow modification of text, schedule, and repeat pattern
4. WHEN the user saves changes, THE Edit Reminder Screen SHALL update the reminder in Persistent Storage
5. THE Notification Service SHALL reschedule the reminder based on updated settings

### Requirement 9

**User Story:** As a user, I want to delete reminders I no longer need, so that I don't receive unnecessary notifications

#### Acceptance Criteria

1. WHEN the user selects a reminder for deletion, THE Reminder List Screen SHALL display a confirmation dialog
2. WHEN the user confirms deletion, THE Reminder List Screen SHALL remove the reminder from Persistent Storage
3. THE Notification Service SHALL cancel all scheduled notifications for the deleted reminder
4. WHEN a linked habit or task is deleted, THE Reminder System SHALL automatically delete associated reminders
5. THE Reminder List Screen SHALL remove the deleted reminder from the displayed list

### Requirement 10

**User Story:** As a user, I want reminders to support daily, weekly, and monthly repeat patterns, so that I can create flexible notification schedules

#### Acceptance Criteria

1. THE Create Reminder Screen SHALL provide a repeat frequency selector with options: None, Daily, Weekly, Monthly
2. WHEN Daily is selected, THE Notification Service SHALL trigger the reminder every day at the specified time
3. WHEN Weekly is selected, THE Create Reminder Screen SHALL allow day-of-week selection and THE Notification Service SHALL trigger on selected days
4. WHEN Monthly is selected, THE Create Reminder Screen SHALL allow day-of-month selection and THE Notification Service SHALL trigger on the selected day each month
5. WHEN None is selected, THE Notification Service SHALL trigger the reminder once at the specified date and time

### Requirement 11

**User Story:** As a user, I want the reminder system to integrate with my device's notification system, so that I receive timely alerts

#### Acceptance Criteria

1. THE Notification Service SHALL request notification permissions from the device on first use
2. WHEN a reminder triggers, THE Notification Service SHALL display a system notification with the reminder text
3. THE Notification Service SHALL include the linked habit or task name in the notification when applicable
4. WHEN the user taps a notification, THE Notification Service SHALL open the app to the relevant habit or task
5. THE Notification Service SHALL handle notification delivery even when the app is closed or in the background

### Requirement 12

**User Story:** As a user, I want reminders to persist across app restarts, so that I continue to receive notifications

#### Acceptance Criteria

1. WHEN the user creates or edits a reminder, THE Reminder Repository SHALL save all reminder data to Persistent Storage
2. WHEN the application launches, THE Reminder System SHALL load all reminders from Persistent Storage
3. THE Notification Service SHALL reschedule all active reminders on app launch
4. THE Reminder System SHALL maintain reminder state even if the device is restarted
5. THE Reminder System SHALL handle time zone changes correctly for scheduled reminders

### Requirement 13

**User Story:** As a user, I want to choose between notification and full-screen alarm types, so that I can select the appropriate alert level for different reminders

#### Acceptance Criteria

1. WHEN the user creates a reminder, THE Create Reminder Screen SHALL provide a reminder type selector with options: Notification and Full-Screen Alarm
2. WHEN Notification is selected, THE Notification Service SHALL deliver a standard system notification
3. WHEN Full-Screen Alarm is selected, THE Notification Service SHALL display a full-screen alarm interface
4. THE Full-Screen Alarm SHALL require user interaction to dismiss
5. THE Full-Screen Alarm SHALL play an alarm sound until dismissed

### Requirement 14

**User Story:** As a user, I want the reminder system to be properly configured for iOS and Android, so that notifications and alarms work correctly on both platforms

#### Acceptance Criteria

1. THE Reminder System SHALL include iOS-specific configuration in the ios folder
2. THE Reminder System SHALL include Android-specific configuration in the android folder
3. THE Reminder System SHALL configure notification permissions in iOS Info.plist
4. THE Reminder System SHALL configure notification channels in Android AndroidManifest.xml
5. THE Reminder System SHALL include Xcode project settings for background notification handling

### Requirement 15

**User Story:** As a developer, I want documentation for testing reminders on real devices, so that I can verify notification and alarm functionality

#### Acceptance Criteria

1. THE Reminder System SHALL include a markdown document with real device testing instructions
2. THE testing document SHALL provide iOS device testing steps
3. THE testing document SHALL provide Android device testing steps
4. THE testing document SHALL include troubleshooting steps for common notification issues
5. THE testing document SHALL explain how to test background notifications and full-screen alarms

### Requirement 16

**User Story:** As a user, I want the reminder system to be a separate feature module, so that it is organized and maintainable

#### Acceptance Criteria

1. THE Reminder System SHALL be implemented in a dedicated features/reminders folder
2. THE Reminder System SHALL include separate files for models, services, repositories, and screens
3. THE Reminder System SHALL follow the existing project architecture patterns
4. THE Reminder System SHALL have its own database tables and schema
5. THE Reminder System SHALL be independently testable from other features

### Requirement 17

**User Story:** As a user, I want to access the reminder system from the navigation panel, so that I can quickly view and manage my reminders

#### Acceptance Criteria

1. THE Navigation Customizer SHALL provide an option to add Reminders to the side panel
2. WHEN Reminders is added to the side panel, THE Navigation Panel SHALL display a Reminders menu item
3. WHEN the user taps the Reminders menu item, THE Navigation Panel SHALL navigate to the Reminder List Screen
4. THE Reminders menu item SHALL display a badge count of active reminders
5. THE Navigation Customizer SHALL allow the user to remove Reminders from the side panel

### Requirement 18

**User Story:** As a user, I want to set reminders for the day of a habit, so that I receive notifications on scheduled habit days

#### Acceptance Criteria

1. WHEN the user creates a reminder for a habit, THE Create Reminder Screen SHALL provide a "Day of habit" timing option
2. WHEN "Day of habit" is selected, THE Create Reminder Screen SHALL allow the user to specify a time of day
3. THE Notification Service SHALL trigger the reminder on days when the habit is active based on the habit's activeWeekdays
4. WHEN a habit has a time window, THE Create Reminder Screen SHALL offer to use the time window start time
5. THE Notification Service SHALL respect the habit's frequency and active days configuration

### Requirement 19

**User Story:** As a user, I want to set reminders for minutes before a habit's time window, so that I receive advance notice

#### Acceptance Criteria

1. WHEN the user creates a reminder for a habit with a time window, THE Create Reminder Screen SHALL provide a "Minutes before time window" option
2. THE Create Reminder Screen SHALL allow the user to specify the number of minutes before the time window (e.g., 15, 30, 60 minutes)
3. WHEN a habit has timeWindowStart configured, THE Notification Service SHALL calculate the reminder time by subtracting the specified minutes
4. WHEN a habit does not have a time window, THE Create Reminder Screen SHALL disable the "Minutes before time window" option
5. THE Notification Service SHALL trigger the reminder at the calculated time before the habit's time window

### Requirement 20

**User Story:** As a user, I want to set reminders for tasks before their due date, so that I have advance notice to complete them

#### Acceptance Criteria

1. WHEN the user creates or edits a task, THE Task Creation Screen SHALL provide an option to add a reminder
2. THE Task Creation Screen SHALL allow the user to specify when to be reminded (e.g., 1 hour before, 1 day before, custom)
3. WHEN a task has a dueDate configured, THE Reminder System SHALL calculate the reminder time based on the due date and offset
4. WHEN a task's due date is updated, THE Reminder System SHALL automatically update the associated reminder time
5. THE Task Creation Screen SHALL allow the user to enable or disable the reminder for the task
