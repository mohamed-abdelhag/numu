# Implementation Plan

- [x] 1. Update database schema and create migration (skipped step no migration needed)
  - Create database migration to version 8 that converts timed habits to binary habits with time windows enabled
  - Add migration logic in `_upgradeDB` method to handle version 7 to 8 upgrade
  - Execute UPDATE query to change all `tracking_type = 'timed'` to `tracking_type = 'binary'` and set `time_window_enabled = 1`
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 2. Update tracking type enum and remove timed option
  - Remove `timed` value from `TrackingType` enum in `lib/features/habits/models/enums/tracking_type.dart`
  - Update enum to only contain `binary` and `value`
  - _Requirements: 1.1, 1.2_

- [x] 3. Update goal type enum and remove none option
  - Remove `none` value from `GoalType` enum in `lib/features/habits/models/enums/goal_type.dart`
  - Update enum to only contain `minimum` and `maximum`
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4. Update TrackingTypeSelector widget
  - Remove the "Timed" segment button from `lib/features/habits/widgets/forms/tracking_type_selector.dart`
  - Keep only "Yes/No" and "Value" options in the segmented button
  - _Requirements: 1.1, 1.2_

- [x] 5. Update GoalTypeSelector widget
  - Remove the "None" segment button from `lib/features/habits/widgets/forms/goal_type_selector.dart`
  - Keep only "Minimum" and "Maximum" options in the segmented button
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 6. Refactor add habit screen to remove unit chips and update validation
- [x] 6.1 Remove unit chip suggestions from add habit screen
  - Delete `_buildUnitChip` method from `lib/features/habits/screens/add_habit_screen.dart`
  - Remove the `Wrap` widget containing chip suggestions
  - Update unit text field to be a simple input without suggestions
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 6.2 Update value habit field visibility and validation
  - Show goal type selector immediately when value tracking is selected
  - Make goal type, target value, and unit required fields for value habits
  - Update form validation to enforce these requirements
  - Update helper text to clarify that unit is required
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 5.4, 5.5_

- [x] 6.3 Update time window availability for both tracking types
  - Ensure time window toggle is available in advanced options for binary habits
  - Ensure time window toggle is available in advanced options for value habits
  - Verify time window configuration works identically for both types
  - _Requirements: 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

- [x] 7. Refactor edit habit screen to match add habit screen changes
- [x] 7.1 Remove unit chip suggestions from edit habit screen
  - Delete `_buildUnitChip` method from `lib/features/habits/screens/edit_habit_screen.dart`
  - Remove the `Wrap` widget containing chip suggestions
  - Update unit text field to be a simple input without suggestions
  - _Requirements: 5.1, 5.2, 5.3, 7.2_

- [x] 7.2 Update edit screen validation and field requirements
  - Make goal type, target value, and unit required for value habits
  - Update form validation to match add habit screen
  - Handle tracking type changes appropriately (clear fields when switching types)
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 8. Update log habit event dialog to remove timed-specific logic
  - Remove `_buildTimedInputs()` method from `lib/features/habits/widgets/log_habit_event_dialog.dart`
  - Remove conditional rendering for `TrackingType.timed` in the build method
  - Remove timed case from `_createEvent()` switch statement
  - Ensure time window indicator works for both binary and value habits
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1, 3.2_

- [x] 9. Update habit model validation logic
  - Add validation in `Habit` model or repository to ensure value habits have goal type
  - Add validation to ensure value habits have target value
  - Add validation to ensure value habits have unit
  - Add validation to ensure target value is positive for value habits
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 5.5_

- [x] 10. Verify active days and quality layer work for both tracking types
  - Test that active days configuration is available for binary habits
  - Test that active days configuration is available for value habits
  - Test that quality layer toggle is available for binary habits
  - Test that quality layer toggle is available for value habits
  - Verify streak calculation respects active days for both types
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 11. Test database migration with existing data
  - Create test habits with timed tracking type
  - Run database migration
  - Verify timed habits are converted to binary with time window enabled
  - Verify time window configuration is preserved
  - Verify no habits remain with timed tracking type
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 12. Test habit creation and editing flows
  - Test creating binary habit without time window
  - Test creating binary habit with time window
  - Test creating value habit with minimum goal
  - Test creating value habit with maximum goal
  - Test editing existing binary habit
  - Test editing existing value habit
  - Test changing tracking type and verify field updates
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 13. Test event logging for all habit configurations
  - Test logging event for binary habit without time window
  - Test logging event for binary habit with time window
  - Test logging event for value habit with minimum goal
  - Test logging event for value habit with maximum goal
  - Test logging event with quality layer enabled
  - Verify time window validation works correctly
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 9.4, 9.5_
