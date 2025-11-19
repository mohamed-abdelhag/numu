# Enhanced Tasks Feature - Design Document

## Overview

This design document outlines the architecture and implementation approach for enhancing the task management system with essential fields (title, description, dueDate) and a dedicated Task Details Screen. The enhancement builds upon the existing task infrastructure while maintaining backward compatibility and following the established patterns in the codebase.

### Design Goals

1. **Minimal Breaking Changes**: Extend the existing Task model without disrupting current functionality
2. **Consistent UX**: Follow Flutter Material Design patterns and existing app conventions
3. **Data Integrity**: Ensure proper database migrations and data persistence
4. **Accessibility**: Maintain WCAG compliance with proper semantic labels
5. **Performance**: Optimize database queries and UI rendering for smooth user experience

### Key Design Decisions

**Decision 1: Field Naming Convention**
- Use `title` instead of `text` for the main task identifier
- **Rationale**: The current `text` field will be renamed to `title` to better reflect its purpose and align with common task management terminology. This provides semantic clarity and prepares for the addition of a separate `description` field.

**Decision 2: Database Migration Strategy**
- Implement a new database version (v7) with ALTER TABLE statements
- **Rationale**: Using ALTER TABLE allows for non-destructive migration of existing data. The current `text` column will be renamed to `title`, and new columns (`description`, `due_date`) will be added with appropriate defaults.

**Decision 3: Nullable Fields**
- Make `description` and `dueDate` optional (nullable)
- **Rationale**: Not all tasks require detailed descriptions or due dates. This flexibility allows users to create quick tasks while supporting more detailed planning when needed.

**Decision 4: Due Date Handling**
- Store due dates as ISO 8601 strings in SQLite
- **Rationale**: SQLite doesn't have a native date type. ISO 8601 format (YYYY-MM-DD) allows for easy string-based comparisons and sorting while maintaining human readability.

**Decision 5: Task Details Screen Navigation**
- Use named routes with task ID parameter
- **Rationale**: Following the existing navigation pattern used for habit and category details. This approach supports deep linking and maintains consistency across the app.

**Decision 6: UI Layout for Task List**
- Display title prominently, description truncated to 2 lines, due date with visual indicators
- **Rationale**: Balances information density with readability. Users can see key information at a glance while accessing full details through the detail screen.

## Architecture

### Component Structure

```
lib/features/tasks/
├── models/
│   └── task.dart (enhanced)
├── repositories/
│   └── tasks_repository.dart (enhanced)
├── providers/
│   └── tasks_provider.dart (enhanced)
├── screens/
│   ├── tasks_screen.dart (refactored)
│   ├── add_task_screen.dart (new)
│   ├── edit_task_screen.dart (new)
│   └── task_detail_screen.dart (new)
└── widgets/
    ├── task_list_item.dart (new)
    ├── task_form.dart (new)
    └── due_date_badge.dart (new)
```

### Data Flow

1. **Task Creation Flow**:
   ```
   User Input → AddTaskScreen → TasksProvider → TasksRepository → Database
   ```

2. **Task Display Flow**:
   ```
   Database → TasksRepository → TasksProvider → TasksScreen → TaskListItem
   ```

3. **Task Detail Flow**:
   ```
   TaskListItem (tap) → Navigation → TaskDetailScreen → TasksProvider (fetch)
   ```

4. **Task Update Flow**:
   ```
   EditTaskScreen → TasksProvider → TasksRepository → Database → Refresh UI
   ```

## Components and Interfaces

### 1. Enhanced Task Model

**File**: `lib/features/tasks/task.dart`

```dart
class Task {
  final int? id;
  final String title;              // Renamed from 'text'
  final String? description;       // New field
  final DateTime? dueDate;         // New field
  final bool isCompleted;
  final int? categoryId;
  final DateTime createdAt;        // New field for sorting
  final DateTime updatedAt;        // New field for tracking changes

  const Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Serialization methods
  Map<String, dynamic> toMap();
  factory Task.fromMap(Map<String, dynamic> map);
  Task copyWith({...});
  
  // Helper methods
  bool get isOverdue;
  bool get isDueToday;
  bool get isDueSoon; // Within 3 days
  String get dueDateFormatted;
}
```

**Key Methods**:
- `isOverdue`: Returns true if dueDate is in the past and task is not completed
- `isDueToday`: Returns true if dueDate is today
- `isDueSoon`: Returns true if dueDate is within 3 days
- `dueDateFormatted`: Returns human-readable date string (e.g., "Today", "Tomorrow", "Nov 20")

### 2. Database Schema Changes

**Migration**: Version 6 → Version 7

```sql
-- Rename text column to title
ALTER TABLE tasks RENAME COLUMN text TO title;

-- Add new columns
ALTER TABLE tasks ADD COLUMN description TEXT;
ALTER TABLE tasks ADD COLUMN due_date TEXT;
ALTER TABLE tasks ADD COLUMN created_at TEXT NOT NULL DEFAULT (datetime('now'));
ALTER TABLE tasks ADD COLUMN updated_at TEXT NOT NULL DEFAULT (datetime('now'));

-- Create index for due date queries
CREATE INDEX idx_tasks_due_date ON tasks (due_date);
```

**Updated Schema**:
```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  due_date TEXT,
  isCompleted INTEGER NOT NULL DEFAULT 0,
  category_id INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 3. Repository Layer

**File**: `lib/features/tasks/tasks_repository.dart`

**Enhanced Methods**:
```dart
class TasksRepository {
  // Existing methods remain, signatures updated for new Task model
  Future<List<Task>> getTasks({
    bool? isCompleted,
    int? categoryId,
    DateTime? dueBefore,
    DateTime? dueAfter,
  });
  
  Future<Task?> getTaskById(int id);
  Future<Task> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int id);
  
  // New query methods
  Future<List<Task>> getOverdueTasks();
  Future<List<Task>> getTasksDueToday();
  Future<List<Task>> getTasksDueSoon();
}
```

### 4. Provider Layer

**File**: `lib/features/tasks/tasks_provider.dart`

**Enhanced State Management**:
```dart
@riverpod
class Tasks extends _$Tasks {
  @override
  Future<List<Task>> build() async {
    return await _repository.getTasks();
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    int? categoryId,
  }) async { ... }

  Future<void> updateTask(Task task) async { ... }
  
  Future<void> toggleTask(Task task) async { ... }
  
  Future<void> deleteTask(int id) async { ... }
}

// New provider for single task details
@riverpod
Future<Task?> taskDetail(TaskDetailRef ref, int taskId) async {
  final repository = TasksRepository();
  return await repository.getTaskById(taskId);
}
```

### 5. Screen Components

#### 5.1 Tasks Screen (Refactored)

**File**: `lib/features/tasks/screens/tasks_screen.dart`

**Changes**:
- Remove inline add/edit functionality
- Use TaskListItem widget for each task
- Add FAB for navigation to AddTaskScreen
- Maintain existing category filter functionality
- Add sorting options (due date, created date, alphabetical)

**Layout**:
```
┌─────────────────────────────────┐
│ NumuAppBar: "Tasks"             │
│   [Filter Icon] [Sort Icon]     │
├─────────────────────────────────┤
│ [Filter Indicator] (if active)  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ TaskListItem                │ │
│ │  [✓] Title                  │ │
│ │      Description...         │ │
│ │      📅 Due: Nov 20 🏷️ Work │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ TaskListItem (Overdue)      │ │
│ │  [ ] Title                  │ │
│ │      Description...         │ │
│ │      ⚠️ Overdue: Nov 15     │ │
│ └─────────────────────────────┘ │
│                                 │
│              [+] FAB            │
└─────────────────────────────────┘
```

#### 5.2 Add Task Screen (New)

**File**: `lib/features/tasks/screens/add_task_screen.dart`

**Features**:
- Form with title, description, due date, and category fields
- Title validation (required, non-empty)
- Date picker for due date selection
- Category dropdown (reuse existing widget)
- Save and Cancel actions

**Layout**:
```
┌─────────────────────────────────┐
│ AppBar: "Add Task"              │
│   [Cancel]           [Save]     │
├─────────────────────────────────┤
│ Title *                         │
│ ┌─────────────────────────────┐ │
│ │ Enter task title...         │ │
│ └─────────────────────────────┘ │
│                                 │
│ Description                     │
│ ┌─────────────────────────────┐ │
│ │ Enter description...        │ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│ Due Date                        │
│ ┌─────────────────────────────┐ │
│ │ 📅 Select date...           │ │
│ └─────────────────────────────┘ │
│                                 │
│ Category                        │
│ ┌─────────────────────────────┐ │
│ │ 🏷️ Select category...       │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

#### 5.3 Edit Task Screen (New)

**File**: `lib/features/tasks/screens/edit_task_screen.dart`

**Features**:
- Identical form to AddTaskScreen
- Pre-filled with existing task data
- Update and Cancel actions
- Delete option in app bar menu

**Implementation Note**: Can share TaskForm widget with AddTaskScreen to reduce code duplication.

#### 5.4 Task Detail Screen (New)

**File**: `lib/features/tasks/screens/task_detail_screen.dart`

**Features**:
- Display all task information
- Completion toggle
- Edit and Delete actions
- Category badge with navigation to category detail
- Due date with visual indicators (overdue, today, soon)

**Layout**:
```
┌─────────────────────────────────┐
│ AppBar: "Task Details"          │
│   [Back]    [Edit] [Delete]     │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ [✓] Task Title              │ │
│ └─────────────────────────────┘ │
│                                 │
│ Description                     │
│ ┌─────────────────────────────┐ │
│ │ Full task description text  │ │
│ │ displayed here without      │ │
│ │ truncation...               │ │
│ └─────────────────────────────┘ │
│                                 │
│ Due Date                        │
│ ┌─────────────────────────────┐ │
│ │ 📅 Wednesday, Nov 20, 2025  │ │
│ │ ⚠️ Overdue by 2 days        │ │
│ └─────────────────────────────┘ │
│                                 │
│ Category                        │
│ ┌─────────────────────────────┐ │
│ │ 💼 Work                     │ │
│ │ [View Category Details →]   │ │
│ └─────────────────────────────┘ │
│                                 │
│ Metadata                        │
│ Created: Nov 15, 2025           │
│ Updated: Nov 18, 2025           │
└─────────────────────────────────┘
```

### 6. Widget Components

#### 6.1 TaskListItem Widget

**File**: `lib/features/tasks/widgets/task_list_item.dart`

**Purpose**: Reusable widget for displaying task in list view

**Features**:
- Checkbox for completion toggle
- Title (bold, strikethrough if completed)
- Description (2 lines max, ellipsis)
- Due date badge with color coding
- Category badge
- Tap to navigate to detail screen

**Visual States**:
- Normal: Default styling
- Overdue: Red due date badge, warning icon
- Due Today: Orange due date badge
- Due Soon: Yellow due date badge
- Completed: Strikethrough text, muted colors

#### 6.2 TaskForm Widget

**File**: `lib/features/tasks/widgets/task_form.dart`

**Purpose**: Shared form component for Add and Edit screens

**Features**:
- Title TextField with validation
- Description TextField (multiline)
- Due Date picker button
- Category dropdown
- Form validation logic
- Accessibility labels

#### 6.3 DueDateBadge Widget

**File**: `lib/features/tasks/widgets/due_date_badge.dart`

**Purpose**: Consistent due date display with visual indicators

**Features**:
- Color-coded based on urgency
- Icon indicators (⚠️ for overdue, 📅 for normal)
- Relative date text ("Today", "Tomorrow", "In 3 days")
- Absolute date for older dates

## Data Models

### Task Model Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | int? | No | null | Auto-generated primary key |
| title | String | Yes | - | Task title (renamed from text) |
| description | String? | No | null | Detailed task description |
| dueDate | DateTime? | No | null | When task should be completed |
| isCompleted | bool | Yes | false | Completion status |
| categoryId | int? | No | null | Associated category |
| createdAt | DateTime | Yes | now() | Creation timestamp |
| updatedAt | DateTime | Yes | now() | Last update timestamp |

### Database Mapping

```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'isCompleted': isCompleted ? 1 : 0,
    'category_id': categoryId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

factory Task.fromMap(Map<String, dynamic> map) {
  return Task(
    id: map['id'] as int?,
    title: map['title'] as String,
    description: map['description'] as String?,
    dueDate: map['due_date'] != null 
        ? DateTime.parse(map['due_date'] as String) 
        : null,
    isCompleted: (map['isCompleted'] as int) == 1,
    categoryId: map['category_id'] as int?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
```

## Error Handling

### Validation Errors

1. **Empty Title**: Display inline error message "Title cannot be empty"
2. **Invalid Date**: Prevent selection of dates in the past (optional constraint)
3. **Database Errors**: Show SnackBar with retry option

### Migration Errors

1. **Failed Migration**: Log error, attempt rollback, show user-friendly message
2. **Data Loss Prevention**: Backup existing data before migration
3. **Fallback Strategy**: If migration fails, maintain old schema and disable new features

### Navigation Errors

1. **Invalid Task ID**: Show error message and navigate back to task list
2. **Deleted Task**: Handle gracefully with "Task not found" message

## Testing Strategy

### Unit Tests

1. **Task Model Tests**
   - Serialization/deserialization
   - copyWith functionality
   - Helper methods (isOverdue, isDueToday, etc.)
   - Edge cases (null values, boundary dates)

2. **Repository Tests**
   - CRUD operations
   - Query methods with filters
   - Database migration
   - Error handling

3. **Provider Tests**
   - State management
   - Async operations
   - Error states

### Widget Tests

1. **TaskListItem Tests**
   - Rendering with different task states
   - Interaction handling (tap, checkbox)
   - Visual indicators

2. **TaskForm Tests**
   - Validation logic
   - Input handling
   - Date picker interaction

3. **Screen Tests**
   - Navigation flows
   - Form submission
   - Error display

### Integration Tests

1. **Task Creation Flow**
   - Navigate to add screen
   - Fill form
   - Save task
   - Verify in list

2. **Task Update Flow**
   - Select task
   - Navigate to edit
   - Update fields
   - Verify changes

3. **Task Detail Flow**
   - Tap task in list
   - View details
   - Verify all fields displayed

4. **Category Integration**
   - Assign category to task
   - Filter by category
   - Handle category deletion

## Performance Considerations

### Database Optimization

1. **Indexes**: Create index on `due_date` column for fast date-based queries
2. **Query Optimization**: Use WHERE clauses to filter at database level
3. **Batch Operations**: Group multiple updates in transactions

### UI Optimization

1. **List Rendering**: Use ListView.builder for efficient rendering
2. **Image Caching**: Cache category icons
3. **Debouncing**: Debounce search/filter operations

### Memory Management

1. **Provider Disposal**: Properly dispose controllers and listeners
2. **Large Lists**: Implement pagination if task count exceeds 100
3. **Date Formatting**: Cache formatted date strings

## Accessibility

### Semantic Labels

- All interactive elements have semantic labels
- Form fields have proper labels and hints
- Error messages are announced to screen readers

### Keyboard Navigation

- Tab order follows logical flow
- Enter key submits forms
- Escape key cancels operations

### Visual Accessibility

- Color contrast meets WCAG AA standards
- Text size respects system font scaling
- Icons have text alternatives

## Migration Path

### Phase 1: Database Migration
1. Update DatabaseService to version 7
2. Implement migration logic
3. Test migration with existing data

### Phase 2: Model Updates
1. Update Task model
2. Update repository methods
3. Update provider methods

### Phase 3: UI Refactoring
1. Create new screen components
2. Create new widget components
3. Update TasksScreen

### Phase 4: Integration
1. Wire up navigation
2. Test all flows
3. Handle edge cases

### Backward Compatibility

- Existing tasks will have `title` populated from `text` column
- `description` and `dueDate` will be null for existing tasks
- All existing functionality remains operational

## Future Enhancements

1. **Recurring Tasks**: Support for repeating tasks
2. **Subtasks**: Hierarchical task structure
3. **Task Priority**: High/Medium/Low priority levels
4. **Task Tags**: Multiple tags per task
5. **Task Attachments**: Link files or images
6. **Task Comments**: Add notes and updates
7. **Task Sharing**: Collaborate on tasks
8. **Smart Due Dates**: Natural language parsing ("next Monday")
9. **Task Templates**: Reusable task structures
10. **Task Analytics**: Completion rates and trends
