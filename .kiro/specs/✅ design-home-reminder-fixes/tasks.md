# Implementation Plan

- [x] 1. Restructure Habit Card Layout
  - [x] 1.1 Refactor habit card header row to remove badges
    - Remove streak badge, score badge, and value badge from the header Row widget
    - Keep only icon, name/description, and quick action button in header
    - _Requirements: 1.1_
  - [x] 1.2 Create dedicated badge row widget method
    - Add `_buildBadgeRow()` method that renders badges in a horizontal Wrap widget
    - Include streak badge, score badge, and conditionally value badge
    - Position between header and weekly progress sections
    - _Requirements: 1.2, 1.3, 1.4_
  - [x] 1.3 Write property test for badge row structure
    - **Property 2: Badge row contains all badges**
    - **Property 3: Value badge conditional rendering**
    - **Validates: Requirements 1.2, 1.3**

- [x] 2. Fix Home Screen Real-time Updates
  - [x] 2.1 Verify and fix callback chain in DailyItemCard
    - Ensure `onActionComplete` callback is properly passed to child widgets
    - Verify `HabitQuickActionButton` triggers the callback after completion
    - _Requirements: 2.1, 2.3_
  - [x] 2.2 Update daily items provider refresh logic
    - Ensure provider invalidation triggers fresh data fetch
    - Verify completion percentage recalculation on refresh
    - _Requirements: 2.2, 2.4_
  - [x] 2.3 Write property test for completion percentage calculation
    - **Property 4: Completion percentage calculation**
    - **Validates: Requirements 2.2**

- [x] 3. Checkpoint - Ensure habit card and home screen changes work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Add Notification Permission Settings Section
  - [x] 4.1 Create notification permission status provider
    - Create a Riverpod provider to check and cache notification permission status
    - Use `NotificationService.areNotificationsEnabled()` for status check
    - _Requirements: 3.1, 3.5_
  - [x] 4.2 Add notifications section to settings screen
    - Create `_buildNotificationsSection()` method in settings screen
    - Display current permission status with appropriate icon and text
    - Add tap handler to request permissions or open device settings
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 4.3 Handle permanently denied permission state
    - Detect when permissions are permanently denied
    - Display guidance message to open device settings
    - Add button to open app settings using `openAppSettings()` from permission_handler
    - _Requirements: 3.6_
  - [x] 4.4 Write property test for permission status display
    - **Property 5: Permission status display consistency**
    - **Validates: Requirements 3.2, 3.4, 3.6**

- [x] 5. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

