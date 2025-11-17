# Requirements Document

## Introduction

This document defines the requirements for a comprehensive habit tracking system within the Numu app. The system enables users to create, track, and monitor habits with flexible configurations including simple yes/no tracking, value-based tracking, time windows, quality layers, and various scheduling patterns. The implementation follows a clean architecture with distinct service and provider layers, reusable widgets, and a centralized database service.

## Glossary

- **Habit System**: The complete habit tracking feature including screens, widgets, services, and data persistence
- **Habit Repository**: Data access layer responsible for all database operations related to habits
- **Habit Provider**: State management layer using Riverpod that manages habit state and business logic
- **Database Service**: Centralized SQLite database service managing all app tables
- **Habit Screen**: Main screen displaying the list of habits with add/edit/log capabilities
- **Habit Widget**: Reusable UI component for displaying individual habit information
- **Tracking Type**: The method of tracking a habit (binary, value, or timed)
- **Goal Type**: The target configuration for a habit (none, minimum, or maximum)
- **Frequency**: How often a habit is evaluated (daily, weekly, monthly, or custom)
- **Streak**: Consecutive successful completions of a habit
- **Time Window**: Optional preferred time range for completing a habit
- **Quality Layer**: Optional additional achievement criteria for a habit
- **Active Days**: Specific weekdays when a habit applies
- **Require Mode**: How completion is evaluated across multiple days (each, any, or total)

## Requirements

### Requirement 1: Navigation and Screen Access

**User Story:** As a user, I want to access the habits feature from the main navigation, so that I can quickly view and manage my habits.

#### Acceptance Criteria

1. WHEN the User opens the navigation drawer, THE Habit System SHALL display a "Habits" menu item with an appropriate icon
2. WHEN the User taps the "Habits" menu item, THE Habit System SHALL navigate to the Habit Screen
3. THE Habit Screen SHALL display within the app shell with proper title "Habits" in the app bar
4. THE Habit System SHALL register the "/habits" route in the router configuration

### Requirement 2: Database Schema Implementation

**User Story:** As a developer, I want a complete database schema for habit tracking, so that all habit data is properly persisted and queryable.

#### Acceptance Criteria

1. THE Database Service SHALL create a "habits" table with all fields defined in the implementation guidelines (habit_id, name, description, category_id, icon, color, tracking_type, goal_type, target_value, unit, frequency, custom_period_days, period_start_date, active_days_mode, active_weekdays, require_mode, time_window_enabled, time_window_start, time_window_end, time_window_mode, quality_layer_enabled, quality_layer_label, is_active, is_template, sort_order, created_at, updated_at, archived_at)
2. THE Database Service SHALL create a "habit_events" table with all fields defined in the implementation guidelines (event_id, habit_id, event_date, event_timestamp, completed, value, value_delta, time_recorded, within_time_window, quality_achieved, notes, created_at, updated_at)
3. THE Database Service SHALL create a "categories" table with fields (category_id, name, description, icon, color, is_system, sort_order, created_at)
4. THE Database Service SHALL create a "habit_streaks" table with fields (streak_id, habit_id, streak_type, current_streak, current_streak_start_date, longest_streak, longest_streak_start_date, longest_streak_end_date, total_completions, total_days_active, consistency_rate, last_calculated_at, last_event_date)
5. THE Database Service SHALL create a "habit_period_progress" table with fields (progress_id, habit_id, period_type, period_start_date, period_end_date, target_value, current_value, completed, completion_date, time_window_completions, quality_completions, created_at, updated_at)
6. THE Database Service SHALL create appropriate indexes on frequently queried columns
7. THE Database Service SHALL handle database migrations when schema changes occur

**[SUGGESTED CHANGE]**: Consider adding a database version migration strategy to handle future schema updates without data loss.

### Requirement 3: Habit Repository Layer

**User Story:** As a developer, I want a dedicated repository layer for habit data access, so that database operations are centralized and testable.

#### Acceptance Criteria

1. THE Habit Repository SHALL provide a method to create a new habit with all configuration options
2. THE Habit Repository SHALL provide a method to retrieve all active habits ordered by sort_order
3. THE Habit Repository SHALL provide a method to retrieve a single habit by habit_id
4. THE Habit Repository SHALL provide a method to update an existing habit's configuration
5. THE Habit Repository SHALL provide a method to archive a habit by setting archived_at timestamp
6. THE Habit Repository SHALL provide a method to delete a habit and all associated events
7. THE Habit Repository SHALL provide a method to log a habit event with all optional fields
8. THE Habit Repository SHALL provide a method to retrieve events for a habit within a date range
9. THE Habit Repository SHALL provide a method to update an existing event
10. THE Habit Repository SHALL provide a method to delete an event
11. THE Habit Repository SHALL use the centralized Database Service for all database operations
12. THE Habit Repository SHALL return strongly-typed model objects, not raw maps

### Requirement 4: Habit Data Models

**User Story:** As a developer, I want well-defined data models for habits and events, so that type safety is maintained throughout the application.

#### Acceptance Criteria

1. THE Habit System SHALL define a Habit model class with all fields from the habits table
2. THE Habit model SHALL include factory constructors for JSON serialization and deserialization
3. THE Habit model SHALL include a copyWith method for immutable updates
4. THE Habit System SHALL define a HabitEvent model class with all fields from the habit_events table
5. THE HabitEvent model SHALL include factory constructors for JSON serialization and deserialization
6. THE HabitEvent model SHALL include a copyWith method for immutable updates
7. THE Habit System SHALL define enum types for tracking_type, goal_type, frequency, active_days_mode, require_mode, time_window_mode, and streak_type
8. THE Habit System SHALL define a Category model class for habit categorization
9. THE Habit System SHALL define a HabitStreak model class for streak data
10. THE Habit System SHALL define a HabitPeriodProgress model class for period tracking

### Requirement 5: Habit Provider Layer

**User Story:** As a developer, I want a Riverpod provider layer for habit state management, so that UI components can reactively display habit data.

#### Acceptance Criteria

1. THE Habit Provider SHALL use Riverpod's AsyncNotifierProvider for managing habit list state
2. THE Habit Provider SHALL expose a method to load all active habits
3. THE Habit Provider SHALL expose a method to add a new habit
4. THE Habit Provider SHALL expose a method to update an existing habit
5. THE Habit Provider SHALL expose a method to archive a habit
6. THE Habit Provider SHALL expose a method to log a habit event
7. THE Habit Provider SHALL automatically refresh the habit list when changes occur
8. THE Habit Provider SHALL handle loading, error, and data states appropriately
9. THE Habit Provider SHALL use the Habit Repository for all data operations
10. THE Habit Provider SHALL NOT contain database logic or SQL queries

**[SUGGESTED CHANGE]**: Consider implementing optimistic updates for better perceived performance when logging habits.

### Requirement 6: Habit List Screen

**User Story:** As a user, I want to see a list of all my active habits, so that I can quickly view my habit tracking progress.

#### Acceptance Criteria

1. THE Habit Screen SHALL display a scrollable list of all active habits
2. WHEN no habits exist, THE Habit Screen SHALL display an empty state message with a call-to-action
3. THE Habit Screen SHALL display a floating action button to add a new habit
4. WHEN the Habit Provider is loading, THE Habit Screen SHALL display a loading indicator
5. WHEN the Habit Provider encounters an error, THE Habit Screen SHALL display an error message
6. THE Habit Screen SHALL use the Habit Provider to fetch and display habit data
7. THE Habit Screen SHALL refresh the habit list when returning from add/edit screens

### Requirement 7: Habit List Item Widget

**User Story:** As a user, I want each habit in the list to display key information, so that I can quickly understand my progress.

#### Acceptance Criteria

1. THE Habit List Item Widget SHALL be a reusable component in a separate file
2. THE Habit List Item Widget SHALL display the habit name prominently
3. THE Habit List Item Widget SHALL display the habit icon with the configured color
4. THE Habit List Item Widget SHALL display the current streak count
5. THE Habit List Item Widget SHALL display today's completion status for daily habits
6. THE Habit List Item Widget SHALL display current period progress for weekly/monthly habits
7. WHEN the User taps a Habit List Item Widget, THE Habit System SHALL navigate to the habit detail screen
8. THE Habit List Item Widget SHALL display a quick-log button for binary habits
9. WHEN the User taps the quick-log button, THE Habit System SHALL log a completion event for today
10. THE Habit List Item Widget SHALL accept a Habit model as a parameter

### Requirement 8: Add Habit Screen

**User Story:** As a user, I want to create a new habit with custom configuration, so that I can track habits that match my goals.

#### Acceptance Criteria

1. THE Add Habit Screen SHALL display a form with fields for habit name (required)
2. THE Add Habit Screen SHALL display a field for habit description (optional)
3. THE Add Habit Screen SHALL display a tracking type selector (binary, value, timed)
4. THE Add Habit Screen SHALL display a goal type selector (none, minimum, maximum)
5. WHEN goal type is minimum or maximum, THE Add Habit Screen SHALL display a target value input field
6. WHEN tracking type is value, THE Add Habit Screen SHALL display a unit input field
7. THE Add Habit Screen SHALL display a frequency selector (daily, weekly, monthly, custom)
8. THE Add Habit Screen SHALL display an icon picker for selecting habit icon
9. THE Add Habit Screen SHALL display a color picker for selecting habit color
10. THE Add Habit Screen SHALL display a save button that validates and creates the habit
11. WHEN validation fails, THE Add Habit Screen SHALL display appropriate error messages
12. WHEN save succeeds, THE Add Habit Screen SHALL navigate back to the Habit Screen
13. THE Add Habit Screen SHALL use the Habit Provider to create the new habit

**[SUGGESTED CHANGE]**: Consider implementing a multi-step wizard for complex habit configuration to improve user experience.

### Requirement 9: Edit Habit Screen

**User Story:** As a user, I want to edit an existing habit's configuration, so that I can adjust my tracking as my goals change.

#### Acceptance Criteria

1. THE Edit Habit Screen SHALL pre-populate all form fields with the existing habit data
2. THE Edit Habit Screen SHALL use the same form components as the Add Habit Screen
3. THE Edit Habit Screen SHALL display a save button that validates and updates the habit
4. THE Edit Habit Screen SHALL display a delete button to archive the habit
5. WHEN the User taps delete, THE Edit Habit Screen SHALL show a confirmation dialog
6. WHEN delete is confirmed, THE Habit System SHALL archive the habit and navigate back
7. WHEN save succeeds, THE Edit Habit Screen SHALL navigate back to the Habit Screen
8. THE Edit Habit Screen SHALL use the Habit Provider to update the habit

### Requirement 10: Habit Detail Screen

**User Story:** As a user, I want to view detailed information about a habit, so that I can see my complete tracking history and statistics.

#### Acceptance Criteria

1. THE Habit Detail Screen SHALL display the habit name, icon, and color
2. THE Habit Detail Screen SHALL display the habit description if present
3. THE Habit Detail Screen SHALL display current streak information for all streak types
4. THE Habit Detail Screen SHALL display the longest streak achieved
5. THE Habit Detail Screen SHALL display the consistency rate percentage
6. THE Habit Detail Screen SHALL display a calendar view showing completion history
7. THE Habit Detail Screen SHALL display a list of recent events with timestamps
8. THE Habit Detail Screen SHALL display an edit button that navigates to the Edit Habit Screen
9. THE Habit Detail Screen SHALL display a log button that opens the log event dialog
10. THE Habit Detail Screen SHALL use the Habit Provider to fetch habit and event data

### Requirement 11: Log Habit Event Dialog

**User Story:** As a user, I want to log a habit completion with optional details, so that I can track my progress accurately.

#### Acceptance Criteria

1. THE Log Habit Event Dialog SHALL display the habit name and icon
2. WHEN tracking type is binary, THE Log Habit Event Dialog SHALL display a simple "Mark Complete" button
3. WHEN tracking type is value, THE Log Habit Event Dialog SHALL display a numeric input for the value
4. WHEN tracking type is timed, THE Log Habit Event Dialog SHALL display a time picker
5. WHEN time window is enabled, THE Log Habit Event Dialog SHALL indicate if the selected time is within the window
6. WHEN quality layer is enabled, THE Log Habit Event Dialog SHALL display a checkbox for quality achievement
7. THE Log Habit Event Dialog SHALL display an optional notes field
8. THE Log Habit Event Dialog SHALL display a date picker to select which day to log for
9. THE Log Habit Event Dialog SHALL display a save button that creates the event
10. WHEN save succeeds, THE Log Habit Event Dialog SHALL close and refresh the habit data
11. THE Log Habit Event Dialog SHALL use the Habit Provider to log the event

### Requirement 12: Streak Calculation Service

**User Story:** As a developer, I want a dedicated service for calculating streaks, so that streak logic is centralized and reusable.

#### Acceptance Criteria

1. THE Streak Calculation Service SHALL provide a method to calculate current streak for a habit
2. THE Streak Calculation Service SHALL provide a method to calculate longest streak for a habit
3. THE Streak Calculation Service SHALL provide a method to calculate consistency rate for a habit
4. THE Streak Calculation Service SHALL implement the streak calculation algorithm defined in the implementation guidelines
5. THE Streak Calculation Service SHALL handle daily, weekly, monthly, and custom frequency habits
6. THE Streak Calculation Service SHALL respect active days configuration when calculating streaks
7. THE Streak Calculation Service SHALL calculate separate streaks for completion, time window, quality, and perfect types
8. THE Streak Calculation Service SHALL use the Habit Repository to fetch event data
9. THE Streak Calculation Service SHALL cache calculated streaks in the habit_streaks table
10. THE Streak Calculation Service SHALL recalculate streaks when new events are logged

### Requirement 13: Period Progress Calculation Service

**User Story:** As a developer, I want a dedicated service for calculating period progress, so that weekly/monthly habit tracking is accurate.

#### Acceptance Criteria

1. THE Period Progress Service SHALL provide a method to calculate current period progress for a habit
2. THE Period Progress Service SHALL implement the period calculation algorithm defined in the implementation guidelines
3. THE Period Progress Service SHALL handle weekly, monthly, and custom period frequencies
4. THE Period Progress Service SHALL respect active days configuration when calculating progress
5. THE Period Progress Service SHALL implement "each", "any", and "total" require modes correctly
6. THE Period Progress Service SHALL use the Habit Repository to fetch event data
7. THE Period Progress Service SHALL cache calculated progress in the habit_period_progress table
8. THE Period Progress Service SHALL recalculate progress when new events are logged
9. THE Period Progress Service SHALL create new period records when period boundaries are crossed

### Requirement 14: Reusable Form Widgets

**User Story:** As a developer, I want reusable form widgets for habit configuration, so that add and edit screens are consistent and maintainable.

#### Acceptance Criteria

1. THE Habit System SHALL provide a TrackingTypeSelector widget in a separate file
2. THE Habit System SHALL provide a GoalTypeSelector widget in a separate file
3. THE Habit System SHALL provide a FrequencySelector widget in a separate file
4. THE Habit System SHALL provide an IconPicker widget in a separate file
5. THE Habit System SHALL provide a ColorPicker widget in a separate file
6. THE Habit System SHALL provide a WeekdaySelector widget for active days configuration
7. THE Habit System SHALL provide a TimeWindowPicker widget for time window configuration
8. THE Habit System SHALL provide a QualityLayerToggle widget for quality layer configuration
9. EACH form widget SHALL accept a callback for value changes
10. EACH form widget SHALL accept an initial value parameter
11. EACH form widget SHALL follow consistent styling with the app theme

### Requirement 15: Empty State and Error Handling

**User Story:** As a user, I want clear feedback when there are no habits or when errors occur, so that I understand the current state of the app.

#### Acceptance Criteria

1. WHEN no habits exist, THE Habit Screen SHALL display an empty state widget with an illustration
2. THE empty state widget SHALL display a message "No habits yet. Start tracking your first habit!"
3. THE empty state widget SHALL display a prominent "Add Habit" button
4. WHEN a database error occurs, THE Habit System SHALL display a user-friendly error message
5. WHEN a network-related operation fails, THE Habit System SHALL display a retry button
6. THE Habit System SHALL log detailed error information for debugging purposes
7. THE Habit System SHALL use the core logging utility for error logging

### Requirement 16: Data Persistence and Caching

**User Story:** As a user, I want my habit data to persist across app restarts, so that I don't lose my tracking history.

#### Acceptance Criteria

1. THE Habit Repository SHALL persist all habit data to the SQLite database
2. THE Habit Repository SHALL persist all event data to the SQLite database
3. THE Habit System SHALL load habit data from the database on app startup
4. THE Habit System SHALL cache calculated streaks in the database
5. THE Habit System SHALL cache period progress in the database
6. WHEN cached data is stale, THE Habit System SHALL recalculate and update the cache
7. THE Habit System SHALL handle database migration without data loss

### Requirement 17: Performance Optimization

**User Story:** As a user, I want the habit tracking feature to be responsive and fast, so that logging habits doesn't feel sluggish.

#### Acceptance Criteria

1. THE Habit Screen SHALL load and display habits within 500 milliseconds
2. THE quick-log action SHALL complete within 200 milliseconds
3. THE Habit System SHALL use database indexes for frequently queried columns
4. THE Habit System SHALL limit event queries to relevant date ranges
5. THE Habit System SHALL calculate streaks asynchronously without blocking the UI
6. THE Habit System SHALL use pagination when displaying large event lists
7. THE Habit Provider SHALL implement debouncing for rapid user actions

**[SUGGESTED CHANGE]**: Consider implementing a background service to pre-calculate streaks and period progress during idle time.

### Requirement 18: Advanced Configuration (Future Enhancement)

**User Story:** As a user, I want to configure advanced habit options like time windows and quality layers, so that I can track habits with more nuance.

#### Acceptance Criteria

1. THE Add Habit Screen SHALL display an "Advanced Options" expandable section
2. WHEN expanded, THE Advanced Options section SHALL display time window configuration
3. WHEN expanded, THE Advanced Options section SHALL display quality layer configuration
4. WHEN expanded, THE Advanced Options section SHALL display active days configuration
5. WHEN expanded, THE Advanced Options section SHALL display require mode configuration
6. THE Habit System SHALL save all advanced configuration options to the database
7. THE Habit Detail Screen SHALL display active advanced configurations
8. THE Log Habit Event Dialog SHALL respect time window and quality layer settings

**Note:** This requirement can be implemented in a later phase after core functionality is complete.

---

## Requirements Summary

This requirements document defines 18 high-level requirements covering:

- Navigation and screen structure (1 requirement)
- Database schema and persistence (1 requirement)
- Data access layer (1 requirement)
- Data models (1 requirement)
- State management (1 requirement)
- User interface screens (5 requirements)
- Business logic services (2 requirements)
- Reusable components (1 requirement)
- Error handling (1 requirement)
- Data persistence (1 requirement)
- Performance (1 requirement)
- Advanced features (1 requirement)

The implementation will follow clean architecture principles with clear separation between:
- **Repository Layer**: Database operations and data access
- **Provider Layer**: State management and business logic coordination
- **Service Layer**: Specialized calculation logic (streaks, periods)
- **Presentation Layer**: UI components and screens
- **Model Layer**: Data structures and type definitions

All widgets will be modular and reusable, stored in separate files for maintainability.
