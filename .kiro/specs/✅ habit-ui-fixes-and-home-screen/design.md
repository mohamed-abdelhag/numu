# Design Document

## Overview

This design addresses critical issues in the habit tracking system related to Riverpod provider lifecycle management, UI state synchronization, and week-based progress calculations. The solution implements proper async operation handling with `ref.mounted` checks, establishes a unidirectional data flow pattern for UI updates, adds user-configurable week start preferences, and ensures real-time reflection of habit status including streaks across all UI components.

## Architecture

### Component Interaction Flow

```
User Action (Quick Action Button)
    ↓
HabitsProvider.logEvent() [with ref.mounted checks]
    ↓
Database Update + Streak/Progress Recalculation
    ↓
Provider State Update (if ref.mounted)
    ↓
UI Rebuild (HabitCard, DailyItemCard)
    ↓
Display Updated Status + Streaks
```

### Key Architectural Principles

1. **Unidirectional Data Flow**: UI components never modify their own state directly; all state changes flow through providers
2. **Provider Lifecycle Safety**: All async operations check `ref.mounted` before state updates
3. **Single Source of Truth**: HabitDetailProvider serves as the authoritative source for habit status, streaks, and progress
4. **Week Configuration**: UserProfile stores week start preference, used by all date-based calculations

## Components and Interfaces

### 1. HabitsProvider Modifications

**Purpose**: Ensure proper async operation handling and state updates

**Current Implementation**: Your `HabitsNotifier` already follows best practices with `AsyncValue.guard()` for error handling.

**Changes Needed**:
- Add `mounted` checks in widget callbacks before calling provider methods
- Ensure proper error propagation using `rethrow` instead of setting error state manually
- No need for `ref.mounted` - Riverpod 3.0 prevents disposed provider interactions automatically

**Current Pattern (Already Correct)**:
```dart
@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  @override
  Future<List<Habit>> build() async {
    _repository = HabitRepository();
    _streakService = StreakCalculationService(_repository);
    _periodService = PeriodProgressService(_repository);
    _reminderSchedulerService = ReminderSchedulerService();
    
    try {
      return await _repository.getActiveHabits();
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'build',
        'Failed to load active habits: $e\n$stackTrace',
      );
      rethrow; // Proper error handling
    }
  }

  Future<void> logEvent(HabitEvent event) async {
    try {
      await _repository.logEvent(event);
      await _streakService.recalculateStreaks(event.habitId);
      await _periodService.recalculatePeriodProgress(event.habitId);

      // Refresh the habit list
      state = await AsyncValue.guard(() async {
        return await _repository.getActiveHabits();
      });
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'HabitsProvider',
        'logEvent',
        'Failed to log event for habit ID ${event.habitId}: $e\n$stackTrace',
      );
      rethrow; // Let Riverpod handle error state
    }
  }
}
```

**Note**: Riverpod 3.0 automatically throws errors when interacting with disposed providers, eliminating the need for manual lifecycle checks.

### 2. HabitQuickActionButton Modifications

**Purpose**: Ensure widget lifecycle safety when calling provider methods

**Current Implementation**: Your `HabitQuickActionButton` uses `FutureBuilder` to query repository directly and manages local loading state.

**Changes Needed**:
- Add `context.mounted` checks before async provider calls
- Keep `mounted` checks before `setState()`
- Current `FutureBuilder` approach is acceptable for quick actions
- Ensure `onActionComplete` callback invalidates related providers

**Current Pattern (Already Mostly Correct)**:

```dart
class _HabitQuickActionButtonState extends ConsumerState<HabitQuickActionButton> {
  bool _isLoading = false;

  // Current implementation uses FutureBuilder - this is fine for immediate queries
  Widget _buildValueAction() {
    return FutureBuilder<double>(
      future: _getTodayTotal(),
      builder: (context, snapshot) {
        final todayTotal = snapshot.data ?? 0;
        return IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            await _incrementValue();
          },
        );
      },
    );
  }
  
  Future<void> _incrementValue() async {
    setState(() => _isLoading = true);
    
    try {
      final event = HabitEvent(/* ... */);
      
      // Add context.mounted check before provider call
      if (!context.mounted) return;
      
      await ref.read(habitsProvider.notifier).logEvent(event);
      
      if (mounted) {
        widget.onActionComplete?.call();
        _showSuccessSnackbar('...');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to log value: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

**Recommended Enhancement**: Consider using `ref.watch(habitDetailProvider)` instead of `FutureBuilder` for reactive updates, but current implementation is functional.

### 3. UserProfile Model Extension

**Purpose**: Store user's week start preference

**Current State**: UserProfile does NOT have a `startOfWeek` field.

**Changes Required**:

- Add `startOfWeek` field (int, 1-7 representing Monday-Sunday)
- Default value: 1 (Monday)
- Update database schema to include new column
- Add validation in copyWith method

**Updated Interface**:

```dart
class UserProfile {
  final int? id;
  final String name;
  final String? email;
  final String? profilePicturePath;
  final int startOfWeek; // 1 = Monday, 7 = Sunday
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
    required this.name,
    this.email,
    this.profilePicturePath,
    this.startOfWeek = 1, // Default to Monday
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      profilePicturePath: map['profile_picture_path'] as String?,
      startOfWeek: map['start_of_week'] as int? ?? 1, // Default to Monday
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'profile_picture_path': profilePicturePath,
      'start_of_week': startOfWeek,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePicturePath,
    int? startOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Validate startOfWeek if provided
    if (startOfWeek != null && (startOfWeek < 1 || startOfWeek > 7)) {
      throw ArgumentError('startOfWeek must be between 1 and 7');
    }
    
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      startOfWeek: startOfWeek ?? this.startOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 4. PeriodProgressService Modifications

**Purpose**: Use user's week start preference for calculations

**Changes**:
- Accept `startOfWeek` parameter in week calculation methods
- Adjust `_getCurrentPeriod` to use custom week start
- Update all callers to pass user's preference

**Interface**:
```dart
class PeriodProgressService {
  Future<void> recalculatePeriodProgress(
    int habitId, {
    int startOfWeek = 1,
  }) async {
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) return;

    if (habit.frequency == Frequency.daily) return;

    final progress = await _calculatePeriodProgress(habit, startOfWeek);
    await _repository.savePeriodProgress(progress);
  }

  ({DateTime start, DateTime end}) _getCurrentPeriod(
    Habit habit,
    int startOfWeek,
  ) {
    final now = DateTime.now();

    switch (habit.frequency) {
      case Frequency.weekly:
        // Calculate week start based on user preference
        final daysFromWeekStart = (now.weekday - startOfWeek + 7) % 7;
        final weekStart = now.subtract(Duration(days: daysFromWeekStart));
        return (
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(weekStart.year, weekStart.month, weekStart.day)
              .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)),
        );
      // ... other cases
    }
  }
}
```

### 5. HabitCard Modifications

**Purpose**: Display real-time status and streaks from provider

**Changes**:
- Remove mock data generation
- Watch HabitDetailProvider for current status
- Display actual weekly progress based on events
- Show current and longest streaks
- Calculate week progress using user's startOfWeek preference

**Interface**:
```dart
class HabitCard extends ConsumerWidget {
  final Habit habit;
  final VoidCallback? onQuickActionComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch habit detail for real-time data
    final habitDetailAsync = ref.watch(habitDetailProvider(habit.id!));
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return habitDetailAsync.when(
      data: (detailState) {
        final startOfWeek = userProfileAsync.value?.startOfWeek ?? 1;
        final weeklyProgress = _calculateWeeklyProgress(
          detailState.events,
          startOfWeek,
        );
        final currentStreak = detailState.streaks[StreakType.completion]?.currentStreak ?? 0;
        final longestStreak = detailState.streaks[StreakType.completion]?.longestStreak ?? 0;
        final weekProgress = _calculateWeekProgress(detailState.events, startOfWeek);
        
        return _buildCard(
          weeklyProgress: weeklyProgress,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          weekProgress: weekProgress,
        );
      },
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard(),
    );
  }
  
  List<DailyHabitStatus> _calculateWeeklyProgress(
    List<HabitEvent> events,
    int startOfWeek,
  ) {
    final now = DateTime.now();
    final daysFromWeekStart = (now.weekday - startOfWeek + 7) % 7;
    final weekStart = now.subtract(Duration(days: daysFromWeekStart));
    
    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayEvents = events.where((e) {
        final eventDay = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
        final targetDay = DateTime(date.year, date.month, date.day);
        return eventDay.isAtSameMomentAs(targetDay);
      }).toList();
      
      return _calculateDayStatus(date, dayEvents, now);
    });
  }
  
  double _calculateWeekProgress(List<HabitEvent> events, int startOfWeek) {
    final now = DateTime.now();
    final daysFromWeekStart = (now.weekday - startOfWeek + 7) % 7;
    final weekStart = now.subtract(Duration(days: daysFromWeekStart));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    // Count completed days in current week
    int completedDays = 0;
    int totalDays = 0;
    
    for (int i = 0; i <= daysFromWeekStart; i++) {
      final date = weekStart.add(Duration(days: i));
      totalDays++;
      
      final dayEvents = events.where((e) {
        final eventDay = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
        final targetDay = DateTime(date.year, date.month, date.day);
        return eventDay.isAtSameMomentAs(targetDay);
      }).toList();
      
      if (_isDayCompleted(dayEvents)) {
        completedDays++;
      }
    }
    
    return totalDays > 0 ? completedDays / totalDays : 0.0;
  }
}
```

### 6. DailyItemCard Modifications

**Purpose**: Display real-time status and streaks from provider

**Changes**:
- Watch HabitDetailProvider instead of querying repository directly
- Display current streak value
- Update immediately when habit events are logged
- Use same week calculation logic as HabitCard

**Interface**:
```dart
class DailyItemCard extends ConsumerWidget {
  final DailyItem item;
  final VoidCallback? onActionComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.type == DailyItemType.habit && item.habitId != null) {
      final habitDetailAsync = ref.watch(habitDetailProvider(item.habitId!));
      
      return habitDetailAsync.when(
        data: (detailState) {
          final currentStreak = detailState.streaks[StreakType.completion]?.currentStreak ?? 0;
          final todayValue = _calculateTodayValue(detailState.events);
          
          return _buildHabitCard(
            currentStreak: currentStreak,
            todayValue: todayValue,
          );
        },
        loading: () => _buildLoadingCard(),
        error: (_, __) => _buildErrorCard(),
      );
    }
    
    return _buildTaskCard();
  }
}
```

### 7. Settings Screen Addition

**Purpose**: Allow users to configure week start preference

**Changes**:
- Add "Week Starts On" setting in Settings screen
- Provide dropdown/picker with days Monday-Sunday
- Save preference to UserProfile
- Invalidate relevant providers when changed

**Interface**:
```dart
class SettingsScreen extends ConsumerWidget {
  Widget _buildWeekStartSetting(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (profile) {
        return ListTile(
          title: const Text('Week Starts On'),
          subtitle: Text(_getDayName(profile.startOfWeek)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showWeekStartPicker(context, ref, profile),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading profile'),
    );
  }
  
  Future<void> _showWeekStartPicker(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Week Starts On'),
        children: List.generate(7, (index) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, index + 1),
            child: Text(days[index]),
          );
        }),
      ),
    );
    
    if (selected != null && selected != profile.startOfWeek) {
      final updatedProfile = profile.copyWith(
        startOfWeek: selected,
        updatedAt: DateTime.now(),
      );
      await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
      
      // Invalidate habit providers to recalculate with new week start
      ref.invalidate(habitsProvider);
    }
  }
}
```

## Data Models

### UserProfile Schema Update

```sql
ALTER TABLE user_profile ADD COLUMN start_of_week INTEGER DEFAULT 1;
```

### Migration Strategy

1. Add column with default value (1 = Monday)
2. Existing users automatically get Monday as week start
3. No data migration needed

## Error Handling

### Provider Lifecycle Errors

**Problem**: Async operations completing after provider disposal
**Solution**: Check `ref.mounted` before state updates
**Logging**: Log cancelled operations at INFO level

### UI State Inconsistency

**Problem**: Cards showing stale data after quick actions
**Solution**: Invalidate HabitDetailProvider after actions complete
**Fallback**: Show loading state during refresh

### Week Calculation Edge Cases

**Problem**: Week boundaries at month/year transitions
**Solution**: Use DateTime arithmetic with proper day-of-week calculations
**Testing**: Verify calculations across year boundaries

## Testing Strategy

### Unit Tests

1. **Provider Lifecycle Tests**
   - Test `ref.mounted` checks prevent state updates after disposal
   - Verify logging of cancelled operations
   - Test error handling with disposed providers

2. **Week Calculation Tests**
   - Test week start calculation for all 7 possible start days
   - Verify week boundaries at month/year transitions
   - Test progress percentage calculations

3. **Streak Calculation Tests**
   - Verify streaks update correctly after event logging
   - Test streak display in cards matches calculated values

### Integration Tests

1. **UI State Synchronization**
   - Log habit event and verify all cards update within 100ms
   - Test navigation between screens maintains consistent state
   - Verify streak values match across HabitCard and DailyItemCard

2. **Week Start Configuration**
   - Change week start preference and verify all cards recalculate
   - Test progress percentages update correctly
   - Verify weekly progress indicators align with new week start

### Widget Tests

1. **HabitCard Tests**
   - Test card displays correct streak values
   - Verify weekly progress indicators show correct days
   - Test loading and error states

2. **DailyItemCard Tests**
   - Test streak display updates in real-time
   - Verify quick action triggers provider update
   - Test card appearance for completed vs incomplete habits

## Performance Considerations

### Provider Invalidation Strategy

- Use targeted invalidation: `ref.invalidate(habitDetailProvider(habitId))` instead of global invalidation
- Debounce rapid successive actions (already implemented in HabitListItem)
- Cache week calculations within build cycle

### Database Query Optimization

- Existing indexes on habit_events table support efficient date range queries
- Week progress calculation queries limited to 7 days
- Streak data pre-calculated and stored, not computed on-demand

### UI Rendering Optimization

- Use `const` constructors where possible
- Minimize widget rebuilds by watching specific providers
- Lazy-load habit details only when cards are visible

## Migration Path

### Phase 1: Provider Lifecycle Safety
1. Add `ref.mounted` checks to HabitsProvider
2. Test with existing UI
3. Deploy and monitor for lifecycle errors

### Phase 2: UserProfile Extension
1. Add database migration for startOfWeek column
2. Update UserProfile model and repository
3. Add settings UI for week start configuration

### Phase 3: Week-Based Calculations
1. Update PeriodProgressService to accept startOfWeek parameter
2. Modify all callers to pass user preference
3. Test week calculations with various start days

### Phase 4: UI State Synchronization
1. Update HabitQuickActionButton to remove direct state management
2. Modify HabitCard to watch HabitDetailProvider
3. Update DailyItemCard to watch HabitDetailProvider
4. Add streak display to both card types

### Phase 5: Testing and Validation
1. Run comprehensive test suite
2. Manual testing of all user flows
3. Performance profiling and optimization

## Dependencies

- **Riverpod**: Provider lifecycle management
- **sqflite**: Database schema migration
- **Existing Services**: StreakCalculationService, PeriodProgressService
- **Existing Providers**: HabitDetailProvider, UserProfileProvider

## Open Questions

1. Should we show longest streak in addition to current streak on cards?
   - **Decision**: Show current streak prominently, longest streak in detail view
   
2. How should we handle timezone changes affecting week calculations?
   - **Decision**: Use device local time consistently, no timezone conversion
   
3. Should week start preference affect calendar views in habit detail screen?
   - **Decision**: Yes, all date-based UI should respect user preference
