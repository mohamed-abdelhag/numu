# Requirements Document

## Introduction

This specification addresses three distinct improvements to the numu habit tracking application:
1. Redesigning the habit card layout to improve visual hierarchy by moving streak and score badges to a separate row
2. Fixing the home screen to reflect real-time changes when habits are completed
3. Adding notification permission checking and activation controls in the settings screen to ensure reminders work properly on both Android and iOS

## Glossary

- **Habit Card**: A UI component displaying habit information including name, icon, weekly progress, streak count, and strength score
- **Streak Badge**: A visual indicator showing the current consecutive completion count for a habit
- **Strength Score Badge**: A visual indicator showing the overall performance percentage for a habit
- **Daily Items Provider**: The Riverpod provider that manages the list of habits and tasks for the current day on the home screen
- **Notification Service**: The service responsible for scheduling and displaying local notifications for reminders
- **Permission Handler**: A Flutter plugin for requesting and checking runtime permissions on mobile devices

## Requirements

### Requirement 1

**User Story:** As a user, I want the habit card to display streak and score information on a separate row from the habit name, so that the card layout is cleaner and easier to read.

#### Acceptance Criteria

1. WHEN a habit card is displayed THEN the System SHALL render the habit name, description, and icon in the header row without streak or score badges
2. WHEN a habit card is displayed THEN the System SHALL render the streak badge and strength score badge in a dedicated row between the header and the weekly progress section
3. WHEN a habit has a value-based tracking type THEN the System SHALL display the current value badge alongside the streak and score badges in the dedicated row
4. WHEN the dedicated badge row is rendered THEN the System SHALL maintain consistent spacing and alignment with the overall card design

### Requirement 2

**User Story:** As a user, I want the home screen to immediately reflect when I complete a habit, so that I can see my progress update in real-time without manual refresh.

#### Acceptance Criteria

1. WHEN a user completes a habit action on the home screen THEN the System SHALL update the daily items list to reflect the new completion status
2. WHEN a habit completion status changes THEN the System SHALL recalculate and display the updated completion percentage in the progress header
3. WHEN a habit is marked complete THEN the System SHALL update the visual state of the corresponding daily item card immediately
4. WHEN the daily items provider is invalidated THEN the System SHALL fetch fresh data and update the UI without requiring user-initiated refresh

### Requirement 3

**User Story:** As a user, I want to check and enable notification permissions from the settings screen, so that I can ensure reminders work properly on my device.

#### Acceptance Criteria

1. WHEN a user navigates to the settings screen THEN the System SHALL display a notifications section showing the current permission status
2. WHEN notification permissions are not granted THEN the System SHALL display a visual indicator showing permissions are disabled
3. WHEN a user taps the notification permission setting THEN the System SHALL request notification permissions from the operating system
4. WHEN notification permissions are granted THEN the System SHALL display a visual indicator showing notifications are enabled
5. WHEN the System checks notification permissions THEN the System SHALL use platform-specific APIs for both Android and iOS
6. IF notification permissions are denied by the operating system THEN the System SHALL provide guidance to enable permissions in device settings

