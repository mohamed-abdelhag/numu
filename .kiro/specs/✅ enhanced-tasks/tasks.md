# Implementation Plan

- [x] 1. Update database schema and implement migration
  - Add database migration from version 6 to version 7
  - Rename `text` column to `title` in tasks table
  - Add `description`, `due_date`, `created_at`, and `updated_at` columns
  - Create index on `due_date` column for performance
  - Test migration with existing data to ensure no data loss
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Enhance Task model with new fields
  - [x] 2.1 Update Task class with new fields
    - Add `title` field (rename from `text`)
    - Add `description` field (nullable String)
    - Add `dueDate` field (nullable DateTime)
    - Add `createdAt` and `updatedAt` fields (DateTime)
    - Update constructor with new parameters
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 2.2 Implement serialization methods
    - Update `toMap()` method to include new fields
    - Update `fromMap()` factory to parse new fields
    - Handle DateTime to ISO 8601 string conversion
    - Update `copyWith()` method with new parameters
    - _Requirements: 1.4, 1.5_

  - [x] 2.3 Add helper methods for due date logic
    - Implement `isOverdue` getter
    - Implement `isDueToday` getter
    - Implement `isDueSoon` getter (within 3 days)
    - Implement `dueDateFormatted` getter for human-readable dates
    - _Requirements: 2.5_

- [x] 3. Update TasksRepository with enhanced methods
  - [x] 3.1 Update existing CRUD methods
    - Modify `getTasks()` to handle new fields
    - Modify `createTask()` to save new fields
    - Modify `updateTask()` to update new fields
    - Add `getTaskById()` method for single task retrieval
    - _Requirements: 1.4, 1.5, 4.4_

  - [x] 3.2 Add query methods for due date filtering
    - Implement `getOverdueTasks()` method
    - Implement `getTasksDueToday()` method
    - Implement `getTasksDueSoon()` method
    - Add optional filters to `getTasks()` (dueBefore, dueAfter)
    - _Requirements: 2.5_

- [x] 4. Update TasksProvider for new functionality
  - Update `addTask()` method to accept title, description, dueDate, and categoryId
  - Update `updateTask()` method to handle all new fields
  - Add `taskDetail` provider for single task fetching
  - Ensure proper state management for async operations
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.4_

- [x] 5. Create reusable widget components
  - [x] 5.1 Create TaskListItem widget
    - Display task title with completion checkbox
    - Show truncated description (2 lines max)
    - Display due date badge with color coding
    - Show category badge if assigned
    - Handle tap to navigate to detail screen
    - Apply visual states (overdue, completed, etc.)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 5.2 Create DueDateBadge widget
    - Display due date with appropriate color coding
    - Show warning icon for overdue tasks
    - Format date as relative ("Today", "Tomorrow") or absolute
    - Handle null due dates gracefully
    - _Requirements: 2.3, 2.4, 2.5_

  - [x] 5.3 Create TaskForm widget
    - Build form with title, description, due date, and category fields
    - Implement title validation (required, non-empty)
    - Add date picker for due date selection
    - Integrate category dropdown
    - Add accessibility labels for all form fields
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 6.2, 6.3_

- [x] 6. Create AddTaskScreen
  - Build screen layout with AppBar and form
  - Use TaskForm widget for input fields
  - Implement Save action with validation
  - Implement Cancel action to discard changes
  - Show validation errors inline
  - Navigate back to tasks list on successful save
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 7. Create EditTaskScreen
  - Build screen layout similar to AddTaskScreen
  - Pre-fill TaskForm with existing task data
  - Implement Update action with validation
  - Implement Cancel action to discard changes
  - Add Delete option in app bar menu
  - Navigate back on successful update or cancel
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 8. Create TaskDetailScreen
  - [x] 8.1 Build detail screen layout
    - Display task title prominently at top
    - Show full description without truncation
    - Display due date with day of week and formatted date
    - Show category with color and icon
    - Add completion toggle checkbox
    - Include Edit and Delete action buttons
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [x] 8.2 Implement navigation and actions
    - Set up route with task ID parameter
    - Fetch task data using taskDetail provider
    - Handle Edit button to navigate to EditTaskScreen
    - Handle Delete button with confirmation dialog
    - Handle completion toggle
    - Navigate back after delete
    - _Requirements: 5.1, 5.6_

- [x] 9. Refactor TasksScreen
  - [x] 9.1 Update UI to use new components
    - Replace inline task items with TaskListItem widgets
    - Remove inline add/edit functionality
    - Add FloatingActionButton for navigation to AddTaskScreen
    - Update task list rendering to display new fields
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 7.1, 7.2_

  - [x] 9.2 Maintain existing functionality
    - Ensure category filter continues to work
    - Preserve task completion toggle
    - Maintain task deletion functionality
    - Handle tasks with and without due dates
    - Handle tasks with and without categories
    - _Requirements: 7.3, 7.4, 7.5_

  - [x] 9.3 Add sorting options
    - Implement sort by due date
    - Implement sort by created date
    - Implement alphabetical sort by title
    - Add sort menu in app bar
    - Persist sort preference
    - _Requirements: 7.1, 7.2_

- [x] 10. Set up navigation routes
  - Add route for AddTaskScreen
  - Add route for EditTaskScreen with task ID parameter
  - Add route for TaskDetailScreen with task ID parameter
  - Update navigation from TasksScreen to new screens
  - Update navigation from TaskDetailScreen to EditTaskScreen
  - _Requirements: 5.1_

- [x] 11. Update category integration
  - Ensure category assignment works in AddTaskScreen
  - Ensure category assignment works in EditTaskScreen
  - Display category in TaskListItem
  - Display category in TaskDetailScreen with navigation
  - Handle category deletion (set categoryId to null)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 12. Implement error handling and validation
  - Add title validation in TaskForm
  - Display validation errors inline
  - Handle database errors with user-friendly messages
  - Handle navigation errors (invalid task ID)
  - Add confirmation dialog for task deletion
  - _Requirements: 3.6, 3.7, 4.3_

- [x] 13. Add accessibility features
  - Add semantic labels to all interactive elements
  - Ensure proper tab order in forms
  - Add screen reader announcements for actions
  - Verify color contrast meets WCAG AA standards
  - Test with system font scaling
  - _Requirements: All requirements (accessibility is cross-cutting)_

- [ ]* 14. Write unit tests for core functionality
  - Write tests for Task model serialization/deserialization
  - Write tests for Task helper methods (isOverdue, isDueToday, etc.)
  - Write tests for TasksRepository CRUD operations
  - Write tests for TasksProvider state management
  - Write tests for date formatting and validation logic
  - _Requirements: All requirements_

- [ ]* 15. Write widget tests
  - Write tests for TaskListItem rendering and interactions
  - Write tests for TaskForm validation logic
  - Write tests for DueDateBadge visual states
  - Write tests for screen navigation flows
  - _Requirements: All requirements_
