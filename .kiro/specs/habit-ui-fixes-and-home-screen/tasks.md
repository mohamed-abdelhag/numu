# Implementation Plan

- [ ] 1. Fix tasks screen sidebar issue
  - Remove the `Scaffold` wrapper from `TasksScreen` widget that conflicts with shell's scaffold
  - Ensure `NumuAppBar` properly connects to shell's drawer controller
  - Verify drawer button opens the sidebar from tasks screen
  - _Requirements: 6.1, 6.2_

- [ ] 2. Fix shell navigation stability
  - Review router configuration in `lib/app/router/router.dart` to ensure all routes use `ShellRoute`
  - Add error boundary in `NumuAppShell` to catch and recover from navigation errors
  - Add initialization check in `main.dart` to ensure shell is ready before first navigation
  - Test app startup and resume from background to verify shell stability
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 3. Fix calendar edit value loading and quality layer logic
  - [ ] 3.1 Modify `LogHabitEventDialog` to load existing event data for the selected date
    - Add `_loadExistingEventForDate()` helper method to fetch event from repository
    - Pre-populate `_valueController` with existing value in `initState()`
    - Pre-populate `_qualityAchieved` checkbox with existing quality status
    - _Requirements: 3.1, 3.2_
  
  - [ ] 3.2 Verify and document quality layer as binary attribute
    - Review save logic to ensure quality is stored as boolean attribute on the value event
    - Add code comments clarifying that quality applies to the value, not as separate counter
    - Verify that logging "20 reps with focused quality" creates one event with valueDelta=20 and qualityAchieved=true
    - _Requirements: 3.3, 3.4_

- [ ] 4. Fix habit card value display
  - Modify `HabitCard` widget to accept and display current day's value
  - Update habit card usage sites to pass today's logged value from provider
  - Display value with unit for value-based habits
  - Show "0" or empty state indicator when no value logged
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 5. Fix habit card streak and percentage accuracy
  - [ ] 5.1 Calculate accurate streak numbers
    - Fetch current streak from habit detail provider or streak service
    - Replace placeholder `score` prop with actual streak data
    - Update `HabitCard` to display real streak numbers
    - _Requirements: 7.1_
  
  - [ ] 5.2 Calculate accurate completion percentage
    - Fetch period progress data from provider
    - Calculate percentage based on actual progress vs target
    - Replace placeholder `overallProgress` prop with calculated percentage
    - _Requirements: 7.2_

- [ ] 6. Integrate quality layer details in habit detail screen
  - Remove `_buildStreakTypeSelector` widget when quality layer is enabled
  - Modify streak display section to show both completion and quality streaks simultaneously
  - Only render quality streak section when `habit.qualityLayerEnabled == true`
  - Display quality streak with clear labeling (e.g., "Quality Streak: Y days ⭐")
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 7. Implement habit card quick action buttons
  - [ ] 7.1 Create `HabitQuickActionButton` widget
    - Implement logic for binary habits without quality layer (simple checkbox)
    - Implement logic for binary habits with quality layer (checkbox with quality dialog on second click)
    - Implement logic for value habits (plus button to increment, full dialog when goal reached)
    - Implement logic for timed habits (add button opens log dialog)
    - _Requirements: 7.3, 7.4, 7.5, 7.6, 7.7_
  
  - [ ] 7.2 Add special handling for minimum goal habits with quality layer
    - Implement quick action to only increment value (no quality selection)
    - Add code comment explaining quality layer must be set via calendar in detail screen
    - _Requirements: 7.8, 7.9_
  
  - [ ] 7.3 Integrate quick action buttons into `HabitCard`
    - Add quick action button to habit card layout
    - Wire up button actions to log events via provider
    - Handle success and error states with snackbar feedback
    - _Requirements: 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ] 8. Implement unified home screen
  - [ ] 8.1 Create `DailyItem` model
    - Define `DailyItem` class with all required fields
    - Define `DailyItemType` enum for habit and task types
    - _Requirements: 4.9_
  
  - [ ] 8.2 Create `DailyItemsProvider`
    - Fetch all habits active today based on frequency and active days
    - Fetch all tasks due today
    - Combine habits and tasks into unified `DailyItem` list
    - Calculate completion percentage
    - Sort items by scheduled time (time window for habits, due time for tasks)
    - Place items without specific time at end of list
    - _Requirements: 4.8, 4.9_
  
  - [ ] 8.3 Create `DailyProgressHeader` widget
    - Display welcome message with user name from profile provider
    - Show summary count of habits and tasks
    - Render progress bar with completion percentage
    - Display motivational message based on percentage ranges
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_
  
  - [ ] 8.4 Create `DailyItemCard` widget
    - Display habit or task in unified card format
    - Show icon, title, and scheduled time
    - Include quick action button (reuse logic from habit quick actions)
    - Make card tappable to navigate to detail screen
    - _Requirements: 4.8_
  
  - [ ] 8.5 Implement new home screen layout
    - Replace placeholder home screen with new implementation
    - Add `DailyProgressHeader` at top
    - Render list of `DailyItemCard` widgets from provider
    - Handle loading and error states
    - Handle empty state when no items due today
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9_
