# Implementation Plan

- [x] 1. Extend data models and database schema
  - Add `isPinnedToSidebar` field to Category model
  - Add `categoryId` field to Task model
  - Create database migration to add `is_pinned_to_sidebar` column to categories table
  - Create database migration to add `category_id` column to tasks table with foreign key constraint
  - Add database indexes for `habits.category_id` and `tasks.category_id`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 9.1, 9.2_

- [x] 2. Extend CategoryRepository with new methods
  - Implement `getCategoryById()` method
  - Implement `updateCategory()` method
  - Implement `deleteCategory()` method with transaction to unassign from habits/tasks
  - Implement `getHabitsByCategory()` method
  - Implement `getTasksByCategory()` method
  - Implement `getHabitCountForCategory()` method
  - Implement `getTaskCountForCategory()` method
  - Implement `toggleCategorySidebarPin()` method
  - Implement `getPinnedCategories()` method
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 3. Extend TaskRepository with category support
  - Implement `updateTaskCategory()` method
  - Implement `getTasksByCategory()` method
  - Implement `unassignCategoryFromTasks()` method
  - Update existing Task CRUD methods to handle categoryId field
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1, 8.2_

- [x] 4. Extend HabitRepository with category query methods
  - Implement `getHabitsByCategory()` method
  - Implement `unassignCategoryFromHabits()` method
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 7.1, 7.2_

- [x] 5. Extend CategoriesProvider with mutation methods
  - Implement `updateCategory()` method
  - Implement `deleteCategory()` method with proper state updates
  - Implement `toggleSidebarPin()` method
  - Add error handling for all mutation methods
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 9.1, 9.2, 9.5_

- [x] 6. Create CategoryDetailProvider for detail screen state
  - Create `CategoryDetailState` class with category, habits, and tasks
  - Implement `CategoryDetailNotifier` with `build()` method to load composite state
  - Implement `refresh()` method
  - Add error handling for missing categories
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 7. Extend NavigationProvider to support dynamic category items
  - Modify `_loadNavigationItems()` to include pinned categories
  - Create method to convert Category to NavigationItem
  - Implement logic to position category items before settings
  - Add method to remove category navigation items when unpinned/deleted
  - Update navigation item order calculation
  - _Requirements: 9.2, 9.3, 9.4, 9.6_

- [x] 8. Create Category List Screen
  - Create `CategoriesScreen` widget with app bar and FAB
  - Implement category grid/list view using CategoriesProvider
  - Create `CategoryCard` widget to display category with icon, color, name, and counts
  - Implement navigation to category detail screen on tap
  - Implement empty state when no categories exist
  - Add loading and error states
  - Implement swipe-to-delete or long-press menu for edit/delete actions
  - _Requirements: 1.1, 1.2, 3.1, 3.5, 4.1_

- [x] 9. Create Create/Edit Category Screens
  - Create `CreateCategoryScreen` with form fields for name, description, icon, color
  - Create `EditCategoryScreen` with pre-filled form fields
  - Implement form validation (name required, max lengths)
  - Reuse existing icon picker widget from habits feature
  - Reuse existing color picker widget from habits feature
  - Implement save action that calls CategoriesProvider
  - Implement cancel action with unsaved changes warning
  - Add loading state during save operation
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 10. Create Category Details Screen
  - Create `CategoryDetailScreen` widget with category header
  - Display category icon, color, and name in header
  - Implement pin/unpin toggle button
  - Implement edit button that navigates to EditCategoryScreen
  - Implement delete button with confirmation dialog
  - Create "Habits" section displaying habits from CategoryDetailProvider
  - Create "Tasks" section displaying tasks from CategoryDetailProvider
  - Implement empty states for habits and tasks sections
  - Implement navigation to habit/task detail screens on tap
  - Add loading and error states
  - _Requirements: 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 4.5, 9.1, 9.5_

- [x] 11. Add category filter to Habits Screen
  - Add category filter dropdown to HabitsScreen app bar
  - Populate dropdown with all categories plus "All" option
  - Implement filter state management (local state)
  - Update habits list to show filtered results when category selected
  - Display active filter indicator
  - Display filtered habit count
  - Implement "Clear filter" action
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 12. Add category filter to Tasks Screen
  - Add category filter dropdown to TasksScreen app bar
  - Populate dropdown with all categories plus "All" option
  - Implement filter state management (local state)
  - Update tasks list to show filtered results when category selected
  - Display active filter indicator
  - Display filtered task count
  - Implement "Clear filter" action
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 13. Add category assignment to Add/Edit Habit Screens
  - Add category selection dropdown to AddHabitScreen
  - Add category selection dropdown to EditHabitScreen with current value
  - Populate dropdown with all available categories
  - Make category field optional (nullable)
  - Display selected category with icon and color
  - Update habit save logic to include categoryId
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 14. Add category assignment to Add/Edit Task Screens
  - Add category selection dropdown to Add Task UI
  - Add category selection dropdown to Edit Task UI with current value
  - Populate dropdown with all available categories
  - Make category field optional (nullable)
  - Display selected category with icon and color
  - Update task save logic to include categoryId
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 15. Display category in habit and task list items
  - Update `HabitListItem` widget to display category badge
  - Update task list item widget to display category badge
  - Show category icon and color in badge
  - Handle null category gracefully
  - _Requirements: 5.5, 6.5_

- [x] 16. Add category routes to router configuration
  - Add `/categories` route for Category List Screen
  - Add `/categories/create` route for Create Category Screen
  - Add `/categories/:id` route for Category Details Screen
  - Add `/categories/:id/edit` route for Edit Category Screen
  - Ensure all routes use ShellRoute for consistent navigation
  - _Requirements: 1.1, 1.2, 2.1, 4.1, 9.3_

- [x] 17. Implement category deletion with confirmation and cleanup
  - Create confirmation dialog showing habit/task counts
  - Display warning message about unassigning categories
  - Implement deletion logic that unassigns from habits/tasks first
  - Remove from sidebar navigation if pinned
  - Refresh all relevant providers after deletion
  - Handle errors gracefully with user feedback
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.6_

- [x] 18. Add comprehensive error handling
  - Implement validation error display in forms
  - Add database error handling with user-friendly messages
  - Handle navigation to deleted categories gracefully
  - Add retry mechanisms for failed operations
  - Implement proper error logging
  - _Requirements: All requirements (error handling is cross-cutting)_

- [ ] 19. Implement accessibility features
  - Add semantic labels to all interactive elements
  - Ensure color contrast meets WCAG AA standards
  - Add screen reader announcements for state changes
  - Test with screen reader enabled
  - Add tooltips for icon-only buttons
  - _Requirements: All requirements (accessibility is cross-cutting)_

- [ ] 20. Write unit tests for repositories and providers
  - Write unit tests for CategoryRepository methods
  - Write unit tests for TaskRepository category methods
  - Write unit tests for HabitRepository category methods
  - Write unit tests for CategoriesProvider mutations
  - Write unit tests for CategoryDetailProvider
  - Test error handling and edge cases
  - _Requirements: All requirements_

- [ ] 21. Write widget tests for category screens
  - Write widget tests for CategoriesScreen
  - Write widget tests for CreateCategoryScreen form validation
  - Write widget tests for EditCategoryScreen
  - Write widget tests for CategoryDetailScreen
  - Write widget tests for category filter dropdowns
  - Test empty states and error states
  - _Requirements: All requirements_

- [ ] 22. Write integration tests for end-to-end workflows
  - Test complete category creation and assignment workflow
  - Test category filtering in habits and tasks
  - Test category pinning to sidebar and navigation
  - Test category deletion and cleanup
  - Test cross-feature integration (habits, tasks, navigation)
  - _Requirements: All requirements_
