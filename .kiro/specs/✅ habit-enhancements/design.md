# Design Document

## Overview

This design document outlines the technical approach for enhancing the habit tracking system with category filtering, unit support for countable habits, improved click behavior, refined boolean and countable habit interactions, enhanced statistics, and calendar-based editing. The enhancements build upon the existing Flutter/Riverpod architecture and SQLite database structure.

## Architecture

### High-Level Architecture

The habit enhancements follow the existing layered architecture:

```
Presentation Layer (Widgets/Screens)
    ↓
State Management Layer (Riverpod Providers)
    ↓
Business Logic Layer (Services)
    ↓
Data Access Layer (Repositories)
    ↓
Database Layer (SQLite via sqflite)
```

### Key Architectural Decisions

1. **Category Filtering**: Implement filtering at the UI layer using existing category data, avoiding additional database queries
2. **Click Debouncing**: Use Flutter's built-in mechanisms and timestamp-based duplicate prevention at the repository layer
3. **Statistics Calculation**: Create a dedicated statistics service to compute aggregated values from habit events
4. **Dialog-Based Interactions**: Leverage existing `LogHabitEventDialog` and extend it for various habit types and quality tracking scenarios

## Components and Interfaces

### 1. Data Model Updates

#### Habit Model
The `Habit` model already contains the necessary fields:
- `categoryId` (int?) - Already exists, supports category assignment
- `unit` (String?) - Already exists, stores measurement unit for countable habits
- `goalType` (GoalType) - Already exists, supports minimum/maximum goals
- `targetValue` (double?) - Already exists, stores the numeric goal
- `qualityLayerEnabled` (bool) - Already exists, indicates quality tracking

No model changes required.

#### HabitEvent Model
The `HabitEvent` model already contains:
- `value` (double?) - Stores numeric count for countable habits
- `completed` (bool?) - Stores completion status for boolean habits
- `qualityAchieved` (bool?) - Stores quality status

No model changes required.

### 2. Repository Layer Enhancements

#### HabitRepository
Extend existing methods to support:

```dart
// Add duplicate prevention logic
Future<HabitEvent> logEvent(HabitEvent event) async {
  // Check for existing event on the same date
  final existingEvents = await getEventsForDate(event.habitId, event.eventDate);
  
  if (existingEvents.isNotEmpty) {
    // Update existing event instead of creating duplicate
    return updateEvent(event.copyWith(id: existingEvents.first.id));
  }
  
  // Create new event
  // ... existing logic
}

// Add update event method
Future<HabitEvent> updateEvent(HabitEvent event) async {
  // Update existing event in database
}

// Add statistics query methods
Future<Map<String, double>> getHabitStatistics(int habitId) async {
  // Calculate total, weekly, monthly, and average values
}
```

### 3. Service Layer

#### HabitStatisticsService
New service to calculate comprehensive statistics:

```dart
class HabitStatisticsService {
  final HabitRepository _repository;
  
  Future<HabitStatistics> calculateStatistics(int habitId, Habit habit) async {
    final events = await _repository.getEventsForHabit(habitId);
    
    return HabitStatistics(
      totalValue: _calculateTotal(events, habit),
      weeklyValue: _calculateWeekly(events, habit),
      monthlyValue: _calculateMonthly(events, habit),
      averagePerDay: _calculateAverage(events, habit),
      qualityDays: _calculateQualityDays(events),
      qualityPercentage: _calculateQualityPercentage(events),
    );
  }
  
  double _calculateTotal(List<HabitEvent> events, Habit habit) {
    // Sum all values for countable habits
    // Count completed days for boolean habits
  }
  
  // ... other calculation methods
}
```

### 4. Provider Layer Updates

#### HabitsProvider
Update to support category filtering:

```dart
@riverpod
class Habits extends _$Habits {
  @override
  Future<List<Habit>> build() async {
    return await _repository.getActiveHabits();
  }
  
  // Existing logEvent method with duplicate prevention
  Future<void> logEvent(HabitEvent event) async {
    await _repository.logEvent(event); // Repository handles duplicates
    ref.invalidateSelf();
  }
}
```

#### HabitDetailProvider
Extend to include statistics:

```dart
class HabitDetailState {
  final Habit habit;
  final List<HabitEvent> events;
  final HabitStatistics statistics; // Add statistics
  final Map<DateTime, HabitEvent> eventsByDate;
  
  // ... existing fields
}
```

### 5. UI Components

#### HabitsScreen Enhancements
Already implements category filtering. Enhancements:
- Ensure filter state persists during navigation
- Display filtered habit count in filter indicator

#### HabitListItem Enhancements
Update click behavior with debouncing:

```dart
class HabitListItem extends ConsumerStatefulWidget {
  DateTime? _lastClickTime;
  
  void _handleClick() {
    final now = DateTime.now();
    if (_lastClickTime != null && 
        now.difference(_lastClickTime!) < Duration(milliseconds: 500)) {
      return; // Ignore rapid clicks
    }
    _lastClickTime = now;
    
    // Process click based on habit type
    _processHabitClick();
  }
}
```

#### HabitQuickLogButton Enhancements
Implement different click behaviors based on habit configuration:

```dart
class HabitQuickLogButton extends ConsumerStatefulWidget {
  Future<void> _handleClick(Habit habit, WidgetRef ref) async {
    if (habit.trackingType == TrackingType.binary) {
      if (habit.qualityLayerEnabled) {
        await _handleBooleanWithQuality(habit, ref);
      } else {
        await _handleBooleanWithoutQuality(habit, ref);
      }
    } else {
      // Countable habit
      if (habit.qualityLayerEnabled) {
        await _handleCountableWithQuality(habit, ref);
      } else {
        await _handleCountableWithoutQuality(habit, ref);
      }
    }
  }
  
  Future<void> _handleBooleanWithQuality(Habit habit, WidgetRef ref) async {
    // First click: mark done
    // Second click: mark quality
    // Third click: no action
  }
  
  Future<void> _handleBooleanWithoutQuality(Habit habit, WidgetRef ref) async {
    // First click: mark done
    // Second click: show confirmation dialog to unmark
  }
  
  Future<void> _handleCountableWithoutQuality(Habit habit, WidgetRef ref) async {
    // Increment count by 1
    // When target reached: show input dialog for manual entry
  }
  
  Future<void> _handleCountableWithQuality(Habit habit, WidgetRef ref) async {
    // Increment count by 1 until target
    // When target reached: show advanced dialog with count input and quality checkbox
  }
}
```

#### LogHabitEventDialog Enhancements
Extend to support:
- Date selection for new entries (FAB click)
- Pre-filled, read-only date for calendar date clicks
- Different input controls based on habit type
- Quality checkbox when quality tracking is enabled
- Unit display for countable habits

```dart
class LogHabitEventDialog extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime? prefilledDate; // null for FAB, specific date for calendar click
  final HabitEvent? existingEvent; // null for new, populated for edit
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(prefilledDate == null ? 'Log Habit' : 'Edit Entry'),
      content: Column(
        children: [
          // Date picker (editable if prefilledDate is null)
          if (prefilledDate == null)
            DatePickerField(...)
          else
            ReadOnlyDateField(date: prefilledDate),
          
          // Input based on tracking type
          if (habit.trackingType == TrackingType.binary)
            CheckboxField(label: 'Completed')
          else
            NumberInputField(
              label: 'Count',
              unit: habit.unit,
              initialValue: existingEvent?.value,
            ),
          
          // Quality checkbox if enabled
          if (habit.qualityLayerEnabled)
            CheckboxField(label: habit.qualityLayerLabel ?? 'Quality'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: _saveEvent, child: Text('Save')),
      ],
    );
  }
}
```

#### HabitDetailScreen Enhancements
Update to display comprehensive statistics:

```dart
Widget _buildStatisticsSection(HabitStatistics stats, Habit habit) {
  return Column(
    children: [
      StatisticCard(
        label: 'Total',
        value: '${stats.totalValue} ${habit.unit ?? ''}',
      ),
      StatisticCard(
        label: 'This Week',
        value: '${stats.weeklyValue} ${habit.unit ?? ''}',
      ),
      StatisticCard(
        label: 'This Month',
        value: '${stats.monthlyValue} ${habit.unit ?? ''}',
      ),
      StatisticCard(
        label: 'Average per Day',
        value: '${stats.averagePerDay.toStringAsFixed(1)} ${habit.unit ?? ''}',
      ),
      
      // Quality statistics (always visible if quality tracking enabled)
      if (habit.qualityLayerEnabled) ...[
        StatisticCard(
          label: 'Quality Days',
          value: '${stats.qualityDays}',
        ),
        StatisticCard(
          label: 'Quality Rate',
          value: '${stats.qualityPercentage.toStringAsFixed(1)}%',
        ),
      ],
    ],
  );
}
```

#### HabitCalendarView Enhancements
Update to support tapping dates for editing:

```dart
class HabitCalendarView extends ConsumerWidget {
  void _handleDateTap(DateTime date, Habit habit, BuildContext context) {
    // Get existing event for this date if any
    final existingEvent = _getEventForDate(date);
    
    showDialog(
      context: context,
      builder: (context) => LogHabitEventDialog(
        habit: habit,
        prefilledDate: date,
        existingEvent: existingEvent,
      ),
    );
  }
}
```

### 6. Form Components

#### AddHabitScreen / EditHabitScreen Enhancements
Ensure proper handling of:
- Category selection dropdown (already implemented)
- Unit input for countable habits with suggestions
- Goal type selector (minimum/maximum)
- Target value input with validation

## Data Models

### HabitStatistics
New model to encapsulate calculated statistics:

```dart
class HabitStatistics {
  final double totalValue;
  final double weeklyValue;
  final double monthlyValue;
  final double averagePerDay;
  final int qualityDays;
  final double qualityPercentage;
  
  const HabitStatistics({
    required this.totalValue,
    required this.weeklyValue,
    required this.monthlyValue,
    required this.averagePerDay,
    required this.qualityDays,
    required this.qualityPercentage,
  });
}
```

## Error Handling

### Duplicate Event Prevention
- Repository layer checks for existing events before creating new ones
- UI layer implements 500ms debounce to prevent rapid clicks
- User feedback via SnackBar for successful logging

### Validation
- Unit required for countable habits (validated in form)
- Target value required for minimum/maximum goal types (validated in form and repository)
- Date validation for event logging (prevent future dates beyond today)

### Error States
- Display appropriate error messages for database failures
- Retry mechanisms for transient errors
- Graceful degradation when statistics cannot be calculated

## Testing Strategy

### Unit Tests
1. **HabitStatisticsService**
   - Test total value calculation for countable habits
   - Test weekly/monthly aggregation
   - Test average calculation
   - Test quality percentage calculation
   - Test edge cases (no events, single event, etc.)

2. **Repository Duplicate Prevention**
   - Test that duplicate events on same date are prevented
   - Test that events on different dates are allowed
   - Test update vs create logic

3. **Click Behavior Logic**
   - Test boolean habit with quality (3-state progression)
   - Test boolean habit without quality (done/undone with confirmation)
   - Test countable habit increment and dialog trigger
   - Test countable habit with quality advanced dialog

### Widget Tests
1. **HabitsScreen Category Filter**
   - Test filter dropdown displays categories
   - Test filtering habits by category
   - Test clearing filter
   - Test filter indicator display

2. **HabitDetailScreen Statistics**
   - Test statistics display for countable habits
   - Test quality statistics visibility
   - Test unit display in statistics

3. **LogHabitEventDialog**
   - Test date picker for FAB-initiated logging
   - Test read-only date for calendar-initiated editing
   - Test appropriate inputs for different habit types
   - Test quality checkbox visibility

### Integration Tests
1. **End-to-End Habit Logging**
   - Create habit with category and unit
   - Log events via quick button
   - Verify statistics update
   - Edit event via calendar
   - Verify updated statistics

2. **Category Filtering Flow**
   - Create habits in different categories
   - Apply category filter
   - Verify filtered list
   - Clear filter
   - Verify all habits shown

## Performance Considerations

1. **Statistics Calculation**: Cache statistics in provider state, recalculate only when events change
2. **Category Filtering**: Filter in memory rather than additional database queries
3. **Event Queries**: Use indexed queries on habit_id and event_date for fast lookups
4. **Debouncing**: Prevent unnecessary database writes from rapid clicks

## Accessibility

1. **Semantic Labels**: Add appropriate labels for filter buttons, FAB, and interactive elements
2. **Screen Reader Support**: Ensure statistics are announced properly
3. **Keyboard Navigation**: Support tab navigation through forms and dialogs
4. **Color Contrast**: Ensure category colors meet WCAG standards

## Migration Considerations

No database schema changes required. All necessary fields already exist in the current schema:
- `habits.category_id`
- `habits.unit`
- `habits.goal_type`
- `habits.target_value`
- `habits.quality_layer_enabled`
- `habit_events.value`
- `habit_events.completed`
- `habit_events.quality_achieved`

## Dependencies

Existing dependencies are sufficient:
- `flutter_riverpod` - State management
- `sqflite` - Database
- `go_router` - Navigation
- `flutter` - UI framework

No new dependencies required.
