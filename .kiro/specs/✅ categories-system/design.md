# Categories System Design Document

## Overview

The categories system enables users to organize habits and tasks into custom categories with visual identifiers (color and icon). Users can create, edit, and delete categories, assign them to habits and tasks, filter content by category, and optionally pin category detail screens to the side panel for quick access.

This design leverages the existing category infrastructure (Category model, CategoryRepository, and CategoriesProvider) and extends it with new screens, enhanced repository methods, and integration points with the habits and tasks features.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐│
│  │ Category List    │  │ Category Details │  │ Create/Edit││
│  │ Screen           │  │ Screen           │  │ Screens    ││
│  └──────────────────┘  └──────────────────┘  └────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                         State Layer                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐│
│  │ Categories       │  │ Habits           │  │ Tasks      ││
│  │ Provider         │  │ Provider         │  │ Provider   ││
│  └──────────────────┘  └──────────────────┘  └────────────┘│
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Navigation       │  │ Category Detail  │                │
│  │ Provider         │  │ Provider         │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                       Repository Layer                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐│
│  │ Category         │  │ Habit            │  │ Task       ││
│  │ Repository       │  │ Repository       │  │ Repository ││
│  └──────────────────┘  └──────────────────┘  └────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                         Data Layer                           │
│                    DatabaseService (SQLite)                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐│
│  │ categories       │  │ habits           │  │ tasks      ││
│  │ table            │  │ table            │  │ table      ││
│  └──────────────────┘  └──────────────────┘  └────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Design Rationale

1. **Leverage Existing Infrastructure**: The Category model, CategoryRepository, and CategoriesProvider already exist. We'll extend these rather than rebuild.

2. **Separation of Concerns**: Each layer has a clear responsibility:
   - Presentation: UI and user interactions
   - State: Business logic and state management using Riverpod
   - Repository: Data access abstraction
   - Data: Persistent storage

3. **Reactive State Management**: Using Riverpod's AsyncNotifier pattern ensures UI automatically updates when data changes.

4. **Database-First Approach**: SQLite provides reliable persistence with ACID guarantees, suitable for local-first mobile apps.

## Components and Interfaces

### 1. Data Models

#### Category Model (Existing - Minor Extensions)
```dart
class Category {
  final int? id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;
  final bool isPinnedToSidebar; // NEW FIELD
}
```

**Design Decision**: Add `isPinnedToSidebar` field to track which categories appear in the side panel. This is simpler than maintaining a separate table and aligns with the single-responsibility principle for the Category model.

#### Task Model (Extension Required)
```dart
class Task {
  final int? id;
  final String text;
  final bool isCompleted;
  final int? categoryId; // NEW FIELD
}
```

**Design Decision**: Add `categoryId` to Task model to enable category assignment. This follows the same pattern as the Habit model.

### 2. Database Schema

#### Categories Table (Existing - Add Column)
```sql
ALTER TABLE categories ADD COLUMN is_pinned_to_sidebar INTEGER NOT NULL DEFAULT 0;
```

#### Tasks Table (Extension Required)
```sql
ALTER TABLE tasks ADD COLUMN category_id INTEGER;
ALTER TABLE tasks ADD FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;
```

**Design Decision**: Use `ON DELETE SET NULL` for category foreign keys. When a category is deleted, associated habits/tasks remain but lose their category assignment. This prevents data loss and gives users flexibility.

### 3. Repository Layer

#### CategoryRepository (Extensions)

**New Methods**:
```dart
// CRUD operations
Future<Category> getCategoryById(int id);
Future<Category> updateCategory(Category category);
Future<void> deleteCategory(int id);

// Category-content relationships
Future<List<Habit>> getHabitsByCategory(int categoryId);
Future<List<Task>> getTasksByCategory(int categoryId);
Future<int> getHabitCountForCategory(int categoryId);
Future<int> getTaskCountForCategory(int categoryId);

// Sidebar pinning
Future<void> toggleCategorySidebarPin(int categoryId);
Future<List<Category>> getPinnedCategories();
```

**Design Rationale**: 
- Repository handles all database interactions, keeping business logic separate
- Relationship queries (getHabitsByCategory, getTasksByCategory) centralize category-content lookups
- Count methods enable efficient UI updates without loading full lists

#### TaskRepository (Extensions)

**New Methods**:
```dart
Future<void> updateTaskCategory(int taskId, int? categoryId);
Future<List<Task>> getTasksByCategory(int categoryId);
Future<void> unassignCategoryFromTasks(int categoryId);
```

#### HabitRepository (Extensions)

**New Methods**:
```dart
Future<List<Habit>> getHabitsByCategory(int categoryId);
Future<void> unassignCategoryFromHabits(int categoryId);
```

### 4. State Management Layer

#### CategoriesProvider (Extensions)

**New Methods**:
```dart
Future<void> updateCategory(Category category);
Future<void> deleteCategory(int categoryId);
Future<void> toggleSidebarPin(int categoryId);
```

**Design Decision**: Provider methods handle state updates and trigger UI refreshes. All mutations go through the provider to maintain single source of truth.

#### CategoryDetailProvider (New)

```dart
@riverpod
class CategoryDetailNotifier extends _$CategoryDetailNotifier {
  @override
  Future<CategoryDetailState> build(int categoryId) async {
    // Load category, habits, and tasks
  }
  
  Future<void> refresh();
}

class CategoryDetailState {
  final Category category;
  final List<Habit> habits;
  final List<Task> tasks;
}
```

**Design Rationale**: Dedicated provider for category detail screen manages the composite state (category + habits + tasks) efficiently. This prevents multiple database queries and ensures consistent data.

#### HabitsProvider & TasksProvider (Extensions)

**New Methods**:
```dart
// HabitsProvider
Future<List<Habit>> getHabitsByCategory(int? categoryId);

// TasksProvider
Future<List<Task>> getTasksByCategory(int? categoryId);
```

### 5. Presentation Layer

#### Category List Screen

**Route**: `/categories`

**Features**:
- Display all categories in a grid or list
- Show category name, icon, color, and item counts
- FAB to create new category
- Tap category to navigate to detail screen
- Long-press or swipe for edit/delete actions

**UI Components**:
- CategoryCard widget (displays category with visual styling)
- Empty state when no categories exist
- Loading and error states

#### Create/Edit Category Screen

**Routes**: `/categories/create`, `/categories/:id/edit`

**Features**:
- Form with fields: name (required), description (optional), icon (picker), color (picker)
- Icon picker with common icons (similar to habit icon picker)
- Color picker with predefined palette
- Save button (validates and saves)
- Cancel button (discards changes)

**Validation**:
- Name: required, max 50 characters
- Description: optional, max 200 characters
- Icon: required
- Color: required

**Design Decision**: Reuse existing icon and color picker widgets from habits feature to maintain consistency and reduce code duplication.

#### Category Details Screen

**Route**: `/categories/:id`

**Features**:
- Header showing category name, icon, color
- Pin/Unpin button to toggle sidebar visibility
- Edit and Delete buttons
- Two sections: "Habits" and "Tasks"
- Each section shows items assigned to this category
- Empty state for each section when no items
- Tap habit/task to navigate to detail screen

**UI Layout**:
```
┌─────────────────────────────────────┐
│ [Icon] Category Name                │
│ [Pin Button] [Edit] [Delete]        │
├─────────────────────────────────────┤
│ Habits (3)                          │
│ ┌─────────────────────────────────┐ │
│ │ Habit 1                         │ │
│ │ Habit 2                         │ │
│ │ Habit 3                         │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Tasks (5)                           │
│ ┌─────────────────────────────────┐ │
│ │ Task 1                          │ │
│ │ Task 2                          │ │
│ │ ...                             │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### Habits Screen (Extensions)

**New Features**:
- Category filter dropdown in app bar
- Filter shows all categories + "All" option
- When filtered, show only habits in selected category
- Display active filter indicator
- Show filtered count

**Design Decision**: Use dropdown instead of chips to save screen space. The filter persists during the session but resets on app restart (no persistence needed per requirements).

#### Tasks Screen (Extensions)

**New Features**:
- Category filter dropdown in app bar (same as habits)
- Filter shows all categories + "All" option
- When filtered, show only tasks in selected category
- Display active filter indicator
- Show filtered count

#### Add/Edit Habit Screen (Extensions)

**New Features**:
- Category selection dropdown
- Shows all available categories
- Optional field (can be null)
- Display selected category with icon and color

#### Add/Edit Task Screen (Extensions)

**New Features**:
- Category selection dropdown (same as habits)
- Shows all available categories
- Optional field (can be null)
- Display selected category with icon and color

#### Side Panel Navigation (Extensions)

**New Features**:
- Dynamically add navigation items for pinned categories
- Category nav items show category icon and color
- Positioned after main nav items, before settings
- Tap to navigate to category detail screen
- Auto-remove when category unpinned or deleted

**Navigation Item Structure**:
```dart
NavigationItem(
  id: 'category_${categoryId}',
  label: categoryName,
  icon: categoryIcon,
  route: '/categories/$categoryId',
  isHome: false,
  isEnabled: true,
  order: dynamicOrder,
)
```

**Design Decision**: Use `category_${categoryId}` as ID prefix to distinguish category nav items from system nav items. This enables easy filtering and management.

## Data Flow

### Creating a Category

```
User Input (Create Screen)
    ↓
CategoriesProvider.addCategory()
    ↓
CategoryRepository.createCategory()
    ↓
DatabaseService (INSERT)
    ↓
CategoriesProvider.refresh()
    ↓
UI Updates (Category List)
```

### Assigning Category to Habit

```
User Selection (Edit Habit Screen)
    ↓
HabitsProvider.updateHabit()
    ↓
HabitRepository.updateHabit()
    ↓
DatabaseService (UPDATE habits SET category_id)
    ↓
HabitsProvider.refresh()
    ↓
UI Updates (Habit Display)
```

### Filtering Habits by Category

```
User Selection (Filter Dropdown)
    ↓
Local State Update (selectedCategoryId)
    ↓
HabitsProvider.getHabitsByCategory(categoryId)
    ↓
HabitRepository.getHabitsByCategory()
    ↓
DatabaseService (SELECT WHERE category_id)
    ↓
UI Updates (Filtered List)
```

### Pinning Category to Sidebar

```
User Action (Pin Button)
    ↓
CategoriesProvider.toggleSidebarPin()
    ↓
CategoryRepository.toggleCategorySidebarPin()
    ↓
DatabaseService (UPDATE categories SET is_pinned_to_sidebar)
    ↓
NavigationProvider.refresh()
    ↓
UI Updates (Side Panel)
```

### Deleting a Category

```
User Confirmation (Delete Dialog)
    ↓
CategoriesProvider.deleteCategory()
    ↓
CategoryRepository.deleteCategory()
    ↓
DatabaseService (DELETE + UPDATE habits/tasks SET category_id = NULL)
    ↓
NavigationProvider.refresh() (if pinned)
    ↓
CategoriesProvider.refresh()
    ↓
UI Updates (Category List, Side Panel)
```

## Error Handling

### Validation Errors

**Scenario**: User submits invalid category data
**Handling**: 
- Display inline error messages on form fields
- Prevent submission until valid
- Show snackbar with summary error message

### Database Errors

**Scenario**: Database operation fails (disk full, corruption, etc.)
**Handling**:
- Catch exceptions in repository layer
- Log error details
- Show user-friendly error dialog
- Provide retry option where applicable

### Deletion Conflicts

**Scenario**: User deletes category with assigned habits/tasks
**Handling**:
- Show confirmation dialog with warning: "This category is assigned to X habits and Y tasks. They will not be deleted, but will lose their category assignment."
- Require explicit confirmation
- On confirm, unassign category from all items before deletion

### Navigation Errors

**Scenario**: User navigates to deleted category detail screen
**Handling**:
- Detect missing category in CategoryDetailProvider
- Show error screen with message
- Provide button to return to category list

## Testing Strategy

### Unit Tests

**Category Model**:
- Test fromMap/toMap serialization
- Test copyWith method
- Test field validation

**CategoryRepository**:
- Test CRUD operations with mock database
- Test relationship queries
- Test error handling

**CategoriesProvider**:
- Test state updates
- Test error propagation
- Test refresh logic

### Widget Tests

**Category List Screen**:
- Test empty state display
- Test category card rendering
- Test navigation to detail screen
- Test FAB action

**Create/Edit Category Screen**:
- Test form validation
- Test icon/color picker interactions
- Test save/cancel actions

**Category Details Screen**:
- Test data loading
- Test pin/unpin toggle
- Test edit/delete actions
- Test empty states

**Filter Dropdowns**:
- Test category selection
- Test "All" option
- Test filtered list updates

### Integration Tests

**End-to-End Category Workflow**:
1. Create category
2. Assign to habit
3. Filter habits by category
4. Pin category to sidebar
5. Navigate via sidebar
6. Unpin category
7. Delete category
8. Verify habit still exists without category

**Cross-Feature Integration**:
- Test category assignment in habit creation flow
- Test category assignment in task creation flow
- Test category deletion impact on habits and tasks
- Test sidebar navigation with pinned categories

## Performance Considerations

### Database Optimization

**Indexes**: 
- Add index on `habits.category_id` for fast filtering
- Add index on `tasks.category_id` for fast filtering
- Add index on `categories.is_pinned_to_sidebar` for sidebar queries

**Query Optimization**:
- Use JOIN queries to fetch category with counts in single query
- Implement pagination for large category lists (future enhancement)

### State Management

**Caching**:
- CategoriesProvider caches category list
- CategoryDetailProvider caches detail state per category
- Invalidate cache on mutations

**Lazy Loading**:
- Load category details only when detail screen opened
- Don't load all habits/tasks upfront in category list

### UI Performance

**List Rendering**:
- Use ListView.builder for efficient rendering
- Implement item keys for proper widget recycling
- Avoid rebuilding entire list on single item change

## Security Considerations

### Input Validation

- Sanitize category name and description to prevent injection
- Limit field lengths to prevent buffer overflow
- Validate color format (hex string)

### Data Integrity

- Use foreign key constraints with ON DELETE SET NULL
- Validate category existence before assignment
- Use transactions for multi-step operations (delete category + unassign)

## Accessibility

### Screen Reader Support

- Provide semantic labels for all interactive elements
- Announce category selection changes
- Announce filter state changes

### Visual Accessibility

- Ensure color contrast meets WCAG AA standards
- Don't rely solely on color to convey information
- Provide text labels alongside icons

### Keyboard Navigation

- Support tab navigation through form fields
- Provide keyboard shortcuts for common actions (future enhancement)

## Future Enhancements

### Phase 2 Features (Out of Scope)

1. **Category Hierarchy**: Support subcategories for deeper organization
2. **Category Templates**: Predefined category sets for common use cases
3. **Category Statistics**: Analytics on category usage and completion rates
4. **Category Sharing**: Export/import categories between devices
5. **Smart Categories**: Auto-assign categories based on habit/task names
6. **Category Colors**: Support custom color picker beyond predefined palette
7. **Category Sorting**: Custom sort order for categories in list

### Technical Debt

1. **Migration Strategy**: Implement proper database migration for schema changes
2. **Offline Sync**: Prepare for future cloud sync by adding sync metadata
3. **Performance Monitoring**: Add analytics to track query performance
4. **Error Reporting**: Integrate crash reporting for production issues

## Open Questions

1. **Category Limit**: Should we limit the number of categories a user can create? (Recommendation: No limit initially, monitor usage)

2. **Default Categories**: Should we seed default categories on first launch? (Recommendation: Yes, seed 5-6 common categories as done currently)

3. **Category Icons**: Should we support custom image uploads or stick to icon library? (Recommendation: Icon library only for MVP, custom images in Phase 2)

4. **Sidebar Order**: Should pinned categories have custom sort order in sidebar? (Recommendation: No, use alphabetical order for simplicity)

5. **Category Archiving**: Should we support archiving categories instead of deleting? (Recommendation: No for MVP, add in Phase 2 if requested)
