# Requirements Document

## Introduction

This specification addresses improvements to the habit tracking system to simplify the tracking type selection and enhance the unit input experience. The current system has three separate tracking types (Yes/No, Value, Timed), but "Timed" should not be a separate tracking type since both Yes/No and Value habits can have time windows. Additionally, the unit input for value-based habits needs to be simplified by removing chip-based suggestions and allowing direct text input with a clear label format.

## Glossary

- **Habit System**: The application's habit tracking feature that allows users to create and monitor habits
- **Tracking Type**: The method by which a habit is tracked (Yes/No or Value)
- **Time Window**: An optional time range during which a habit should be completed
- **Quality Layer**: An optional rating system for habit completion quality
- **Active Days**: Specific days of the week when a habit is tracked
- **Goal Type**: For value-based habits, whether the target is a minimum or maximum value
- **Unit**: The measurement unit for value-based habits (e.g., glasses, pages, km)

## Requirements

### Requirement 1

**User Story:** As a user creating a habit, I want to choose between only Yes/No or Value tracking types, so that I can select the appropriate tracking method without confusion about timed tracking.

#### Acceptance Criteria

1. WHEN THE Habit System displays tracking type options, THE Habit System SHALL present exactly two tracking type options: "Yes/No" and "Value"
2. WHEN THE Habit System displays tracking type options, THE Habit System SHALL remove the "Timed" option from the tracking type selector
3. WHEN a user selects "Yes/No" tracking type, THE Habit System SHALL allow the user to optionally enable a time window layer
4. WHEN a user selects "Value" tracking type, THE Habit System SHALL allow the user to optionally enable a time window layer

### Requirement 2

**User Story:** As a user creating a Yes/No habit, I want to optionally add a time window, so that I can track habits that need to be completed within specific time ranges.

#### Acceptance Criteria

1. WHEN a user selects "Yes/No" tracking type, THE Habit System SHALL display an option to enable time window tracking
2. WHEN a user enables time window for a Yes/No habit, THE Habit System SHALL display time window configuration fields
3. WHEN a user configures a time window for a Yes/No habit, THE Habit System SHALL store the time window start time, end time, and mode
4. WHEN a user disables time window for a Yes/No habit, THE Habit System SHALL clear any previously configured time window settings

### Requirement 3

**User Story:** As a user creating a Value habit, I want to optionally add a time window, so that I can track measurable habits that need to be completed within specific time ranges.

#### Acceptance Criteria

1. WHEN a user selects "Value" tracking type, THE Habit System SHALL display an option to enable time window tracking
2. WHEN a user enables time window for a Value habit, THE Habit System SHALL display time window configuration fields
3. WHEN a user configures a time window for a Value habit, THE Habit System SHALL store the time window start time, end time, and mode
4. WHEN a user disables time window for a Value habit, THE Habit System SHALL clear any previously configured time window settings

### Requirement 4

**User Story:** As a user creating a Value habit, I want to specify a goal type of minimum or maximum, so that I can track whether I need to reach at least a target value or stay below a target value.

#### Acceptance Criteria

1. WHEN a user selects "Value" tracking type, THE Habit System SHALL display goal type options: "Minimum" and "Maximum"
2. WHEN a user selects "Minimum" goal type, THE Habit System SHALL require the user to enter a target value representing the minimum threshold
3. WHEN a user selects "Maximum" goal type, THE Habit System SHALL require the user to enter a target value representing the maximum threshold
4. WHEN a user selects "Value" tracking type, THE Habit System SHALL require the user to specify a unit for the value
5. WHEN a user enters a target value, THE Habit System SHALL validate that the value is a positive number greater than zero

### Requirement 5

**User Story:** As a user creating a Value habit, I want to type my unit directly into a text field, so that I can quickly specify custom units without selecting from predefined chips.

#### Acceptance Criteria

1. WHEN a user selects "Value" tracking type, THE Habit System SHALL display a text input field labeled "Unit"
2. WHEN a user types into the unit field, THE Habit System SHALL accept any alphanumeric text as a valid unit
3. WHEN THE Habit System displays the unit field, THE Habit System SHALL remove all predefined unit suggestion chips
4. WHEN a user enters a unit, THE Habit System SHALL display the unit alongside the target value in the format "[target value] [unit]"
5. WHEN a user saves a Value habit, THE Habit System SHALL require that the unit field contains at least one character

### Requirement 6

**User Story:** As a user with existing Timed habits, I want my habits to be automatically migrated to Yes/No habits with time windows enabled, so that I don't lose any habit data during the system update.

#### Acceptance Criteria

1. WHEN THE Habit System performs a database migration, THE Habit System SHALL identify all habits with tracking type "timed"
2. WHEN THE Habit System identifies a timed habit, THE Habit System SHALL convert the tracking type to "binary"
3. WHEN THE Habit System converts a timed habit, THE Habit System SHALL set the time window enabled flag to true
4. WHEN THE Habit System converts a timed habit, THE Habit System SHALL preserve all existing time window configuration data
5. WHEN THE Habit System completes the migration, THE Habit System SHALL ensure no habits remain with tracking type "timed"

### Requirement 7

**User Story:** As a user editing an existing habit, I want the same simplified tracking type options and unit input, so that I have a consistent experience across habit creation and editing.

#### Acceptance Criteria

1. WHEN a user opens the edit habit screen, THE Habit System SHALL display only "Yes/No" and "Value" tracking type options
2. WHEN a user edits a Value habit, THE Habit System SHALL display the unit as a text input field without suggestion chips
3. WHEN a user edits a habit with time window enabled, THE Habit System SHALL display the time window configuration in the advanced options section
4. WHEN a user changes tracking type from Value to Yes/No, THE Habit System SHALL clear the goal type, target value, and unit fields
5. WHEN a user changes tracking type from Yes/No to Value, THE Habit System SHALL require the user to specify goal type, target value, and unit

### Requirement 8

**User Story:** As a user, I want both Yes/No and Value habits to support active days configuration, so that I can track habits that only apply on certain days of the week.

#### Acceptance Criteria

1. WHEN a user creates a Yes/No habit, THE Habit System SHALL display active days configuration options
2. WHEN a user creates a Value habit, THE Habit System SHALL display active days configuration options
3. WHEN a user selects specific active days, THE Habit System SHALL use only those days for streak calculation
4. WHEN a user selects specific active days, THE Habit System SHALL use only those days for progress tracking
5. WHEN a user selects "All days" mode, THE Habit System SHALL track the habit on every day of the week

### Requirement 9

**User Story:** As a user, I want both Yes/No and Value habits to support quality layer tracking, so that I can rate the quality of my habit completions.

#### Acceptance Criteria

1. WHEN a user creates a Yes/No habit, THE Habit System SHALL display an option to enable quality layer tracking
2. WHEN a user creates a Value habit, THE Habit System SHALL display an option to enable quality layer tracking
3. WHEN a user enables quality layer, THE Habit System SHALL allow the user to specify a custom quality label
4. WHEN a user logs a habit event with quality layer enabled, THE Habit System SHALL prompt the user to provide a quality rating
5. WHEN a user disables quality layer, THE Habit System SHALL not prompt for quality ratings during habit logging
