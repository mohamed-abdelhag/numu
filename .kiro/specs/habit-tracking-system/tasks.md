# Implementation Plan

This implementation plan breaks down the habit tracking system into discrete, actionable coding tasks. Each task builds incrementally on previous work, with all code properly integrated. The plan follows the phased approach from the design document, starting with MVP functionality.

## Phase 1: Core Foundation (MVP)

- [x] 1. Set up database schema and core models
- [x] 1.1 Update DatabaseService to create habits and habit_events tables with indexes
  - Modify `lib/core/services/database_service.dart`
  - Add table creation SQL for habits table with all basic fields
  - Add table creation SQL for habit_events table
  - Create indexes on habit_id, event_date, and is_active
  - Update database version number
  - _Requirements: 2.1, 2.2, 2.6_

- [x] 1.2 Create enum types for habit configuration
  - Create `lib/features/habits/models/enums/tracking_type.dart` with binary, value, timed
  - Create `lib/features/habits/models/enums/goal_type.dart` with none, minimum, maximum
  - Create `lib/features/habits/models/enums/frequency.dart` with daily, weekly, monthly, custom
  - Create `lib/features/habits/models/enums/active_days_mode.dart` with all, selected
  - Create `lib/features/habits/models/enums/require_mode.dart` with each, any, total
  - _Requirements: 4.7_

- [x] 1.3 Create Habit model class
  - Create `lib/features/habits/models/habit.dart`
  - Define all fields from database schema
  - Implement `fromMap()` factory constructor with type conversions
  - Implement `toMap()` method with type conversions
  - Implement `copyWith()` method for immutable updates
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 1.4 Create HabitEvent model class
  - Create `lib/features/habits/models/habit_event.dart`
  - Define all fields from database schema
  - Implement `fromMap()` factory constructor
  - Implement `toMap()` method
  - Implement `copyWith()` method
  - _Requirements: 4.4, 4.5, 4.6_

- [x] 2. Implement repository layer for data access
- [x] 2.1 Create HabitRepository with basic CRUD operations
  - Create `lib/features/habits/repositories/habit_repository.dart`
  - Implement `getActiveHabits()` method to fetch all active habits ordered by sort_order
  - Implement `getHabitById(int id)` method
  - Implement `createHabit(Habit habit)` method with validation
  - Implement `updateHabit(Habit habit)` method
  - Implement `archiveHabit(int id)` method to set archived_at timestamp
  - Use DatabaseService.instance for all database operations
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.11, 3.12_

- [x] 2.2 Add event logging methods to HabitRepository
  - Implement `logEvent(HabitEvent event)` method
  - Implement `getEventsForDate(int habitId, DateTime date)` method
  - Implement `getEventsForHabit(int habitId, {DateTime? startDate, DateTime? endDate})` method with date range filtering
  - _Requirements: 3.7, 3.8_

- [x] 3. Create provider layer for state management
- [x] 3.1 Set up HabitsProvider with Riverpod code generation
  - Create `lib/features/habits/providers/habits_provider.dart`
  - Use `@riverpod` annotation and extend `_$HabitsNotifier`
  - Implement `build()` method to load active habits
  - Add `part 'habits_provider.g.dart'` directive
  - _Requirements: 5.1, 5.2, 5.8, 5.9_

- [x] 3.2 Add habit management methods to HabitsProvider
  - Implement `addHabit(Habit habit)` method with AsyncValue.guard
  - Implement `updateHabit(Habit habit)` method
  - Implement `archiveHabit(int id)` method
  - Implement `logEvent(HabitEvent event)` method
  - Each method should refresh the habit list after operation
  - _Requirements: 5.3, 5.4, 5.5, 5.6, 5.7, 5.10_

- [x] 3.3 Generate Riverpod code
  - Run `dart run build_runner build --delete-conflicting-outputs`
  - Verify `habits_provider.g.dart` is generated correctly
  - _Requirements: 5.1_

- [x] 4. Build habits list screen
- [x] 4.1 Create HabitsScreen with basic layout
  - Create `lib/features/habits/screens/habits_screen.dart`
  - Use Scaffold with NumuAppBar
  - Add Consumer widget to watch habitsNotifierProvider
  - Implement loading state with CircularProgressIndicator
  - Implement error state with error message and retry button
  - Add FloatingActionButton to navigate to add habit screen
  - _Requirements: 6.1, 6.4, 6.5, 6.6, 6.7, 15.4, 15.5_

- [x] 4.2 Create EmptyHabitsState widget
  - Create `lib/features/habits/widgets/empty_habits_state.dart`
  - Display icon, "No habits yet" message, and "Add Habit" button
  - Button navigates to add habit screen
  - _Requirements: 6.2, 15.1, 15.2, 15.3_

- [x] 4.3 Display habit list in HabitsScreen
  - Use ListView.builder when habits list is not empty
  - Display HabitListItem for each habit
  - _Requirements: 6.1, 6.3_

- [x] 5. Create reusable habit list item widget
- [x] 5.1 Build HabitListItem widget structure
  - Create `lib/features/habits/widgets/habit_list_item.dart`
  - Accept Habit model as parameter
  - Use Card with InkWell for tap handling
  - Display habit icon in colored circle
  - Display habit name
  - Navigate to habit detail screen on tap
  - _Requirements: 7.1, 7.2, 7.3, 7.8, 7.10_

- [x] 5.2 Add quick log button to HabitListItem
  - Create `lib/features/habits/widgets/habit_quick_log_button.dart`
  - Show check icon for binary habits
  - Show plus icon for value/timed habits
  - Implement quick log for binary habits (create event with completed=true for today)
  - Show LogHabitEventDialog for value/timed habits
  - _Requirements: 7.9, 7.10_

- [x] 6. Build add habit screen with basic form
- [x] 6.1 Create AddHabitScreen scaffold and form structure
  - Create `lib/features/habits/screens/add_habit_screen.dart`
  - Use Scaffold with app bar
  - Create Form widget with GlobalKey
  - Add TextFormField for habit name with validation (required)
  - Add TextFormField for description (optional)
  - Add save button that validates and creates habit
  - Navigate back on successful save
  - _Requirements: 8.1, 8.2, 8.10, 8.11, 8.12, 8.13_

- [x] 6.2 Create TrackingTypeSelector widget
  - Create `lib/features/habits/widgets/forms/tracking_type_selector.dart`
  - Use SegmentedButton with binary, value, timed options
  - Accept value and onChanged callback parameters
  - _Requirements: 8.3, 14.1, 14.9, 14.10, 14.11_

- [x] 6.3 Create GoalTypeSelector widget
  - Create `lib/features/habits/widgets/forms/goal_type_selector.dart`
  - Use SegmentedButton with none, minimum, maximum options
  - Accept value and onChanged callback parameters
  - _Requirements: 8.4, 14.2, 14.9, 14.10, 14.11_

- [x] 6.4 Create FrequencySelector widget
  - Create `lib/features/habits/widgets/forms/frequency_selector.dart`
  - Use SegmentedButton with daily, weekly, monthly options (custom for later phase)
  - Accept value and onChanged callback parameters
  - _Requirements: 8.7, 14.3, 14.9, 14.10, 14.11_

- [x] 6.5 Create IconPicker widget
  - Create `lib/features/habits/widgets/forms/icon_picker.dart`
  - Display grid of common emoji icons
  - Highlight selected icon
  - Accept selectedIcon and onIconSelected callback parameters
  - _Requirements: 8.8, 14.4, 14.9, 14.10, 14.11_

- [x] 6.6 Create ColorPicker widget
  - Create `lib/features/habits/widgets/forms/color_picker.dart`
  - Display row of color circles
  - Highlight selected color with check icon
  - Accept selectedColor and onColorSelected callback parameters
  - _Requirements: 8.9, 14.5, 14.9, 14.10, 14.11_

- [x] 6.7 Integrate form widgets into AddHabitScreen
  - Add TrackingTypeSelector to form
  - Add GoalTypeSelector to form
  - Add target value TextFormField (shown when goal type is minimum/maximum)
  - Add unit TextFormField (shown when tracking type is value)
  - Add FrequencySelector to form
  - Add IconPicker to form with default icon
  - Add ColorPicker to form with default color
  - Wire up all callbacks to update form state
  - _Requirements: 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9_

- [x] 6.8 Implement form submission in AddHabitScreen
  - Validate all required fields
  - Create Habit object with form data
  - Set default values for optional fields (activeDaysMode: all, requireMode: each, etc.)
  - Call habitsNotifierProvider.addHabit()
  - Show loading indicator during save
  - Handle errors with SnackBar
  - Navigate back on success
  - _Requirements: 8.10, 8.11, 8.12, 8.13_

- [x] 7. Add navigation and routing
- [x] 7.1 Register habits routes in router
  - Update `lib/app/router/router.dart`
  - Add '/habits' route with HabitsScreen
  - Add '/habits/add' route with AddHabitScreen
  - Add '/habits/:id' route with HabitDetailScreen (placeholder for now)
  - _Requirements: 1.4_

- [x] 7.2 Add Habits menu item to app shell drawer
  - Update `lib/app/shell/numu_app_shell.dart`
  - Add ListTile with "Habits" label and track_changes icon
  - Navigate to '/habits' on tap
  - _Requirements: 1.1, 1.2_

## Phase 2: Value Tracking & Streaks

- [x] 8. Implement streak calculation service
- [x] 8.1 Create streak-related database tables
  - Update DatabaseService to create habit_streaks table
  - Add streak_type enum file
  - _Requirements: 2.4, 4.7_

- [x] 8.2 Create HabitStreak model
  - Create `lib/features/habits/models/habit_streak.dart`
  - Define all fields from database schema
  - Implement fromMap, toMap, and copyWith methods
  - _Requirements: 4.9_

- [x] 8.3 Add streak methods to HabitRepository
  - Implement `getStreakForHabit(int habitId, StreakType type)` method
  - Implement `saveStreak(HabitStreak streak)` method
  - _Requirements: 3.1_

- [x] 8.4 Create StreakCalculationService class
  - Create `lib/features/habits/services/streak_calculation_service.dart`
  - Implement `recalculateStreaks(int habitId)` method
  - Implement `_calculateStreak(Habit habit, StreakType type)` private method
  - Implement `_isActiveDay(Habit habit, DateTime date)` helper
  - Implement `_checkDayCompletion(Habit habit, DateTime date, StreakType type)` helper
  - Implement `_checkBasicCompletion(Habit habit, List<HabitEvent> events)` helper
  - Walk backwards from today to calculate current streak
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.6, 12.8, 12.10_

- [x] 8.5 Integrate streak calculation into HabitsProvider
  - Update `logEvent()` method to call StreakCalculationService after logging
  - _Requirements: 12.10_

- [x] 9. Build habit detail screen
- [x] 9.1 Create HabitDetailProvider
  - Create `lib/features/habits/providers/habit_detail_provider.dart`
  - Use @riverpod with habitId parameter
  - Load habit, events, and streaks in build() method
  - Create HabitDetailState class to hold all data
  - _Requirements: 5.1_

- [x] 9.2 Create HabitDetailScreen layout
  - Create `lib/features/habits/screens/habit_detail_screen.dart`
  - Display habit icon, name, and description
  - Add edit button in app bar that navigates to edit screen
  - Add FAB to log new event
  - Use Consumer to watch habitDetailProvider
  - _Requirements: 10.1, 10.2, 10.8, 10.9, 10.10_

- [x] 9.3 Create HabitStreakDisplay widget
  - Create `lib/features/habits/widgets/habit_streak_display.dart`
  - Display current streak count
  - Display longest streak
  - Display consistency rate percentage
  - Accept habitId parameter and load streak data
  - _Requirements: 10.3, 10.4, 10.5_

- [x] 9.4 Add streak display to HabitDetailScreen
  - Integrate HabitStreakDisplay widget
  - Show completion streak by default
  - _Requirements: 10.3, 10.4, 10.5_

- [x] 9.5 Add recent activity list to HabitDetailScreen
  - Display list of recent events with timestamps
  - Show completion status or value for each event
  - Limit to last 10 events
  - _Requirements: 10.7_

- [x] 9.6 Update HabitListItem to show streak
  - Integrate HabitStreakDisplay widget into HabitListItem
  - Show compact version with just current streak
  - _Requirements: 7.4_

- [-] 10. Create log habit event dialog
- [ ] 10.1 Build LogHabitEventDialog for binary habits
  - Create `lib/features/habits/widgets/log_habit_event_dialog.dart`
  - Accept Habit parameter
  - Show habit name and icon
  - Add date picker defaulting to today
  - Add "Mark Complete" button for binary habits
  - Add optional notes TextField
  - Implement save action to create HabitEvent
  - Close dialog on success
  - _Requirements: 11.1, 11.2, 11.7, 11.9, 11.10, 11.11_

- [ ] 10.2 Extend LogHabitEventDialog for value habits
  - Add numeric TextField for value input when tracking type is value
  - Display unit label next to input
  - Calculate and show today's total after adding value
  - Show progress bar toward target
  - _Requirements: 11.3, 11.4_

- [ ] 10.3 Add time picker to LogHabitEventDialog
  - Add time picker for timed tracking type
  - Store time in time_recorded field
  - _Requirements: 11.4_

## Phase 3: Period-Based Habits

- [ ] 11. Implement period progress service
- [ ] 11.1 Create period progress database table
  - Update DatabaseService to create habit_period_progress table
  - _Requirements: 2.5_

- [ ] 11.2 Create HabitPeriodProgress model
  - Create `lib/features/habits/models/habit_period_progress.dart`
  - Define all fields from database schema
  - Implement fromMap, toMap, and copyWith methods
  - _Requirements: 4.10_

- [ ] 11.3 Add period progress methods to HabitRepository
  - Implement `getCurrentPeriodProgress(int habitId)` method
  - Implement `savePeriodProgress(HabitPeriodProgress progress)` method
  - _Requirements: 3.1_

- [ ] 11.4 Create PeriodProgressService class
  - Create `lib/features/habits/services/period_progress_service.dart`
  - Implement `recalculatePeriodProgress(int habitId)` method
  - Implement `_calculatePeriodProgress(Habit habit)` private method
  - Implement `_getCurrentPeriod(Habit habit)` helper for weekly/monthly
  - Implement `_getActiveDaysInPeriod(Habit habit, DateTime start, DateTime end)` helper
  - Implement `_calculateAdjustedTarget(Habit habit, int activeDaysCount)` helper
  - Implement `_calculateCurrentValue(Habit habit, List<HabitEvent> events, List<DateTime> activeDays)` helper
  - Implement `_checkPeriodCompletion()` helper with each/any/total logic
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.8, 13.9_

- [ ] 11.5 Integrate period progress into HabitsProvider
  - Update `logEvent()` method to call PeriodProgressService after logging
  - _Requirements: 13.8_

- [ ] 12. Add period progress display
- [ ] 12.1 Create HabitProgressIndicator widget
  - Create `lib/features/habits/widgets/habit_progress_indicator.dart`
  - Display progress bar for weekly/monthly habits
  - Show "X/Y" text (e.g., "3/5 days" or "8/10 km")
  - Accept habitId parameter and load period progress
  - _Requirements: 7.6_

- [ ] 12.2 Add progress indicator to HabitListItem
  - Show HabitProgressIndicator for weekly/monthly habits
  - Show today's status for daily habits
  - _Requirements: 7.5, 7.6_

- [ ] 12.3 Create HabitCalendarView widget
  - Create `lib/features/habits/widgets/habit_calendar_view.dart`
  - Display calendar grid showing completion history
  - Mark completed days with checkmark
  - Mark incomplete days with X or empty
  - Accept habitId parameter and load events
  - _Requirements: 10.6_

- [ ] 12.4 Add calendar view to HabitDetailScreen
  - Integrate HabitCalendarView widget
  - Show last 4 weeks by default
  - _Requirements: 10.6_

## Phase 4: Advanced Features

- [ ] 13. Add advanced habit configuration
- [ ] 13.1 Create time window enum and picker widget
  - Create `lib/features/habits/models/enums/time_window_mode.dart`
  - Create `lib/features/habits/widgets/forms/time_window_picker.dart`
  - Display toggle to enable time window
  - Show start/end time pickers when enabled
  - Show soft/hard mode selector
  - _Requirements: 14.7, 18.2, 18.3_

- [ ] 13.2 Create quality layer toggle widget
  - Create `lib/features/habits/widgets/forms/quality_layer_toggle.dart`
  - Display toggle to enable quality layer
  - Show TextField for quality label when enabled
  - _Requirements: 14.8, 18.2, 18.4_

- [ ] 13.3 Create weekday selector widget
  - Create `lib/features/habits/widgets/forms/weekday_selector.dart`
  - Display toggle for "All days" vs "Selected days"
  - Show checkboxes for Monday-Sunday when selected mode
  - _Requirements: 14.6, 18.2, 18.5_

- [ ] 13.4 Add advanced options section to AddHabitScreen
  - Add ExpansionTile labeled "Advanced Options"
  - Integrate TimeWindowPicker
  - Integrate QualityLayerToggle
  - Integrate WeekdaySelector
  - Add require mode selector (each/any/total)
  - Wire up all callbacks to form state
  - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5, 18.6_

- [ ] 13.5 Update LogHabitEventDialog for advanced features
  - Show time window indicator when enabled
  - Calculate and set within_time_window field
  - Show quality checkbox when enabled
  - Set quality_achieved field based on checkbox
  - _Requirements: 11.5, 11.6_

- [ ] 13.6 Update streak calculation for time window and quality
  - Implement `_checkTimeWindowCompletion()` in StreakCalculationService
  - Implement `_checkQualityCompletion()` in StreakCalculationService
  - Implement `_checkPerfectCompletion()` in StreakCalculationService
  - Calculate all four streak types (completion, time_window, quality, perfect)
  - _Requirements: 12.7_

- [ ] 13.7 Display advanced streak types in HabitDetailScreen
  - Show tabs or segments to switch between streak types
  - Display time window streak when enabled
  - Display quality streak when enabled
  - Display perfect streak when both enabled
  - _Requirements: 10.3, 18.7_

- [ ] 14. Build edit habit screen
- [ ] 14.1 Create EditHabitScreen
  - Create `lib/features/habits/screens/edit_habit_screen.dart`
  - Load existing habit data using habitId parameter
  - Reuse all form widgets from AddHabitScreen
  - Pre-populate all fields with existing values
  - Implement save action to update habit
  - Add delete button with confirmation dialog
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_

- [ ] 14.2 Add edit navigation from HabitDetailScreen
  - Add edit icon button to app bar
  - Navigate to EditHabitScreen with habitId
  - _Requirements: 10.8_

## Phase 5: Polish & Optimization

- [ ] 15. Implement categories
- [ ] 15.1 Create Category model
  - Create `lib/features/habits/models/category.dart`
  - Define fields from database schema
  - Implement fromMap, toMap, and copyWith methods
  - _Requirements: 4.8_

- [ ] 15.2 Create CategoryRepository
  - Create `lib/features/habits/repositories/category_repository.dart`
  - Implement getCategories() method
  - Implement createCategory() method
  - Seed default system categories on first run
  - _Requirements: 3.1_

- [ ] 15.3 Create CategoriesProvider
  - Create `lib/features/habits/providers/categories_provider.dart`
  - Load and expose categories list
  - _Requirements: 5.1_

- [ ] 15.4 Add category selector to AddHabitScreen
  - Display dropdown or chips for category selection
  - Load categories from CategoriesProvider
  - Allow "None" option
  - _Requirements: 8.1_

- [ ] 15.5 Display category in HabitListItem
  - Show category name or icon if set
  - _Requirements: 7.1_

- [ ] 16. Add error handling and logging
- [ ] 16.1 Create custom exception classes
  - Create HabitException, HabitValidationException, HabitNotFoundException, DatabaseException
  - _Requirements: 15.4, 15.6_

- [ ] 16.2 Add validation to HabitRepository
  - Validate habit name is not empty
  - Validate target value when goal type requires it
  - Throw HabitValidationException on validation failure
  - Wrap database errors in DatabaseException
  - _Requirements: 3.1, 15.4_

- [ ] 16.3 Add error logging to providers
  - Use CoreLoggingUtility to log errors
  - Log with context (habit id, operation, etc.)
  - _Requirements: 15.7_

- [ ] 16.4 Improve error display in UI
  - Show specific error messages for validation errors
  - Show generic message for database errors
  - Add retry button for recoverable errors
  - _Requirements: 15.4, 15.5_

- [ ] 17. Performance optimization
- [ ] 17.1 Add database indexes
  - Verify all indexes are created in DatabaseService
  - Test query performance with large datasets
  - _Requirements: 2.6, 17.1, 17.4_

- [ ] 17.2 Implement streak caching
  - Only recalculate streaks when events are added
  - Check last_calculated_at timestamp
  - Skip calculation if cache is fresh (< 1 hour old)
  - _Requirements: 16.4, 17.5_

- [ ] 17.3 Implement period progress caching
  - Only recalculate when events are added to current period
  - Create new period record when boundary crossed
  - _Requirements: 16.4, 17.5_

- [ ] 17.4 Add optimistic updates to quick log
  - Update UI immediately when quick log button tapped
  - Revert if operation fails
  - _Requirements: 17.2_

- [ ] 17.5 Add debouncing to quick log button
  - Prevent multiple rapid taps
  - Use 300ms debounce timer
  - _Requirements: 17.7_

- [ ] 18. UI polish and animations
- [ ] 18.1 Add loading states to all async operations
  - Show progress indicators during saves
  - Disable buttons while loading
  - _Requirements: 6.4_

- [ ] 18.2 Add success feedback
  - Show SnackBar on successful habit creation
  - Show SnackBar on successful event logging
  - _Requirements: 15.1_

- [ ] 18.3 Add animations to habit list
  - Animate item addition/removal
  - Add fade-in animation for list items
  - _Requirements: 6.1_

- [ ] 18.4 Improve form UX
  - Add input hints and helper text
  - Show validation errors inline
  - Auto-focus first field
  - _Requirements: 8.11_

- [ ] 18.5 Add empty state illustrations
  - Use custom illustrations or icons
  - Make empty states more engaging
  - _Requirements: 15.1, 15.2_

---

## Notes

- Each task is designed to be completed independently
- Tasks within a phase can be worked on sequentially
- All code should be tested after each task completion
- Database migrations should be handled carefully to avoid data loss
- Follow existing code patterns from the tasks feature
- Use Riverpod code generation throughout
- Keep widgets small and focused on single responsibility
