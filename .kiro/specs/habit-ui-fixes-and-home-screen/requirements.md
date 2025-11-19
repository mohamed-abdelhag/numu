# Requirements Document

## Introduction

This specification addresses critical UI/UX issues and enhancements in the habit tracking system, including fixing habit card displays, improving quality layer presentation, implementing a unified home screen for today's habits and tasks, and resolving navigation stability issues.

## Glossary

- **Habit Card**: A UI component displaying habit summary information in list views
- **Quality Layer**: An optional binary attribute that can be tracked alongside the primary habit metric (e.g., "focused" while doing reps)
- **Value Habit**: A habit tracked with numeric values (e.g., number of reps, minutes)
- **Binary Habit**: A habit tracked as done/not done
- **Timed Habit**: A habit tracked with duration in minutes
- **App Shell**: The main navigation container with bottom navigation bar and sidebar
- **Habit Detail Screen**: The screen showing comprehensive habit information including calendar and statistics
- **Home Screen**: The main dashboard showing today's habits and tasks

## Requirements

### Requirement 1: Habit Card Value Display

**User Story:** As a user tracking value-based habits, I want to see the current value on the habit card, so that I can quickly understand my progress without opening the detail screen.

#### Acceptance Criteria

1. WHEN THE Habit_Card displays a Value_Habit, THE Habit_Card SHALL render the current day's logged value
2. WHEN THE Habit_Card displays a Binary_Habit or Timed_Habit, THE Habit_Card SHALL render the appropriate status indicator
3. WHEN no value has been logged for the current day, THE Habit_Card SHALL display zero or an empty state indicator

### Requirement 2: Quality Layer Details Presentation

**User Story:** As a user with quality layer enabled habits, I want to see quality layer streak information integrated with normal details, so that I have a unified view of my progress. in the habit deitls screen 

#### Acceptance Criteria

1. WHEN THE Habit_Detail_Screen displays a habit with quality layer enabled, THE Habit_Detail_Screen SHALL render quality layer streak information in the same section as normal streak details
2. WHEN THE Habit_Detail_Screen displays a habit without quality layer, THE Habit_Detail_Screen SHALL omit the quality layer section entirely
3. THE Habit_Detail_Screen SHALL NOT use a select widget to split quality and normal details

### Requirement 3: Calendar Edit Value Loading

**User Story:** As a user editing a habit event in the calendar, I want the dialog to load with the current logged value, so that I can modify existing entries without re-entering data.

#### Acceptance Criteria

1. WHEN THE user opens the calendar edit dialog for a day with existing value, THE edit dialog SHALL pre-populate the value field with the current logged value
2. WHEN THE user opens the calendar edit dialog for a Value_Habit with Quality_Layer, THE edit dialog SHALL present quality as a binary yes/no option separate from the numeric value
3. WHEN THE user logs 20 reps with quality "focused", THE system SHALL record 20 reps with quality attribute set to true
4. THE system SHALL NOT treat quality layer as a separate counter from the primary value

### Requirement 4: Unified Home Screen

**User Story:** As a user planning my day, I want to see all habits and tasks due today in a single sorted list with progress tracking, so that I can efficiently manage my daily activities.

#### Acceptance Criteria

1. THE Home_Screen SHALL display a welcome message with the user's name
2. THE Home_Screen SHALL display a summary showing the count of habits and tasks due today
3. THE Home_Screen SHALL render a progress bar indicating completion percentage of today's items
4. WHEN completion percentage is 0-25%, THE Home_Screen SHALL display the message "Let's get started"
5. WHEN completion percentage is 26-75%, THE Home_Screen SHALL display the message "Almost there" or "Going well"
6. WHEN completion percentage is 76-99%, THE Home_Screen SHALL display the message "Going well"
7. WHEN completion percentage is 100%, THE Home_Screen SHALL display the message "Done for the day"
8. THE Home_Screen SHALL render habits and tasks in a single list sorted by scheduled time
9. WHEN a habit or task has no specific time, THE Home_Screen SHALL place it at the end of the sorted list

### Requirement 5: Shell Navigation Stability

**User Story:** As a user navigating the app, I want the app to always load within the shell, so that I have consistent navigation and avoid crashes.

#### Acceptance Criteria

1. WHEN THE app starts, THE app SHALL initialize within the App_Shell
2. WHEN THE app resumes from background, THE app SHALL maintain the App_Shell state
3. THE app SHALL NOT render any screen outside the App_Shell context
4. WHEN navigation errors occur, THE app SHALL recover within the App_Shell rather than crash

### Requirement 6: Tasks Screen Sidebar

**User Story:** As a user on the tasks screen, I want to open the sidebar drawer, so that I can access navigation options.

#### Acceptance Criteria

1. WHEN THE user taps the menu icon on the Tasks_Screen, THE App_Shell SHALL open the sidebar drawer
2. THE Tasks_Screen SHALL properly connect to the App_Shell drawer controller

### Requirement 7: Habit Card Accuracy and Quick Actions

**User Story:** As a user viewing habit cards, I want to see accurate streak numbers and completion percentages with quick action buttons, so that I can track and log progress efficiently.

#### Acceptance Criteria

1. THE Habit_Card SHALL calculate and display the current streak using the same logic as Habit_Detail_Screen
2. THE Habit_Card SHALL calculate and display the completion percentage based on actual progress data
3. WHEN THE Habit_Card displays a Binary_Habit without Quality_Layer, THE Habit_Card SHALL render a checkbox that marks the habit done on click
4. WHEN THE Habit_Card displays a Binary_Habit with Quality_Layer, THE Habit_Card SHALL render a checkbox that opens the quality layer dialog on second click after marking done
5. WHEN THE Habit_Card displays a Value_Habit, THE Habit_Card SHALL render a plus button that increments the value by one
6. WHEN THE Value_Habit goal is reached, THE Habit_Card SHALL open the full log dialog with quality options on next click
7. WHEN THE Habit_Card displays a Timed_Habit, THE Habit_Card SHALL render an add button that opens the log dialog
8. WHEN THE Habit_Card displays a Value_Habit with minimum goal type, THE Habit_Card SHALL only allow value increment and SHALL NOT enable quality layer selection via quick action
9. THE implementation SHALL include code comments noting that quality layer for minimum goal habits can only be set via the calendar in Habit_Detail_Screen
