# Requirements Document

## Introduction

This feature addresses critical issues in the habit tracking system related to provider lifecycle management, UI state synchronization, and user preferences for week configuration. The system currently experiences race conditions when logging habit events, lacks proper week start configuration, and has inconsistent real-time UI updates across habit cards.

## Glossary

- **HabitsProvider**: The Riverpod state notifier that manages habit data and operations
- **HabitCard**: UI component displaying habit information in list views
- **DailyItemCard**: UI component showing habits on the home screen
- **UserProfile**: Data model containing user preferences and settings
- **WeekProgress**: Calculated percentage of habit completion for the current week
- **ref.mounted**: Riverpod property indicating if a provider reference is still valid

## Requirements

### Requirement 1: Provider Lifecycle Management

**User Story:** As a user, I want habit logging operations to complete reliably without crashes, so that my progress is always saved correctly.

#### Acceptance Criteria

1. WHEN an async operation is in progress in HabitsProvider, THE HabitsProvider SHALL check ref.mounted before updating state
2. WHEN a habit event is logged successfully, THE HabitsProvider SHALL update state only if ref.mounted returns true
3. IF ref.mounted returns false during an async operation, THEN THE HabitsProvider SHALL abort the state update and log the cancellation
4. WHEN an error occurs during habit logging, THE HabitsProvider SHALL check ref.mounted before setting error state

### Requirement 2: UI State Synchronization

**User Story:** As a user, I want habit cards to update smoothly without flickering or acting erratically, so that I have a consistent experience.

#### Acceptance Criteria

1. WHEN a habit event is logged, THE HabitCard SHALL update its display only after the provider state change is complete
2. THE HabitCard SHALL NOT directly modify its internal state based on user actions
3. WHEN the provider state changes, THE HabitCard SHALL rebuild with the new data from the provider
4. THE DailyItemCard SHALL follow the same state management pattern as HabitCard

### Requirement 3: Week Start Configuration

**User Story:** As a user, I want to configure which day my week starts on, so that weekly progress aligns with my personal schedule.

#### Acceptance Criteria

1. THE UserProfile SHALL include a startOfWeek field with values from 1 to 7 representing Monday through Sunday
2. WHEN a user first creates their profile, THE UserProfile SHALL default startOfWeek to 1 (Monday)
3. THE SettingsScreen SHALL provide a selector for users to change their startOfWeek preference
4. WHEN startOfWeek is changed, THE UserProfile SHALL persist the new value to the database

### Requirement 4: Week-Based Progress Calculation

**User Story:** As a user, I want to see my weekly progress percentage calculated based on my configured week start day, so that progress metrics are meaningful to me.

#### Acceptance Criteria

1. WHEN calculating weekly progress, THE PeriodProgressService SHALL use the startOfWeek value from UserProfile
2. THE WeekProgress calculation SHALL include only days from the current week based on startOfWeek
3. WHEN displaying progress on HabitCard, THE HabitCard SHALL show the week-based percentage
4. WHEN displaying progress on DailyItemCard, THE DailyItemCard SHALL show the week-based percentage
5. THE progress percentage SHALL update in real-time when habit events are logged

### Requirement 5: Real-Time Status Reflection

**User Story:** As a user, I want habit cards to immediately reflect my current completion status and streaks, so that I can see my progress without refreshing.

#### Acceptance Criteria

1. WHEN a habit event is logged from HabitQuickActionButton, THE HabitCard SHALL reflect the updated status within 100 milliseconds
2. WHEN a habit event is logged from the home screen, THE DailyItemCard SHALL reflect the updated status within 100 milliseconds
3. WHEN a habit event is logged, THE HabitCard SHALL display updated streak information in real-time
4. WHEN a habit event is logged, THE DailyItemCard SHALL display updated streak information in real-time
5. THE HabitCard SHALL show both current streak and longest streak values that update immediately
6. THE DailyItemCard SHALL show current streak value that updates immediately
7. WHEN navigating between screens, THE habit status and streak information SHALL remain consistent across all views

### Requirement 6: Testing Coverage

**User Story:** As a developer, I want comprehensive tests for the habit state management, so that regressions are caught early.

#### Acceptance Criteria

1. THE test suite SHALL include tests verifying ref.mounted checks in async operations
2. THE test suite SHALL include tests verifying UI updates only occur after provider state changes
3. THE test suite SHALL include tests verifying week progress calculations with different startOfWeek values
4. THE test suite SHALL include tests verifying real-time status updates across multiple card instances
