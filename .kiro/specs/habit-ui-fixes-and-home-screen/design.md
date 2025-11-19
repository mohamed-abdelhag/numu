# Design Document

## Overview

This design addresses seven critical UI/UX issues and enhancements in the habit tracking application. The fixes span across habit cards, quality layer presentation, calendar editing, home screen implementation, navigation stability, and quick action buttons. The design maintains consistency with the existing architecture while improving user experience and data accuracy.

## Architecture

### Component Structure

```
lib/features/
├── habits/
│   ├── widgets/
│   │   ├── habit_card.dart (MODIFY)
│   │   ├── log_habit_event_dialog.dart (MODIFY)
│   │   └── habit_quick_action_button.dart (NEW)
│   ├── screens/
│   │   └── habit_detail_screen.dart (MODIFY)
│   └── providers/
│       └── habits_provider.dart (existing)
├── home/
│   ├── home_screen.dart (MODIFY)
│   ├── models/
│   │   └── daily_item.dart (NEW)
│   ├── providers/
│   │   └── daily_items_provider.dart (NEW)
│   └── widgets/
│       ├── daily_item_card.dart (NEW)
│       └── daily_progress_header.dart (NEW)
├── tasks/
│   └── tasks_screen.dart (MODIFY)
└── core/
    └── widgets/
        └── shell/
            └── numu_app_shell.dart (existing)
```

## Components and Interfaces

### 1. Habit Card Value Display (Requirement 1)

**Problem**: Habit cards show placeholder data instead of actual current values for value-based habits.

**Solution**: Modify `HabitCard` to fetch and display today's logged value.

**Changes to `habit_card.dart`**:
- Add a provider watch to fetch today's events for the habit
- Calculate current day's total value from events
- Display the value with unit in the card UI
- Show "0" or empty state when no value logged

**Data Flow**:
```
HabitCard → habitDetailProvider(habitId) → HabitDetailState → events
→ Filter events for today → Sum valueDelta → Display value
```

### 2. Quality Layer Details Integration (Requirement 2)

**Problem**: Quality layer streak information is separated from normal details using a segmented button selector, creating a fragmented view.

**Solution**: Integrate quality layer streak display within the same section as normal streak details.

**Changes to `habit_detail_screen.dart`**:
- Remove the `_buildStreakTypeSelector` widget when quality layer is enabled
- Modify `HabitStreakDisplay` to show both completion and quality streaks simultaneously
- Only show quality section when `habit.qualityLayerEnabled == true`
- Display quality streak below or alongside the main streak with clear labeling

**UI Layout**:
```
Streak Section:
├── Completion Streak: X days 🔥
└── Quality Streak: Y days ⭐ (only if quality enabled)
```

### 3. Calendar Edit Value Loading (Requirement 3)

**Problem**: 
- Calendar edit dialog loads with value "0" instead of current logged value
- Quality layer logic may be treating quality as separate counter

**Solution**: 
- Pre-populate dialog with existing event data
- Clarify quality layer as binary attribute, not separate counter

**Changes to `log_habit_event_dialog.dart`**:
- Modify `initState()` to load existing event for the selected date
- Pre-fill `_valueController` with current value from event
- Pre-fill `_qualityAchieved` checkbox with current quality status
- Add helper method `_loadExistingEventForDate()` to fetch event data
- Ensure quality checkbox is independent of value input
- Update save logic to preserve the relationship: value + quality attribute

**Data Model Clarification**:
```dart
HabitEvent {
  valueDelta: 20.0,  // The actual reps/value
  qualityAchieved: true,  // Binary: was focused during those 20 reps
}
// NOT: valueDelta: 20.0 (unfocused) + qualityDelta: 20.0 (focused)
```

### 4. Unified Home Screen (Requirement 4)

**Problem**: Home screen is a placeholder with no functionality.

**Solution**: Implement a comprehensive daily dashboard showing habits and tasks due today.

**New Components**:

#### `DailyItem` Model
```dart
class DailyItem {
  final String id;
  final String title;
  final DailyItemType type; // habit or task
  final DateTime? scheduledTime;
  final bool isCompleted;
  final String? icon;
  final Color? color;
  final int? habitId;
  final int? taskId;
}

enum DailyItemType { habit, task }
```

#### `DailyItemsProvider`
- Fetches all habits active today (based on frequency and active days)
- Fetches all tasks due today
- Combines into unified list
- Calculates completion percentage
- Sorts by scheduled time (habits with time window, tasks with due time)

#### `DailyProgressHeader` Widget
- Displays "Welcome, [User Name]"
- Shows "X habits and Y tasks" summary
- Renders progress bar with completion percentage
- Displays motivational message based on percentage:
  - 0-25%: "Let's get started"
  - 26-75%: "Almost there"
  - 76-99%: "Going well"
  - 100%: "Done for the day"

#### `DailyItemCard` Widget
- Displays habit or task in unified format
- Shows icon, title, scheduled time
- Includes quick action button (checkbox for habits, checkbox for tasks)
- Tappable to navigate to detail screen

**Home Screen Layout**:
```
┌─────────────────────────────┐
│ Welcome, [Name]             │
│ X habits and Y tasks        │
│ ████████░░ 80%              │
│ Going well                  │
├─────────────────────────────┤
│ 🏃 Morning Run      [✓] 7AM │
│ 📝 Review PR        [ ] 9AM │
│ 💧 Drink Water      [+] 10AM│
│ 📚 Read Book        [ ] 8PM │
└─────────────────────────────┘
```

### 5. Shell Navigation Stability (Requirement 5)

**Problem**: App sometimes loads outside shell causing instability.

**Solution**: Ensure all routes are wrapped in shell and handle navigation errors gracefully.

**Changes**:
- Review router configuration to ensure all routes use `ShellRoute`
- Add navigation guards to prevent direct navigation outside shell
- Implement error boundary in shell to catch and recover from navigation errors
- Add initialization check in `main.dart` to ensure shell is ready before first navigation

**Router Structure** (to verify):
```dart
GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => NumuAppShell(child: child),
      routes: [
        // All app routes here
      ],
    ),
  ],
  errorBuilder: (context, state) => ErrorScreen(withinShell: true),
)
```

### 6. Tasks Screen Sidebar Fix (Requirement 6)

**Problem**: Sidebar drawer doesn't open from tasks screen.

**Solution**: Ensure tasks screen properly connects to shell's drawer controller.

**Changes to `tasks_screen.dart`**:
- Remove `Scaffold` wrapper (shell already provides it)
- Ensure `NumuAppBar` has `showDrawerButton: true` (default)
- Verify drawer button triggers `Scaffold.of(context).openDrawer()`

**Current Issue**: Tasks screen wraps content in its own `Scaffold`, which conflicts with shell's `Scaffold`. The drawer button tries to open the inner scaffold's drawer (which doesn't exist) instead of the shell's drawer.

**Fix**: Remove the `Scaffold` wrapper and return just the `Column` with `NumuAppBar` and content.

### 7. Habit Card Accuracy and Quick Actions (Requirement 7)

**Problem**: 
- Streak numbers are placeholder/inaccurate
- Completion percentage is placeholder
- No quick action buttons to log progress

**Solution**: Calculate accurate metrics and add context-aware quick action buttons.

**Changes to `habit_card.dart`**:

#### Accurate Metrics
- Fetch current streak from `HabitStreakDisplay` logic or provider
- Calculate completion percentage from period progress
- Use real data instead of placeholder `score` and `overallProgress` props

#### Quick Action Buttons
Create new `HabitQuickActionButton` widget with logic:

```dart
Widget buildQuickAction(Habit habit, BuildContext context) {
  if (habit.trackingType == TrackingType.binary) {
    if (!habit.qualityLayerEnabled) {
      // Simple checkbox - marks done on click
      return Checkbox(onChanged: (val) => markComplete());
    } else {
      // Checkbox that opens quality dialog on second click
      return Checkbox(onChanged: (val) => 
        isAlreadyDone ? showQualityDialog() : markComplete()
      );
    }
  } else if (habit.trackingType == TrackingType.value) {
    // Plus button to increment by 1
    return IconButton(
      icon: Icon(Icons.add),
      onPressed: () {
        if (goalReached) {
          showFullLogDialog(); // With quality options
        } else {
          incrementValue();
        }
      },
    );
  } else if (habit.trackingType == TrackingType.timed) {
    // Add button opens log dialog
    return IconButton(
      icon: Icon(Icons.add),
      onPressed: () => showLogDialog(),
    );
  }
}
```

**Special Case - Minimum Goal with Quality**:
- For habits with `goalType == GoalType.minimum` and quality layer enabled
- Quick action only increments value
- Quality layer can ONLY be set via calendar in detail screen
- Add code comment explaining this limitation

## Data Models

### DailyItem (New)
```dart
class DailyItem {
  final String id;
  final String title;
  final DailyItemType type;
  final DateTime? scheduledTime;
  final bool isCompleted;
  final String? icon;
  final Color? color;
  final int? habitId;
  final int? taskId;
  final double? currentValue;
  final double? targetValue;
  final String? unit;
  
  DailyItem({
    required this.id,
    required this.title,
    required this.type,
    this.scheduledTime,
    required this.isCompleted,
    this.icon,
    this.color,
    this.habitId,
    this.taskId,
    this.currentValue,
    this.targetValue,
    this.unit,
  });
}

enum DailyItemType { habit, task }
```

### HabitEvent (Existing - Clarification)
The existing model already supports the correct quality layer logic:
```dart
class HabitEvent {
  final double? valueDelta;  // The actual value (e.g., 20 reps)
  final bool? qualityAchieved;  // Binary quality attribute
  // qualityAchieved applies to the valueDelta, not separate
}
```

## Error Handling

### Navigation Errors
- Catch navigation exceptions in shell
- Log errors with `CoreLoggingUtility`
- Display error snackbar to user
- Recover by navigating to home screen

### Data Loading Errors
- Use `AsyncValue` error states in providers
- Display user-friendly error messages
- Provide retry buttons
- Log detailed errors for debugging

### Quick Action Errors
- Wrap quick action handlers in try-catch
- Show snackbar on failure
- Don't block UI on error
- Log errors for investigation

## Testing Strategy

### Unit Tests
- `DailyItemsProvider`: Test habit/task filtering and sorting
- `HabitQuickActionButton`: Test action logic for each habit type
- Quality layer logic: Verify value + quality relationship

### Widget Tests
- `DailyProgressHeader`: Test message display for each percentage range
- `HabitCard`: Test value display and quick actions
- `LogHabitEventDialog`: Test pre-population with existing values

### Integration Tests
- Home screen: Verify habits and tasks load and sort correctly
- Navigation: Test all routes load within shell
- Quick actions: Test logging from habit card updates detail screen

### Manual Testing
- Test sidebar opens from all screens
- Verify calendar edit loads current values
- Test quality layer as binary attribute (not separate counter)
- Verify app never loads outside shell
- Test quick actions for all habit types and configurations

## Implementation Notes

### Phase 1: Critical Fixes
1. Fix tasks screen sidebar (Requirement 6)
2. Fix shell navigation stability (Requirement 5)
3. Fix calendar edit value loading (Requirement 3)

### Phase 2: Data Accuracy
4. Fix habit card value display (Requirement 1)
5. Fix habit card streak/percentage accuracy (Requirement 7 - part 1)

### Phase 3: UX Improvements
6. Integrate quality layer details (Requirement 2)
7. Add quick action buttons (Requirement 7 - part 2)

### Phase 4: New Feature
8. Implement unified home screen (Requirement 4)

### Code Comments
Add comments in `HabitQuickActionButton` explaining:
```dart
// TODO: For minimum goal habits with quality layer,
// quick actions only increment value. Quality layer
// must be set via calendar in habit detail screen.
// This is by design to prevent accidental quality logging.
```

## Dependencies

No new dependencies required. All fixes use existing:
- `flutter_riverpod` for state management
- `go_router` for navigation
- Existing repository and service layers
