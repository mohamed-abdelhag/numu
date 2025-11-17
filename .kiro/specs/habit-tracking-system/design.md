# Design Document

## Overview

This document provides a comprehensive design for the habit tracking system in the Numu app. The system follows clean architecture principles with clear separation of concerns across multiple layers. The design emphasizes reusability, testability, and maintainability while adhering to Flutter and Riverpod best practices.

### Key Design Principles

1. **Separation of Concerns**: Repository handles data access, Provider manages state, Services contain business logic
2. **Reusable Components**: All widgets are modular and stored in separate files
3. **Type Safety**: Strong typing throughout with well-defined models and enums
4. **Reactive State Management**: Riverpod for declarative UI updates
5. **Centralized Database**: Single DatabaseService manages all tables
6. **Performance First**: Caching, indexing, and optimistic updates where appropriate

### Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  (Screens, Widgets, Dialogs - UI Components)            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Provider Layer                        │
│  (State Management, Business Logic Coordination)        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Service Layer                         │
│  (Streak Calculation, Period Progress, Business Logic)  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Repository Layer                       │
│  (Data Access, Database Operations)                     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Model Layer                           │
│  (Data Structures, Enums, Type Definitions)             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                 Core Database Service                    │
│  (Centralized SQLite Database Management)               │
└─────────────────────────────────────────────────────────┘
```

## Architecture

### Folder Structure


```
lib/features/habits/
├── models/
│   ├── habit.dart                      # Habit model with all configuration fields
│   ├── habit_event.dart                # Event model for tracking completions
│   ├── habit_streak.dart               # Streak data model
│   ├── habit_period_progress.dart      # Period progress model
│   ├── category.dart                   # Category model
│   └── enums/
│       ├── tracking_type.dart          # binary, value, timed
│       ├── goal_type.dart              # none, minimum, maximum
│       ├── frequency.dart              # daily, weekly, monthly, custom
│       ├── active_days_mode.dart       # all, selected
│       ├── require_mode.dart           # each, any, total
│       ├── time_window_mode.dart       # soft, hard
│       └── streak_type.dart            # completion, time_window, quality, perfect
│
├── repositories/
│   ├── habit_repository.dart           # Data access for habits and events
│   └── category_repository.dart        # Data access for categories
│
├── providers/
│   ├── habits_provider.dart            # Main habits list state management
│   ├── habit_detail_provider.dart      # Single habit detail state
│   └── categories_provider.dart        # Categories state management
│
├── services/
│   ├── streak_calculation_service.dart # Streak calculation logic
│   └── period_progress_service.dart    # Period progress calculation logic
│
├── screens/
│   ├── habits_screen.dart              # Main habits list screen
│   ├── habit_detail_screen.dart        # Detailed habit view with history
│   ├── add_habit_screen.dart           # Create new habit form
│   └── edit_habit_screen.dart          # Edit existing habit form
│
└── widgets/
    ├── habit_list_item.dart            # Individual habit in list
    ├── habit_quick_log_button.dart     # Quick log button for binary habits
    ├── habit_streak_display.dart       # Streak visualization widget
    ├── habit_progress_indicator.dart   # Progress bar for period habits
    ├── habit_calendar_view.dart        # Calendar showing completion history
    ├── empty_habits_state.dart         # Empty state when no habits
    ├── log_habit_event_dialog.dart     # Dialog for logging events
    └── forms/
        ├── tracking_type_selector.dart # Select tracking type
        ├── goal_type_selector.dart     # Select goal type
        ├── frequency_selector.dart     # Select frequency
        ├── icon_picker.dart            # Pick habit icon
        ├── color_picker.dart           # Pick habit color
        ├── weekday_selector.dart       # Select active weekdays
        ├── time_window_picker.dart     # Configure time window
        └── quality_layer_toggle.dart   # Enable/configure quality layer
```

## Components and Interfaces

### 1. Data Models

#### Habit Model


```dart
class Habit {
  final int? id;
  final String name;
  final String? description;
  final int? categoryId;
  final String icon;
  final String color;
  
  // Tracking configuration
  final TrackingType trackingType;
  final GoalType goalType;
  final double? targetValue;
  final String? unit;
  
  // Frequency configuration
  final Frequency frequency;
  final int? customPeriodDays;
  final DateTime? periodStartDate;
  
  // Active days configuration
  final ActiveDaysMode activeDaysMode;
  final List<int>? activeWeekdays; // 1-7, Monday-Sunday
  final RequireMode requireMode;
  
  // Time window configuration (optional)
  final bool timeWindowEnabled;
  final TimeOfDay? timeWindowStart;
  final TimeOfDay? timeWindowEnd;
  final TimeWindowMode? timeWindowMode;
  
  // Quality layer configuration (optional)
  final bool qualityLayerEnabled;
  final String? qualityLayerLabel;
  
  // Metadata
  final bool isActive;
  final bool isTemplate;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Habit({...});
  
  factory Habit.fromMap(Map<String, dynamic> map) {...}
  Map<String, dynamic> toMap() {...}
  Habit copyWith({...}) {...}
}
```

#### HabitEvent Model

```dart
class HabitEvent {
  final int? id;
  final int habitId;
  
  // Event timing
  final DateTime eventDate;
  final DateTime eventTimestamp;
  
  // Tracking data
  final bool? completed;
  final double? value;
  final double? valueDelta;
  
  // Optional layer data
  final TimeOfDay? timeRecorded;
  final bool? withinTimeWindow;
  final bool? qualityAchieved;
  
  // Metadata
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitEvent({...});
  
  factory HabitEvent.fromMap(Map<String, dynamic> map) {...}
  Map<String, dynamic> toMap() {...}
  HabitEvent copyWith({...}) {...}
}
```

#### Enums

```dart
enum TrackingType { binary, value, timed }
enum GoalType { none, minimum, maximum }
enum Frequency { daily, weekly, monthly, custom }
enum ActiveDaysMode { all, selected }
enum RequireMode { each, any, total }
enum TimeWindowMode { soft, hard }
enum StreakType { completion, timeWindow, quality, perfect }
```

### 2. Repository Layer

#### HabitRepository Interface


```dart
class HabitRepository {
  final DatabaseService _dbService = DatabaseService.instance;
  
  // Habit CRUD operations
  Future<List<Habit>> getActiveHabits();
  Future<Habit?> getHabitById(int id);
  Future<Habit> createHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> archiveHabit(int id);
  Future<void> deleteHabit(int id);
  
  // Event operations
  Future<HabitEvent> logEvent(HabitEvent event);
  Future<List<HabitEvent>> getEventsForHabit(int habitId, {DateTime? startDate, DateTime? endDate});
  Future<List<HabitEvent>> getEventsForDate(int habitId, DateTime date);
  Future<void> updateEvent(HabitEvent event);
  Future<void> deleteEvent(int eventId);
  
  // Streak operations
  Future<HabitStreak?> getStreakForHabit(int habitId, StreakType type);
  Future<void> saveStreak(HabitStreak streak);
  
  // Period progress operations
  Future<HabitPeriodProgress?> getCurrentPeriodProgress(int habitId);
  Future<void> savePeriodProgress(HabitPeriodProgress progress);
}
```

**Design Decisions:**

- Repository returns strongly-typed models, not raw maps
- All database operations are async
- Date range queries for performance optimization
- Separate methods for different query patterns
- Uses centralized DatabaseService for all DB access

### 3. Provider Layer

#### HabitsProvider

```dart
@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  late final HabitRepository _repository;
  late final StreakCalculationService _streakService;
  late final PeriodProgressService _periodService;

  @override
  Future<List<Habit>> build() async {
    _repository = HabitRepository();
    _streakService = StreakCalculationService(_repository);
    _periodService = PeriodProgressService(_repository);
    
    return await _repository.getActiveHabits();
  }

  Future<void> addHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createHabit(habit);
      return await _repository.getActiveHabits();
    });
  }

  Future<void> updateHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateHabit(habit);
      return await _repository.getActiveHabits();
    });
  }

  Future<void> archiveHabit(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.archiveHabit(id);
      return await _repository.getActiveHabits();
    });
  }

  Future<void> logEvent(HabitEvent event) async {
    // Log the event
    await _repository.logEvent(event);
    
    // Recalculate streaks and period progress
    await _streakService.recalculateStreaks(event.habitId);
    await _periodService.recalculatePeriodProgress(event.habitId);
    
    // Refresh the list
    state = await AsyncValue.guard(() async {
      return await _repository.getActiveHabits();
    });
  }
}
```

#### HabitDetailProvider

```dart
@riverpod
class HabitDetailNotifier extends _$HabitDetailNotifier {
  late final HabitRepository _repository;

  @override
  Future<HabitDetailState> build(int habitId) async {
    _repository = HabitRepository();
    
    final habit = await _repository.getHabitById(habitId);
    final events = await _repository.getEventsForHabit(habitId);
    final streaks = await _loadStreaks(habitId);
    final periodProgress = await _repository.getCurrentPeriodProgress(habitId);
    
    return HabitDetailState(
      habit: habit!,
      events: events,
      streaks: streaks,
      periodProgress: periodProgress,
    );
  }

  Future<Map<StreakType, HabitStreak>> _loadStreaks(int habitId) async {
    final streaks = <StreakType, HabitStreak>{};
    for (final type in StreakType.values) {
      final streak = await _repository.getStreakForHabit(habitId, type);
      if (streak != null) streaks[type] = streak;
    }
    return streaks;
  }
}
```

**Design Decisions:**

- Uses Riverpod's code generation for type safety
- Provider coordinates between repository and services
- Automatic recalculation of streaks/progress after logging
- Separate provider for detail view to avoid unnecessary rebuilds
- AsyncValue for loading/error states

### 4. Service Layer

#### StreakCalculationService


```dart
class StreakCalculationService {
  final HabitRepository _repository;
  
  StreakCalculationService(this._repository);

  /// Calculate all streak types for a habit
  Future<void> recalculateStreaks(int habitId) async {
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) return;
    
    for (final type in StreakType.values) {
      final streak = await _calculateStreak(habit, type);
      await _repository.saveStreak(streak);
    }
  }

  /// Calculate a specific streak type
  Future<HabitStreak> _calculateStreak(Habit habit, StreakType type) async {
    int currentStreak = 0;
    DateTime? currentStreakStart;
    int longestStreak = 0;
    DateTime? longestStreakStart;
    DateTime? longestStreakEnd;
    
    // Walk backwards from today
    DateTime currentDate = DateTime.now();
    bool streakBroken = false;
    
    while (!streakBroken) {
      // Check if this date is relevant (active day)
      if (!_isActiveDay(habit, currentDate)) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }
      
      // Check if habit was completed on this date
      final completed = await _checkDayCompletion(habit, currentDate, type);
      
      if (completed) {
        currentStreak++;
        currentStreakStart ??= currentDate;
      } else {
        streakBroken = true;
      }
      
      currentDate = currentDate.subtract(const Duration(days: 1));
      
      // Safety limit: don't go back more than 1 year
      if (currentDate.isBefore(DateTime.now().subtract(const Duration(days: 365)))) {
        break;
      }
    }
    
    // Calculate longest streak (scan historical data)
    longestStreak = await _findLongestStreak(habit, type);
    
    return HabitStreak(
      habitId: habit.id!,
      streakType: type,
      currentStreak: currentStreak,
      currentStreakStartDate: currentStreakStart,
      longestStreak: longestStreak,
      // ... other fields
    );
  }

  bool _isActiveDay(Habit habit, DateTime date) {
    if (habit.activeDaysMode == ActiveDaysMode.all) return true;
    
    final weekday = date.weekday; // 1-7, Monday-Sunday
    return habit.activeWeekdays?.contains(weekday) ?? true;
  }

  Future<bool> _checkDayCompletion(Habit habit, DateTime date, StreakType type) async {
    final events = await _repository.getEventsForDate(habit.id!, date);
    
    if (events.isEmpty) return false;
    
    switch (type) {
      case StreakType.completion:
        return _checkBasicCompletion(habit, events);
      case StreakType.timeWindow:
        return _checkTimeWindowCompletion(habit, events);
      case StreakType.quality:
        return _checkQualityCompletion(habit, events);
      case StreakType.perfect:
        return _checkPerfectCompletion(habit, events);
    }
  }

  bool _checkBasicCompletion(Habit habit, List<HabitEvent> events) {
    if (habit.trackingType == TrackingType.binary) {
      return events.any((e) => e.completed == true);
    }
    
    final total = events.fold<double>(0, (sum, e) => sum + (e.valueDelta ?? 0));
    
    switch (habit.goalType) {
      case GoalType.minimum:
        return total >= (habit.targetValue ?? 0);
      case GoalType.maximum:
        return total <= (habit.targetValue ?? double.infinity);
      case GoalType.none:
        return events.isNotEmpty;
    }
  }

  bool _checkTimeWindowCompletion(Habit habit, List<HabitEvent> events) {
    if (!habit.timeWindowEnabled) return false;
    return events.any((e) => e.withinTimeWindow == true);
  }

  bool _checkQualityCompletion(Habit habit, List<HabitEvent> events) {
    if (!habit.qualityLayerEnabled) return false;
    return events.any((e) => e.qualityAchieved == true);
  }

  bool _checkPerfectCompletion(Habit habit, List<HabitEvent> events) {
    return _checkBasicCompletion(habit, events) &&
           (!habit.timeWindowEnabled || _checkTimeWindowCompletion(habit, events)) &&
           (!habit.qualityLayerEnabled || _checkQualityCompletion(habit, events));
  }

  Future<int> _findLongestStreak(Habit habit, StreakType type) async {
    // Implementation: scan all historical events to find longest streak
    // This is expensive, so we cache the result
    return 0; // Placeholder
  }
}
```

#### PeriodProgressService


```dart
class PeriodProgressService {
  final HabitRepository _repository;
  
  PeriodProgressService(this._repository);

  /// Recalculate period progress for a habit
  Future<void> recalculatePeriodProgress(int habitId) async {
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) return;
    
    // Only calculate for non-daily habits
    if (habit.frequency == Frequency.daily) return;
    
    final progress = await _calculatePeriodProgress(habit);
    await _repository.savePeriodProgress(progress);
  }

  Future<HabitPeriodProgress> _calculatePeriodProgress(Habit habit) async {
    final period = _getCurrentPeriod(habit);
    final events = await _repository.getEventsForHabit(
      habit.id!,
      startDate: period.start,
      endDate: period.end,
    );
    
    final activeDays = _getActiveDaysInPeriod(habit, period.start, period.end);
    final adjustedTarget = _calculateAdjustedTarget(habit, activeDays.length);
    final currentValue = _calculateCurrentValue(habit, events, activeDays);
    final completed = _checkPeriodCompletion(habit, currentValue, adjustedTarget, events, activeDays);
    
    return HabitPeriodProgress(
      habitId: habit.id!,
      periodType: habit.frequency,
      periodStartDate: period.start,
      periodEndDate: period.end,
      targetValue: adjustedTarget,
      currentValue: currentValue,
      completed: completed,
      // ... other fields
    );
  }

  ({DateTime start, DateTime end}) _getCurrentPeriod(Habit habit) {
    final now = DateTime.now();
    
    switch (habit.frequency) {
      case Frequency.weekly:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(monday.year, monday.month, monday.day),
          end: DateTime(monday.year, monday.month, monday.day).add(const Duration(days: 6)),
        );
      
      case Frequency.monthly:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      
      case Frequency.custom:
        // Calculate based on periodStartDate and customPeriodDays
        final startDate = habit.periodStartDate ?? now;
        final daysSinceStart = now.difference(startDate).inDays;
        final periodNumber = daysSinceStart ~/ (habit.customPeriodDays ?? 7);
        final periodStart = startDate.add(Duration(days: periodNumber * (habit.customPeriodDays ?? 7)));
        final periodEnd = periodStart.add(Duration(days: (habit.customPeriodDays ?? 7) - 1));
        return (start: periodStart, end: periodEnd);
      
      case Frequency.daily:
        return (start: now, end: now);
    }
  }

  List<DateTime> _getActiveDaysInPeriod(Habit habit, DateTime start, DateTime end) {
    final days = <DateTime>[];
    DateTime current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (habit.activeDaysMode == ActiveDaysMode.all ||
          habit.activeWeekdays?.contains(current.weekday) == true) {
        days.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

  double _calculateAdjustedTarget(Habit habit, int activeDaysCount) {
    switch (habit.requireMode) {
      case RequireMode.each:
        return (habit.targetValue ?? 0) * activeDaysCount;
      case RequireMode.any:
      case RequireMode.total:
        return habit.targetValue ?? 0;
    }
  }

  double _calculateCurrentValue(Habit habit, List<HabitEvent> events, List<DateTime> activeDays) {
    if (habit.requireMode == RequireMode.each) {
      // Check each day individually
      int completedDays = 0;
      for (final day in activeDays) {
        final dayEvents = events.where((e) => 
          e.eventDate.year == day.year &&
          e.eventDate.month == day.month &&
          e.eventDate.day == day.day
        ).toList();
        
        final dayTotal = dayEvents.fold<double>(0, (sum, e) => sum + (e.valueDelta ?? 0));
        if (dayTotal >= (habit.targetValue ?? 0)) {
          completedDays++;
        }
      }
      return completedDays.toDouble();
    } else {
      // Sum all events
      return events.fold<double>(0, (sum, e) => sum + (e.valueDelta ?? 0));
    }
  }

  bool _checkPeriodCompletion(Habit habit, double currentValue, double target, 
                               List<HabitEvent> events, List<DateTime> activeDays) {
    switch (habit.requireMode) {
      case RequireMode.each:
        // All active days must be completed
        return currentValue >= activeDays.length;
      
      case RequireMode.any:
        // At least one day must be completed
        return currentValue >= 1;
      
      case RequireMode.total:
        // Total must meet target
        switch (habit.goalType) {
          case GoalType.minimum:
            return currentValue >= target;
          case GoalType.maximum:
            return currentValue <= target;
          case GoalType.none:
            return events.isNotEmpty;
        }
    }
  }
}
```

**Design Decisions:**

- Services contain pure business logic, no UI concerns
- Services use repository for data access
- Complex calculations are broken into smaller methods
- Services are stateless and can be easily tested
- Caching strategy: calculate on-demand, store in database

### 5. Screen Designs

#### HabitsScreen


**Layout:**
```
┌─────────────────────────────────────┐
│  ← Habits                        ⋮  │ ← App Bar
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🏃 Exercise                 │   │
│  │ Current Streak: 5 days      │   │
│  │ ████████░░ 80%              │   │
│  │                         [✓] │   │ ← Quick log button
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💧 Drink Water              │   │
│  │ Today: 6/8 glasses          │   │
│  │ ██████░░░░ 75%              │   │
│  │                         [+] │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📚 Read                     │   │
│  │ This Week: 3/5 days         │   │
│  │ ██████░░░░ 60%              │   │
│  │                         [✓] │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
                                  [+] ← FAB to add habit
```

**Widget Tree:**
```dart
Scaffold(
  appBar: NumuAppBar(title: 'Habits'),
  body: Consumer(
    builder: (context, ref, child) {
      final habitsAsync = ref.watch(habitsNotifierProvider);
      
      return habitsAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorWidget(error: err),
        data: (habits) {
          if (habits.isEmpty) {
            return EmptyHabitsState();
          }
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              return HabitListItem(habit: habits[index]);
            },
          );
        },
      );
    },
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () => context.push('/habits/add'),
    child: Icon(Icons.add),
  ),
)
```

#### AddHabitScreen

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Add Habit                        │
├─────────────────────────────────────┤
│                                     │
│  Habit Name *                       │
│  ┌─────────────────────────────┐   │
│  │ Exercise                    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Description                        │
│  ┌─────────────────────────────┐   │
│  │ Daily morning workout       │   │
│  └─────────────────────────────┘   │
│                                     │
│  Tracking Type                      │
│  ┌─────┬─────┬─────┐               │
│  │ ✓   │     │     │               │
│  │Yes/No│Value│Timed│               │
│  └─────┴─────┴─────┘               │
│                                     │
│  Goal                               │
│  ┌─────┬─────┬─────┐               │
│  │     │ ✓   │     │               │
│  │None │Min  │Max  │               │
│  └─────┴─────┴─────┘               │
│                                     │
│  Target: [30] minutes               │
│                                     │
│  Frequency                          │
│  ┌─────┬─────┬─────┬─────┐         │
│  │ ✓   │     │     │     │         │
│  │Daily│Week │Month│Custom│         │
│  └─────┴─────┴─────┴─────┘         │
│                                     │
│  Icon & Color                       │
│  🏃 ●                               │
│                                     │
│  ▼ Advanced Options                │
│                                     │
│  ┌─────────────────────────────┐   │
│  │         Save Habit          │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Form Validation:**
- Name is required (min 1 character)
- Target value required if goal type is minimum/maximum
- Unit recommended if tracking type is value
- Custom period days required if frequency is custom

#### HabitDetailScreen

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Exercise                      ⋮  │ ← Edit menu
├─────────────────────────────────────┤
│                                     │
│         🏃                          │
│      Exercise                       │
│   Daily morning workout             │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Current Streak: 5 days      │   │
│  │ Longest Streak: 12 days     │   │
│  │ Consistency: 85%            │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Calendar View              │   │
│  │  Mo Tu We Th Fr Sa Su       │   │
│  │  ✓  ✓  ✓  ✓  ✓  ✗  ✗       │   │
│  │  ✓  ✓  ✓  ✓  ✓  ✓  ✗       │   │
│  └─────────────────────────────┘   │
│                                     │
│  Recent Activity                    │
│  ┌─────────────────────────────┐   │
│  │ Today, 7:30 AM              │   │
│  │ Completed ✓                 │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Yesterday, 7:15 AM          │   │
│  │ Completed ✓                 │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
                                  [+] ← FAB to log event
```

#### LogHabitEventDialog

**Layout for Binary Habit:**
```
┌─────────────────────────────────────┐
│  Log Exercise                       │
├─────────────────────────────────────┤
│                                     │
│  Date: [Today ▼]                    │
│                                     │
│  Time: [7:30 AM]                    │
│  ✓ Within preferred window          │
│                                     │
│  □ Quality: Stretched after         │
│                                     │
│  Notes (optional)                   │
│  ┌─────────────────────────────┐   │
│  │ Felt great today!           │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │  Cancel  │  │   Save   │        │
│  └──────────┘  └──────────┘        │
│                                     │
└─────────────────────────────────────┘
```

**Layout for Value Habit:**
```
┌─────────────────────────────────────┐
│  Log Drink Water                    │
├─────────────────────────────────────┤
│                                     │
│  Date: [Today ▼]                    │
│                                     │
│  Amount                             │
│  ┌─────────────────────────────┐   │
│  │ [2] glasses                 │   │
│  └─────────────────────────────┘   │
│                                     │
│  Today's Total: 6/8 glasses         │
│  ████████░░ 75%                     │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │  Cancel  │  │   Save   │        │
│  └──────────┘  └──────────┘        │
│                                     │
└─────────────────────────────────────┘
```

### 6. Reusable Widgets

#### HabitListItem


```dart
class HabitListItem extends ConsumerWidget {
  final Habit habit;
  
  const HabitListItem({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/habits/${habit.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon with color
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(habit.color)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(habit.icon, style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              
              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    HabitStreakDisplay(habitId: habit.id!),
                    const SizedBox(height: 4),
                    HabitProgressIndicator(habitId: habit.id!),
                  ],
                ),
              ),
              
              // Quick log button
              HabitQuickLogButton(habit: habit),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### HabitQuickLogButton

```dart
class HabitQuickLogButton extends ConsumerWidget {
  final Habit habit;
  
  const HabitQuickLogButton({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show for binary habits
    if (habit.trackingType != TrackingType.binary) {
      return IconButton(
        icon: Icon(Icons.add),
        onPressed: () => _showLogDialog(context, ref),
      );
    }
    
    return IconButton(
      icon: Icon(Icons.check_circle_outline),
      onPressed: () => _quickLog(ref),
    );
  }

  Future<void> _quickLog(WidgetRef ref) async {
    final event = HabitEvent(
      habitId: habit.id!,
      eventDate: DateTime.now(),
      eventTimestamp: DateTime.now(),
      completed: true,
    );
    
    await ref.read(habitsNotifierProvider.notifier).logEvent(event);
  }

  void _showLogDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => LogHabitEventDialog(habit: habit),
    );
  }
}
```

#### EmptyHabitsState

```dart
class EmptyHabitsState extends StatelessWidget {
  const EmptyHabitsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your first habit!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/habits/add'),
            icon: Icon(Icons.add),
            label: Text('Add Habit'),
          ),
        ],
      ),
    );
  }
}
```

#### Form Widgets

**TrackingTypeSelector:**
```dart
class TrackingTypeSelector extends StatelessWidget {
  final TrackingType? value;
  final ValueChanged<TrackingType> onChanged;
  
  const TrackingTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrackingType>(
      segments: const [
        ButtonSegment(value: TrackingType.binary, label: Text('Yes/No'), icon: Icon(Icons.check)),
        ButtonSegment(value: TrackingType.value, label: Text('Value'), icon: Icon(Icons.numbers)),
        ButtonSegment(value: TrackingType.timed, label: Text('Timed'), icon: Icon(Icons.schedule)),
      ],
      selected: value != null ? {value!} : {},
      onSelectionChanged: (Set<TrackingType> selected) {
        if (selected.isNotEmpty) onChanged(selected.first);
      },
    );
  }
}
```

**IconPicker:**
```dart
class IconPicker extends StatelessWidget {
  final String? selectedIcon;
  final ValueChanged<String> onIconSelected;
  
  static const List<String> commonIcons = [
    '🏃', '💧', '📚', '🧘', '🍎', '💪', '🎯', '✍️', 
    '🚶', '🏋️', '🧠', '❤️', '🌙', '☀️', '🎨', '🎵'
  ];

  const IconPicker({required this.selectedIcon, required this.onIconSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commonIcons.map((icon) {
        final isSelected = icon == selectedIcon;
        return InkWell(
          onTap: () => onIconSelected(icon),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 24)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

**ColorPicker:**
```dart
class ColorPicker extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;
  
  static const List<String> commonColors = [
    '0xFFE57373', '0xFFBA68C8', '0xFF64B5F6', '0xFF4DB6AC',
    '0xFF81C784', '0xFFFFD54F', '0xFFFF8A65', '0xFF90A4AE',
  ];

  const ColorPicker({required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commonColors.map((colorHex) {
        final isSelected = colorHex == selectedColor;
        return InkWell(
          onTap: () => onColorSelected(colorHex),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(int.parse(colorHex)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSelected ? Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }
}
```

## Data Models

### Database Schema


**Updated DatabaseService with Habit Tables:**

```dart
class DatabaseService {
  // ... existing code ...
  
  Future<void> _createDB(Database db, int version) async {
    // Existing tables
    await db.execute('''CREATE TABLE $tasksTable (...)''');
    
    // Habits table
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category_id INTEGER,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        tracking_type TEXT NOT NULL,
        goal_type TEXT NOT NULL,
        target_value REAL,
        unit TEXT,
        frequency TEXT NOT NULL,
        custom_period_days INTEGER,
        period_start_date TEXT,
        active_days_mode TEXT NOT NULL,
        active_weekdays TEXT,
        require_mode TEXT NOT NULL,
        time_window_enabled INTEGER NOT NULL DEFAULT 0,
        time_window_start TEXT,
        time_window_end TEXT,
        time_window_mode TEXT,
        quality_layer_enabled INTEGER NOT NULL DEFAULT 0,
        quality_layer_label TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_template INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    
    // Habit events table
    await db.execute('''
      CREATE TABLE habit_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        event_date TEXT NOT NULL,
        event_timestamp TEXT NOT NULL,
        completed INTEGER,
        value REAL,
        value_delta REAL,
        time_recorded TEXT,
        within_time_window INTEGER,
        quality_achieved INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Categories table (updated)
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        color TEXT NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Habit streaks table
    await db.execute('''
      CREATE TABLE habit_streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        streak_type TEXT NOT NULL,
        current_streak INTEGER NOT NULL DEFAULT 0,
        current_streak_start_date TEXT,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak_start_date TEXT,
        longest_streak_end_date TEXT,
        total_completions INTEGER NOT NULL DEFAULT 0,
        total_days_active INTEGER NOT NULL DEFAULT 0,
        consistency_rate REAL NOT NULL DEFAULT 0,
        last_calculated_at TEXT NOT NULL,
        last_event_date TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE (habit_id, streak_type)
      )
    ''');
    
    // Habit period progress table
    await db.execute('''
      CREATE TABLE habit_period_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        period_type TEXT NOT NULL,
        period_start_date TEXT NOT NULL,
        period_end_date TEXT NOT NULL,
        target_value REAL NOT NULL,
        current_value REAL NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        completion_date TEXT,
        time_window_completions INTEGER NOT NULL DEFAULT 0,
        quality_completions INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_habit_events_habit_date ON habit_events(habit_id, event_date)');
    await db.execute('CREATE INDEX idx_habit_events_date ON habit_events(event_date)');
    await db.execute('CREATE INDEX idx_habits_active ON habits(is_active)');
    await db.execute('CREATE INDEX idx_habit_streaks_habit_type ON habit_streaks(habit_id, streak_type)');
    await db.execute('CREATE INDEX idx_period_progress_habit ON habit_period_progress(habit_id, period_start_date)');
  }
}
```

### Type Conversions

**Storing Enums:**
```dart
// Store as string
trackingType: habit.trackingType.name, // 'binary', 'value', 'timed'

// Retrieve from string
trackingType: TrackingType.values.byName(map['tracking_type']),
```

**Storing Lists:**
```dart
// Store as JSON string
activeWeekdays: jsonEncode(habit.activeWeekdays), // '[1,2,3,4,5]'

// Retrieve from JSON
activeWeekdays: map['active_weekdays'] != null 
  ? List<int>.from(jsonDecode(map['active_weekdays']))
  : null,
```

**Storing TimeOfDay:**
```dart
// Store as string 'HH:mm'
timeWindowStart: habit.timeWindowStart != null
  ? '${habit.timeWindowStart!.hour}:${habit.timeWindowStart!.minute}'
  : null,

// Retrieve from string
timeWindowStart: map['time_window_start'] != null
  ? TimeOfDay(
      hour: int.parse(map['time_window_start'].split(':')[0]),
      minute: int.parse(map['time_window_start'].split(':')[1]),
    )
  : null,
```

**Storing DateTime:**
```dart
// Store as ISO 8601 string
createdAt: habit.createdAt.toIso8601String(),

// Retrieve from string
createdAt: DateTime.parse(map['created_at']),
```

## Error Handling

### Error Types


```dart
class HabitException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  HabitException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'HabitException: $message';
}

class HabitValidationException extends HabitException {
  HabitValidationException(String message) : super(message, code: 'VALIDATION_ERROR');
}

class HabitNotFoundException extends HabitException {
  HabitNotFoundException(int id) : super('Habit with id $id not found', code: 'NOT_FOUND');
}

class DatabaseException extends HabitException {
  DatabaseException(String message, {dynamic originalError}) 
    : super(message, code: 'DATABASE_ERROR', originalError: originalError);
}
```

### Error Handling in Repository

```dart
class HabitRepository {
  Future<Habit> createHabit(Habit habit) async {
    try {
      // Validate
      if (habit.name.trim().isEmpty) {
        throw HabitValidationException('Habit name cannot be empty');
      }
      
      if (habit.goalType != GoalType.none && habit.targetValue == null) {
        throw HabitValidationException('Target value required for goal type ${habit.goalType}');
      }
      
      // Create
      final db = await _dbService.database;
      final id = await db.insert('habits', habit.toMap());
      return habit.copyWith(id: id);
      
    } on HabitException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to create habit', originalError: e);
    }
  }
}
```

### Error Handling in Provider

```dart
@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  @override
  Future<List<Habit>> build() async {
    try {
      return await _repository.getActiveHabits();
    } catch (e) {
      // Log error
      CoreLoggingUtility.logError('Failed to load habits', e);
      rethrow;
    }
  }
}
```

### Error Display in UI

```dart
// In screen
habitsAsync.when(
  loading: () => Center(child: CircularProgressIndicator()),
  error: (error, stack) {
    String message = 'An error occurred';
    
    if (error is HabitValidationException) {
      message = error.message;
    } else if (error is DatabaseException) {
      message = 'Database error. Please try again.';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(habitsNotifierProvider),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  },
  data: (habits) => /* ... */,
)
```

## Testing Strategy

### Unit Tests

**Model Tests:**
- Test `toMap()` and `fromMap()` conversions
- Test `copyWith()` method
- Test enum conversions
- Test date/time conversions

**Repository Tests:**
- Mock DatabaseService
- Test CRUD operations
- Test error handling
- Test query filters

**Service Tests:**
- Mock HabitRepository
- Test streak calculation logic
- Test period progress calculation
- Test edge cases (no events, archived habits, etc.)

**Provider Tests:**
- Mock repository and services
- Test state transitions
- Test error handling
- Test refresh logic

### Widget Tests

**Screen Tests:**
- Test empty state display
- Test loading state display
- Test error state display
- Test data display
- Test navigation

**Widget Tests:**
- Test HabitListItem rendering
- Test quick log button behavior
- Test form widget interactions
- Test dialog display and submission

### Integration Tests

- Test complete flow: add habit → log event → view detail
- Test streak calculation after multiple events
- Test period progress updates
- Test navigation between screens

## Performance Optimization

### Database Optimization


**Indexes:**
```sql
-- Fast lookup of events for a habit on specific dates
CREATE INDEX idx_habit_events_habit_date ON habit_events(habit_id, event_date);

-- Fast queries for today's events across all habits
CREATE INDEX idx_habit_events_date ON habit_events(event_date);

-- Filter active habits quickly
CREATE INDEX idx_habits_active ON habits(is_active);

-- Lookup streaks by habit and type
CREATE INDEX idx_habit_streaks_habit_type ON habit_streaks(habit_id, streak_type);

-- Find current period for a habit
CREATE INDEX idx_period_progress_habit ON habit_period_progress(habit_id, period_start_date);
```

**Query Optimization:**
```dart
// Bad: Load all events then filter in Dart
final allEvents = await db.query('habit_events');
final filtered = allEvents.where((e) => e['habit_id'] == habitId);

// Good: Filter in SQL
final events = await db.query(
  'habit_events',
  where: 'habit_id = ? AND event_date >= ? AND event_date <= ?',
  whereArgs: [habitId, startDate.toIso8601String(), endDate.toIso8601String()],
);
```

### Caching Strategy

**Streak Caching:**
- Calculate streaks when events are logged
- Store in `habit_streaks` table
- Include `last_calculated_at` timestamp
- Recalculate if stale (> 1 hour) or when new event added

**Period Progress Caching:**
- Calculate when events are logged
- Store in `habit_period_progress` table
- Create new record when period boundary crossed
- Update existing record when events added to current period

**Provider Caching:**
```dart
// Riverpod automatically caches provider data
// Refresh only when needed
ref.refresh(habitsNotifierProvider); // Manual refresh
ref.invalidate(habitsNotifierProvider); // Invalidate cache
```

### UI Optimization

**Lazy Loading:**
```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: habits.length,
  itemBuilder: (context, index) => HabitListItem(habit: habits[index]),
)
```

**Debouncing:**
```dart
// Debounce rapid taps on quick log button
Timer? _debounceTimer;

void _quickLog() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    // Perform log
  });
}
```

**Optimistic Updates:**
```dart
Future<void> logEvent(HabitEvent event) async {
  // Update UI immediately
  state = AsyncValue.data([...state.value!, /* updated habit */]);
  
  try {
    // Perform actual operation
    await _repository.logEvent(event);
  } catch (e) {
    // Revert on error
    state = await AsyncValue.guard(() => _repository.getActiveHabits());
    rethrow;
  }
}
```

## Navigation and Routing

### Route Definitions

```dart
// In router.dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => NumuAppShell(child: child),
        routes: [
          // ... existing routes ...
          
          // Habits routes
          GoRoute(
            path: '/habits',
            name: 'habits',
            pageBuilder: (context, state) => NoTransitionPage(
              child: HabitsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-habit',
                pageBuilder: (context, state) => MaterialPage(
                  child: AddHabitScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'habit-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(
                    child: HabitDetailScreen(habitId: id),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-habit',
                    pageBuilder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return MaterialPage(
                        child: EditHabitScreen(habitId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
```

### Navigation in App Shell

```dart
// Update NumuAppShell drawer
ListTile(
  leading: const Icon(Icons.track_changes),
  title: const Text('Habits'),
  onTap: () {
    Navigator.pop(context);
    context.go('/habits');
  },
),
```

## Implementation Phases

### Phase 1: Core Foundation (MVP)
- Database schema setup
- Basic models (Habit, HabitEvent)
- HabitRepository with CRUD operations
- HabitsProvider for state management
- HabitsScreen with list display
- AddHabitScreen with basic form (name, icon, color, tracking type)
- Simple binary habit tracking only
- Quick log functionality

**Deliverable:** Users can create binary habits and log completions

### Phase 2: Value Tracking & Streaks
- Extend models for value tracking
- Implement StreakCalculationService
- HabitStreak model and database table
- HabitDetailScreen with streak display
- LogHabitEventDialog for value input
- Streak display in HabitListItem

**Deliverable:** Users can track measurable habits and see streaks

### Phase 3: Period-Based Habits
- Implement PeriodProgressService
- HabitPeriodProgress model and database table
- Weekly/monthly frequency support
- Period progress display in UI
- Calendar view widget

**Deliverable:** Users can create weekly/monthly habits

### Phase 4: Advanced Features
- Time window configuration
- Quality layer configuration
- Active days selection
- Require mode options
- Advanced options in add/edit forms
- Time window and quality indicators in UI

**Deliverable:** Full feature parity with design guidelines

### Phase 5: Polish & Optimization
- Categories implementation
- Habit templates
- Performance optimization
- Comprehensive error handling
- Unit and widget tests
- UI polish and animations

**Deliverable:** Production-ready habit tracking system

## Design Decisions Summary

1. **Repository Pattern**: Separates data access from business logic, makes testing easier
2. **Riverpod for State Management**: Type-safe, testable, and follows Flutter best practices
3. **Service Layer for Calculations**: Keeps complex logic out of providers and repositories
4. **Reusable Widgets**: Each widget in its own file for maintainability
5. **Centralized Database Service**: Single source of truth for database access
6. **Caching Strategy**: Balance between performance and data freshness
7. **Strong Typing**: Models and enums prevent runtime errors
8. **Error Handling**: Custom exceptions with user-friendly messages
9. **Phased Implementation**: Incremental delivery of features
10. **Performance First**: Indexes, query optimization, and lazy loading

## Suggested Changes to Guidelines

**[SUGGESTED CHANGE 1]**: Simplify initial implementation by making categories optional
- **Rationale**: Categories add complexity but aren't essential for MVP
- **Recommendation**: Implement categories in Phase 5 instead of Phase 1

**[SUGGESTED CHANGE 2]**: Add a `last_logged_date` field to habits table
- **Rationale**: Quickly determine if habit was logged today without querying events
- **Recommendation**: Add field for performance optimization

**[SUGGESTED CHANGE 3]**: Consider using a single `metadata` JSON field for advanced options
- **Rationale**: Reduces table width and makes schema more flexible
- **Recommendation**: Store time window, quality layer, and other optional configs in JSON
- **Trade-off**: Harder to query, but more flexible for future additions

**[SUGGESTED CHANGE 4]**: Add soft delete for events
- **Rationale**: Users may accidentally log events and want to undo
- **Recommendation**: Add `deleted_at` field to habit_events table
- **Implementation**: Filter out deleted events in queries, allow restore within 30 days

---

**End of Design Document**
