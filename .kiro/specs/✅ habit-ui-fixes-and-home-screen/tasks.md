# Implementation Plan

- [x] 1. Add provider lifecycle safety to HabitsProvider
  - Add `ref.mounted` checks before all state updates in async methods (logEvent, addHabit, updateHabit, archiveHabit)
  - Wrap state assignments in conditional blocks that verify ref.mounted
  - Add INFO-level logging for cancelled operations when provider is disposed
  - Add ref.mounted check before setting error states in catch blocks
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Extend UserProfile model with week start preference
  - Add `startOfWeek` field to UserProfile model (int, 1-7 representing Monday-Sunday)
  - Set default value to 1 (Monday) in model constructor
  - Update `fromMap` and `toMap` methods to handle new field
  - Update `copyWith` method to include startOfWeek parameter
  - _Requirements: 3.1, 3.2_

- [x] 3. Create database migration for UserProfile
  - Create migration script to add `start_of_week` column to user_profile table
  - Set default value to 1 in migration
  - Update UserProfileRepository to handle new column in queries
  - Test migration with existing database
  - _Requirements: 3.4_

- [x] 4. Update PeriodProgressService for configurable week start
  - Add `startOfWeek` parameter to `recalculatePeriodProgress` method
  - Modify `_getCurrentPeriod` to accept and use startOfWeek parameter
  - Update week calculation logic to compute week start based on user preference
  - Update `_getActiveDaysInPeriod` to align with custom week start
  - Update all callers of PeriodProgressService to pass startOfWeek value
  - _Requirements: 4.1, 4.2_

- [x] 5. Add week start setting to Settings screen
  - Create week start preference UI in SettingsScreen
  - Implement day picker dialog with Monday-Sunday options
  - Save selected day to UserProfile via provider
  - Invalidate habit providers when week start changes to trigger recalculation
  - Display current week start preference in settings list
  - _Requirements: 3.3, 3.4_

- [x] 6. Refactor HabitQuickActionButton to use provider state
  - Remove FutureBuilder widgets that query repository directly
  - Watch HabitDetailProvider for current habit status
  - Remove local state management for completion status
  - Ensure button appearance reflects provider state
  - Keep loading state management for action in progress
  - Verify mounted checks before setState calls remain in place
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 7. Update HabitCard to display real-time data from provider
  - Watch HabitDetailProvider for habit events and streaks
  - Watch UserProfileProvider for startOfWeek preference
  - Implement `_calculateWeeklyProgress` method using actual events and custom week start
  - Implement `_calculateWeekProgress` method for week-based percentage
  - Display current streak from StreakType.completion
  - Display longest streak from StreakType.completion
  - Remove mock data generation logic
  - Update circular progress to show week-based percentage
  - _Requirements: 2.3, 4.2, 4.3, 5.1, 5.3, 5.5, 5.7_

- [x] 8. Update DailyItemCard to display real-time data from provider
  - Watch HabitDetailProvider for habit status when item is a habit
  - Display current streak value from provider
  - Calculate today's value from provider events
  - Remove direct repository queries
  - Ensure card updates within 100ms of provider state change
  - _Requirements: 2.4, 4.4, 5.2, 5.4, 5.6, 5.7_

- [x] 9. Update HabitListItem to invalidate provider on quick action
  - Ensure onQuickActionComplete callback invalidates HabitDetailProvider
  - Verify debounce logic remains in place for navigation
  - Test that streak and progress values update immediately after quick action
  - _Requirements: 5.1, 5.3, 5.7_

- [-] 10. Write tests for provider lifecycle management
  - [x] 10.1 Write unit test verifying ref.mounted prevents state updates after disposal
  - [ ] 10.2 Write unit test verifying cancelled operations are logged
  - [ ] 10.3 Write unit test verifying error states check ref.mounted
  - _Requirements: 6.1_

- [x] 11. Write tests for week calculation logic
  - [x] 11.1 Write unit tests for week start calculation with all 7 possible start days
  - [x] 11.2 Write unit tests for week boundaries at month/year transitions
  - [x] 11.3 Write unit tests for progress percentage calculations with custom week start
  - _Requirements: 6.2_

- [x] 12. Write integration tests for UI state synchronization
  - [x] 12.1 Write test verifying habit event logging updates all cards within 100ms
  - [x] 12.2 Write test verifying streak values match across HabitCard and DailyItemCard
  - [x] 12.3 Write test verifying state consistency when navigating between screens
  - [x] 12.4 Write test verifying week start preference change triggers recalculation
  - _Requirements: 6.3, 6.4_
