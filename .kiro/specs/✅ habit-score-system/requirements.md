# Requirements Document

## Introduction

This feature implements a "Habit Score" system inspired by Loop Habit Tracker's algorithm. The habit score provides a more nuanced measure of habit strength than simple completion percentages. It uses an exponential moving average that rewards consistency while being forgiving of occasional misses — a few missed days after a long streak won't destroy progress.

## Glossary

- **Habit_Score_System**: The service responsible for calculating and storing habit strength scores
- **Habit_Score**: A value between 0.0 and 1.0 representing the current strength of a habit
- **Frequency_Value**: The number of expected completions per day (e.g., daily = 1.0, 3x/week = 3/7 ≈ 0.43)
- **Decay_Multiplier**: A value derived from frequency that controls how quickly scores decay on missed days
- **Checkmark_Value**: The completion value for a day (1.0 for complete, 0.0 for missed, or percentage for value habits)
- **Score_History**: A record of daily scores for a habit over time

## Requirements

### Requirement 1

**User Story:** As a user, I want to see a habit strength score that reflects my consistency over time, so that I can understand how well I'm maintaining my habits.

#### Acceptance Criteria

1. WHEN a habit has events logged THEN the Habit_Score_System SHALL calculate a score between 0.0 and 1.0
2. WHEN a user completes a habit THEN the Habit_Score_System SHALL increase the habit score using the exponential moving average formula
3. WHEN a user misses a habit on an active day THEN the Habit_Score_System SHALL decrease the habit score gradually based on the decay multiplier
4. WHEN a habit has no events THEN the Habit_Score_System SHALL return a score of 0.0
5. WHEN displaying the habit score THEN the system SHALL show it as a percentage (0-100%)

### Requirement 2

**User Story:** As a user, I want the scoring system to account for my habit's frequency, so that weekly habits aren't penalized as harshly as daily habits for missed days.

#### Acceptance Criteria

1. WHEN calculating the decay multiplier THEN the Habit_Score_System SHALL use the formula: `multiplier = 0.5^(√frequency / 13.0)`
2. WHEN a habit is configured as daily (frequency = 1.0) THEN the Habit_Score_System SHALL apply a multiplier of approximately 0.948
3. WHEN a habit is configured as weekly (frequency ≈ 0.14) THEN the Habit_Score_System SHALL apply a multiplier of approximately 0.980
4. WHEN a habit has a custom frequency THEN the Habit_Score_System SHALL calculate the frequency value as (repetitions / period_days)

### Requirement 3

**User Story:** As a user, I want the score calculation to handle value-based habits, so that partial completions contribute proportionally to my score.

#### Acceptance Criteria

1. WHEN a value habit reaches its target THEN the Habit_Score_System SHALL use a checkmark value of 1.0
2. WHEN a value habit is partially completed THEN the Habit_Score_System SHALL use a checkmark value equal to (actual_value / target_value), capped at 1.0
3. WHEN a value habit has a "maximum" goal type THEN the Habit_Score_System SHALL calculate checkmark value as the inverse proportion (staying under target = 1.0)

### Requirement 4

**User Story:** As a user, I want to see my habit score displayed in the UI, so that I can quickly assess my habit strength.

#### Acceptance Criteria

1. WHEN viewing the habit detail screen THEN the system SHALL display the current habit score as a percentage
2. WHEN viewing the habit card THEN the system SHALL display a visual indicator of habit strength (e.g., progress ring or bar)
3. WHEN the habit score changes THEN the system SHALL update the display in real-time after logging events

### Requirement 5

**User Story:** As a user, I want the score to only consider active days, so that non-active days don't affect my score.

#### Acceptance Criteria

1. WHEN calculating scores THEN the Habit_Score_System SHALL skip days that are not in the habit's active weekdays
2. WHEN a day is marked as "skip" THEN the Habit_Score_System SHALL not affect the score for that day
3. WHEN iterating through days THEN the Habit_Score_System SHALL only process days from the habit's creation date to today

### Requirement 6

**User Story:** As a developer, I want the score calculation to be efficient, so that it doesn't slow down the app when viewing habits.

#### Acceptance Criteria

1. WHEN calculating scores THEN the Habit_Score_System SHALL cache the most recent score to avoid full recalculation
2. WHEN a new event is logged THEN the Habit_Score_System SHALL incrementally update the score from the last cached value
3. WHEN the habit configuration changes (frequency, active days) THEN the Habit_Score_System SHALL trigger a full recalculation

### Requirement 7

**User Story:** As a developer, I want to serialize and deserialize habit scores, so that they can be stored in the database.

#### Acceptance Criteria

1. WHEN storing a habit score THEN the Habit_Score_System SHALL persist the score value and calculation timestamp
2. WHEN loading a habit THEN the Habit_Score_System SHALL retrieve the cached score from the database
3. WHEN serializing a score THEN the Habit_Score_System SHALL convert it to a map representation
4. WHEN deserializing a score THEN the Habit_Score_System SHALL reconstruct the score from the map representation
