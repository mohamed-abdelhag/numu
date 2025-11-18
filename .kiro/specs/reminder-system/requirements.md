# Requirements Document

## Introduction

This feature implements a comprehensive reminder system that allows users to create notifications for tasks and habits. Reminders can be one-time or repeating, can be linked to specific habits or tasks, and support flexible scheduling options including custom repeat patterns, time windows, and specific days. The system integrates with the existing habit and task features to provide timely notifications.

## Glossary

- **Reminder**: A scheduled notification that alerts the user about a task or habit
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
