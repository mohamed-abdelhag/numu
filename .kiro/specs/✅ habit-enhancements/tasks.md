# Implementation Plan

- [x] 1. Implement duplicate event prevention in repository layer
  - Add logic to check for existing events before creating new ones
  - Implement updateEvent method for modifying existing events
  - Add timestamp-based duplicate detection
  - _Requirements: 5.3, 5.4, 5.5_

- [x] 2. Create HabitStatisticsService for calculating aggregated values
  - [x] 2.1 Create HabitStatistics model class
    - Define fields for total, weekly, monthly, average, quality days, and quality percentage
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 12.3, 12.4_
  
  - [x] 2.2 Implement HabitStatisticsService
    - Write calculateStatistics method that aggregates habit events
    - Implement _calculateTotal for summing countable habit values
    - Implement _calculateWeekly for current week aggregation
    - Implement _calculateMonthly for current month aggregation
    - Implement _calculateAverage for daily average calculation
    - Implement _calculateQualityDays for counting quality achievements
    - Implement _calculateQualityPercentage for quality rate calculation
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 12.3, 12.4_

- [x] 3. Update HabitDetailProvider to include statistics
  - Modify HabitDetailState to include HabitStatistics field
  - Integrate HabitStatisticsService into provider
  - Ensure statistics recalculate when events change
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 4. Implement click debouncing in HabitListItem
  - Add timestamp tracking for last click
  - Implement 500ms debounce logic
  - Ensure rapid clicks are ignored
  - _Requirements: 5.1, 5.2_

- [x] 5. Enhance HabitQuickLogButton with smart click behavior
  - [x] 5.1 Implement boolean habit with quality tracking (3-state)
    - First click marks habit as done
    - Second click marks quality as achieved
    - Third click takes no action
    - Display star icon when quality is achieved
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [x] 5.2 Implement boolean habit without quality (done/undone with confirmation)
    - First click marks habit as done
    - Second click shows confirmation dialog
    - Handle user confirmation to unmark
    - Handle user cancellation to maintain done status
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [x] 5.3 Implement countable habit without quality (increment with manual entry)
    - Click increments count by 1
    - Display current count and target
    - Show input dialog when target is reached or exceeded
    - Allow manual count entry in dialog
    - Save entered value to repository
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 10.1, 10.2, 10.3_
  
  - [x] 5.4 Implement countable habit with quality (increment with advanced dialog)
    - Click increments count by 1 until target
    - Show advanced dialog when target is reached
    - Pre-fill number input with current count
    - Include quality checkbox in dialog
    - Save both count and quality status
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3_
  
  - [x] 5.5 Implement progress calculation for countable habits
    - Calculate progress as (current / target) for minimum goals
    - Calculate progress as (target - current) / target for maximum goals
    - Display progress appropriately in UI
    - _Requirements: 10.4, 10.5_

- [x] 6. Enhance LogHabitEventDialog for flexible date handling
  - [x] 6.1 Add support for FAB-initiated logging (new entries)
    - Show empty date field
    - Allow user to select any date
    - Provide appropriate input controls based on habit type
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [x] 6.2 Add support for calendar-initiated editing (existing entries)
    - Pre-fill date field with selected date
    - Make date field read-only
    - Pre-fill values if event exists for that date
    - Show empty/default values if no event exists
    - Update existing event or create new one on submit
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_
  
  - [x] 6.3 Add unit display for countable habits
    - Display unit in number input field label
    - Show unit in value display
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.5_

- [x] 7. Update HabitDetailScreen to display comprehensive statistics
  - Remove quality details toggle switch
  - Add statistics section with total, weekly, monthly, and average values
  - Display statistics with habit's unit
  - Always show quality statistics when quality tracking is enabled
  - Hide quality statistics when quality tracking is disabled
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 8. Update HabitCalendarView to support date tapping for editing
  - Add onTap handler for calendar dates
  - Retrieve existing event for tapped date
  - Show LogHabitEventDialog with pre-filled date
  - Pass existing event data if available
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

- [x] 9. Ensure category assignment in Add/Edit Habit screens
  - Verify category selection dropdown exists in AddHabitScreen
  - Verify category selection dropdown exists in EditHabitScreen
  - Ensure category can be left unassigned
  - Display currently assigned category in EditHabitScreen
  - Save categoryId when habit is created or updated
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 10. Verify category filtering in HabitsScreen
  - Confirm category filter control is functional
  - Verify filtered habits display correctly
  - Ensure filter can be cleared
  - Verify filter indicator shows active state
  - Display count of filtered habits
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 11. Ensure unit support in Add/Edit Habit screens
  - Add unit input field for countable habits
  - Provide common unit suggestions (pages, reps, km, glasses, minutes)
  - Allow custom unit entry
  - Require unit for countable habits
  - Leave unit null for boolean habits
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 12. Ensure goal type support in Add/Edit Habit screens
  - Add goal type selector (minimum/maximum) for countable habits
  - Require both target value and unit for countable habits
  - Validate that target value is greater than 0
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 13. Update repository to handle category deletion
  - Implement unassignCategoryFromHabits method (if not already present)
  - Set categoryId to null for all habits when category is deleted
  - _Requirements: 1.6_
