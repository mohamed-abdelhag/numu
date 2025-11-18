# Requirements Document

## Introduction

This feature significantly enhances the habit tracking system by adding category support, introducing units for countable habits with minimum/maximum goal types, improving click behavior to prevent duplicates, refining boolean and countable habit interactions with quality tracking, enhancing the habit details screen with comprehensive statistics, and improving calendar-based editing. These improvements provide users with a more robust and flexible habit tracking experience.

## Glossary

- **Habit Model**: The data structure representing a habit with all its properties
- **Countable Habit**: A habit tracked by numeric values (e.g., pages read, glasses of water)
- **Boolean Habit**: A habit tracked by done/not done status
- **Quality**: An additional attribute indicating whether a habit was performed with high quality
- **Unit**: The measurement unit for countable habits (e.g., pages, reps, km, glasses)
- **Goal Type**: The type of goal for countable habits (minimum or maximum)
- **Target Value**: The numeric goal for countable habits
- **Habit Event**: A record of habit completion on a specific date
- **Habit Details Screen**: The interface showing comprehensive information and statistics about a habit
- **Calendar View**: The visual representation of habit completion over time
- **FAB**: Floating Action Button used to create new habit entries

## Requirements

### Requirement 1

**User Story:** As a user, I want to assign categories to habits, so that I can organize habits by type or goal area

#### Acceptance Criteria

1. THE Habit Model SHALL include a categoryId field of type String that can be null
2. WHEN the user creates a habit, THE Add Habit Screen SHALL provide a category selection dropdown
3. WHEN the user edits a habit, THE Edit Habit Screen SHALL display the currently assigned category and allow changing it
4. THE Add Habit Screen SHALL allow the user to leave the category unassigned
5. WHEN a category is assigned, THE Habit Repository SHALL save the categoryId with the habit data
6. WHEN a category is deleted, THE Habit Repository SHALL set categoryId to null for all affected habits

### Requirement 2

**User Story:** As a user, I want to filter habits by category, so that I can focus on specific types of habits

#### Acceptance Criteria

1. THE Habits Screen SHALL provide a category filter control
2. WHEN the user selects a category filter, THE Habits Screen SHALL display only habits assigned to that category
3. WHEN the user clears the category filter, THE Habits Screen SHALL display all habits
4. THE Habits Screen SHALL indicate when a category filter is active
5. THE Habits Screen SHALL display the count of filtered habits

### Requirement 3

**User Story:** As a user, I want to specify units for countable habits, so that I can track meaningful measurements

#### Acceptance Criteria

1. THE Habit Model SHALL include a unit field of type String that applies only to countable habits
2. WHEN the user creates a countable habit, THE Add Habit Screen SHALL require the user to specify a unit
3. THE Add Habit Screen SHALL provide common unit suggestions (pages, reps, km, glasses, minutes)
4. THE Add Habit Screen SHALL allow the user to enter a custom unit
5. WHEN the user creates a boolean habit, THE Habit Model SHALL leave the unit field null

### Requirement 4

**User Story:** As a user, I want to set minimum or maximum goals for countable habits, so that I can track different types of objectives

#### Acceptance Criteria

1. THE Habit Model SHALL include a goalType field with values "minimum" or "maximum" for countable habits
2. WHEN the user creates a countable habit, THE Add Habit Screen SHALL provide a goal type selector (minimum/maximum)
3. WHEN the user selects minimum goal type, THE Add Habit Screen SHALL indicate the habit is complete when the count reaches or exceeds the target
4. WHEN the user selects maximum goal type, THE Add Habit Screen SHALL indicate the habit is complete when the count stays at or below the target
5. THE Add Habit Screen SHALL require both a target value and a unit for countable habits

### Requirement 5

**User Story:** As a user, I want habit clicks to register only once, so that I don't accidentally create duplicate entries

#### Acceptance Criteria

1. WHEN the user clicks a habit card, THE Habit Card SHALL disable further clicks for 500 milliseconds
2. THE Habit Card SHALL ignore rapid successive clicks that occur within 500 milliseconds
3. WHEN a habit event is being saved, THE Habit Repository SHALL prevent duplicate events for the same date
4. THE Habit Repository SHALL check for existing events before creating a new event
5. WHEN a duplicate event is attempted, THE Habit Repository SHALL ignore the request without error

### Requirement 6

**User Story:** As a user with boolean habits that have quality tracking, I want the first click to mark done and the second click to mark quality, so that I can track both completion and excellence

#### Acceptance Criteria

1. WHEN the user clicks an incomplete boolean habit with quality enabled, THE Habit Card SHALL mark the habit as done
2. WHEN the user clicks a done boolean habit with quality enabled, THE Habit Card SHALL mark quality as achieved
3. WHEN quality is achieved, THE Habit Card SHALL display a star icon
4. THE Habit Card SHALL show different visual states for: not done, done without quality, and done with quality
5. WHEN the user clicks a habit with quality already marked, THE Habit Card SHALL take no action

### Requirement 7

**User Story:** As a user with boolean habits without quality tracking, I want the first click to mark done and the second click to unmark with confirmation, so that I can correct mistakes

#### Acceptance Criteria

1. WHEN the user clicks an incomplete boolean habit without quality, THE Habit Card SHALL mark the habit as done
2. WHEN the user clicks a done boolean habit without quality, THE Habit Card SHALL display a confirmation dialog
3. THE Confirmation Dialog SHALL ask "Are you sure you want to unmark this habit?"
4. WHEN the user confirms, THE Habit Card SHALL remove the done status
5. WHEN the user cancels, THE Habit Card SHALL maintain the done status

### Requirement 8

**User Story:** As a user with countable habits without quality, I want clicks to increment the count and allow manual entry when exceeding the target, so that I can track progress flexibly

#### Acceptance Criteria

1. WHEN the user clicks a countable habit without quality, THE Habit Card SHALL increment the count by 1
2. WHEN the count is below the target, THE Habit Card SHALL display the current count and target
3. WHEN the count reaches or exceeds the target, THE Habit Card SHALL display an input dialog
4. THE Input Dialog SHALL allow the user to manually enter the exact count value
5. WHEN the user submits the manual count, THE Habit Repository SHALL save the entered value

### Requirement 9

**User Story:** As a user with countable habits with quality tracking, I want clicks to increment until target is reached, then show an advanced dialog, so that I can track both quantity and quality

#### Acceptance Criteria

1. WHEN the user clicks a countable habit with quality and count is below target, THE Habit Card SHALL increment the count by 1
2. WHEN the count reaches the target, THE Habit Card SHALL display an advanced dialog
3. THE Advanced Dialog SHALL include a number input field pre-filled with the current count
4. THE Advanced Dialog SHALL include a quality checkbox
5. WHEN the user submits the dialog, THE Habit Repository SHALL save both the count value and quality status

### Requirement 10

**User Story:** As a user, I want countable habits to fully support numeric values, so that I can track actual quantities rather than just completion status

#### Acceptance Criteria

1. THE Habit Event Model SHALL store numeric count values for countable habits
2. THE Habit Repository SHALL save and retrieve count values for countable habit events
3. THE Habit Card SHALL display the current count value for countable habits
4. THE Habit Card SHALL calculate progress as (current count / target) for minimum goals
5. THE Habit Card SHALL calculate progress as (target - current count) / target for maximum goals

### Requirement 11

**User Story:** As a user, I want to see comprehensive statistics on the habit details screen, so that I can understand my habit performance over time

#### Acceptance Criteria

1. THE Habit Details Screen SHALL display the total value across all time for countable habits
2. THE Habit Details Screen SHALL display the total value for the current week
3. THE Habit Details Screen SHALL display the total value for the current month
4. THE Habit Details Screen SHALL calculate and display the average value per day
5. THE Habit Details Screen SHALL display all statistics using the habit's unit (e.g., "150 pages", "12 km")

### Requirement 12

**User Story:** As a user, I want quality details to always be visible on the habit details screen, so that I don't need to toggle a switch to see them

#### Acceptance Criteria

1. THE Habit Details Screen SHALL remove the quality details toggle switch
2. WHEN a habit has quality tracking enabled, THE Habit Details Screen SHALL always display quality statistics
3. THE Habit Details Screen SHALL show the number of days with quality achieved
4. THE Habit Details Screen SHALL show the percentage of completed days that achieved quality
5. WHEN a habit does not have quality tracking, THE Habit Details Screen SHALL not display quality statistics

### Requirement 13

**User Story:** As a user, I want to create new habit entries by tapping the FAB, so that I can log habits for any date

#### Acceptance Criteria

1. WHEN the user taps the FAB on the Habit Details Screen, THE Habit Details Screen SHALL display the habit entry dialog
2. THE Habit Entry Dialog SHALL show an empty date field
3. THE Habit Entry Dialog SHALL allow the user to select any date
4. THE Habit Entry Dialog SHALL provide appropriate input controls based on habit type (boolean/countable, with/without quality)
5. WHEN the user submits the dialog, THE Habit Repository SHALL create a new habit event for the selected date

### Requirement 14

**User Story:** As a user, I want to edit existing habit entries by tapping calendar dates, so that I can correct or update past entries

#### Acceptance Criteria

1. WHEN the user taps a date in the Calendar View, THE Habit Details Screen SHALL display the habit entry dialog
2. THE Habit Entry Dialog SHALL pre-fill the date field with the selected date
3. THE Habit Entry Dialog SHALL make the date field read-only (non-editable)
4. WHEN a habit event exists for that date, THE Habit Entry Dialog SHALL pre-fill all values (count, done state, quality)
5. WHEN no habit event exists for that date, THE Habit Entry Dialog SHALL show empty/default values
6. WHEN the user submits the dialog, THE Habit Repository SHALL update the existing event or create a new one for that date
