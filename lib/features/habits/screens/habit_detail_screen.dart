import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/habit_detail_provider.dart';
import '../widgets/habit_streak_display.dart';
import '../widgets/habit_calendar_view.dart';
import '../widgets/log_habit_event_dialog.dart';
import '../models/enums/streak_type.dart';
import '../models/exceptions/habit_exception.dart';

/// Screen displaying detailed information about a single habit
/// Shows habit info, streak statistics, and recent activity
class HabitDetailScreen extends ConsumerStatefulWidget {
  final int habitId;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  StreakType _selectedStreakType = StreakType.completion;

  @override
  Widget build(BuildContext context) {
    final habitDetailAsync = ref.watch(habitDetailProvider(widget.habitId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(
          habitDetailAsync.when(
            data: (state) => state.habit.name,
            loading: () => 'Loading...',
            error: (_, __) => 'Error',
          ),
        ),
        actions: [
          habitDetailAsync.when(
            data: (state) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/habits/${widget.habitId}/edit');
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: habitDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, ref, error),
        data: (state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit header with icon and name
              _buildHabitHeader(context, state),
              const SizedBox(height: 24),

              // Streak type selector (if advanced features enabled)
              if (state.habit.timeWindowEnabled || state.habit.qualityLayerEnabled)
                _buildStreakTypeSelector(context, state),

              // Streak display
              HabitStreakDisplay(
                habitId: widget.habitId,
                compact: false,
                streakType: _selectedStreakType,
              ),
              const SizedBox(height: 24),

              // Calendar view showing last 4 weeks
              HabitCalendarView(
                habitId: widget.habitId,
                weeksToShow: 4,
              ),
              const SizedBox(height: 24),

              // Recent activity section
              _buildRecentActivitySection(context, state),
            ],
          ),
        ),
      ),
      floatingActionButton: habitDetailAsync.when(
        data: (state) => FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => LogHabitEventDialog(habit: state.habit),
            );
          },
          child: const Icon(Icons.add),
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildStreakTypeSelector(BuildContext context, HabitDetailState state) {
    final habit = state.habit;
    
    // Build list of available streak types based on enabled features
    final availableTypes = <StreakType>[StreakType.completion];
    
    if (habit.timeWindowEnabled) {
      availableTypes.add(StreakType.timeWindow);
    }
    
    if (habit.qualityLayerEnabled) {
      availableTypes.add(StreakType.quality);
    }
    
    if (habit.timeWindowEnabled && habit.qualityLayerEnabled) {
      availableTypes.add(StreakType.perfect);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<StreakType>(
          segments: availableTypes.map((type) {
            String label;
            IconData icon;
            
            switch (type) {
              case StreakType.completion:
                label = 'Basic';
                icon = Icons.check_circle;
                break;
              case StreakType.timeWindow:
                label = 'Time';
                icon = Icons.access_time;
                break;
              case StreakType.quality:
                label = 'Quality';
                icon = Icons.star;
                break;
              case StreakType.perfect:
                label = 'Perfect';
                icon = Icons.emoji_events;
                break;
            }
            
            return ButtonSegment<StreakType>(
              value: type,
              label: Text(label),
              icon: Icon(icon),
            );
          }).toList(),
          selected: {_selectedStreakType},
          onSelectionChanged: (Set<StreakType> selected) {
            if (selected.isNotEmpty) {
              setState(() {
                _selectedStreakType = selected.first;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getStreakTypeDescription(_selectedStreakType, habit),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getStreakTypeDescription(StreakType type, dynamic habit) {
    switch (type) {
      case StreakType.completion:
        return 'Days where you completed the habit goal';
      case StreakType.timeWindow:
        return 'Days where you completed within the time window';
      case StreakType.quality:
        return 'Days where you achieved the quality criteria';
      case StreakType.perfect:
        return 'Days where you met all criteria (goal + time + quality)';
    }
  }

  Widget _buildHabitHeader(BuildContext context, HabitDetailState state) {
    final habit = state.habit;
    return Center(
      child: Column(
        children: [
          // Habit icon with color
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(int.parse(habit.color)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                habit.icon,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Habit name
          Text(
            habit.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          // Habit description
          if (habit.description != null && habit.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              habit.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    HabitDetailState state,
  ) {
    final recentEvents = state.events.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (recentEvents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start logging to see your progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentEvents.map((event) => _buildEventItem(context, state.habit, event)),
      ],
    );
  }

  Widget _buildEventItem(BuildContext context, dynamic habit, dynamic event) {
    final dateTime = event.eventTimestamp as DateTime;
    final isToday = _isToday(dateTime);
    final isYesterday = _isYesterday(dateTime);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = _formatDate(dateTime);
    }

    final timeLabel = _formatTime(dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: event.completed == true
              ? Colors.green.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            event.completed == true ? Icons.check : Icons.numbers,
            color: event.completed == true
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text('$dateLabel, $timeLabel'),
        subtitle: _buildEventSubtitle(context, habit, event),
        trailing: event.completed == true
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  Widget? _buildEventSubtitle(BuildContext context, dynamic habit, dynamic event) {
    if (event.completed == true) {
      return const Text('Completed');
    } else if (event.value != null || event.valueDelta != null) {
      final value = event.valueDelta ?? event.value ?? 0.0;
      final unit = habit.unit ?? '';
      return Text('$value $unit');
    } else if (event.timeRecorded != null) {
      final time = event.timeRecorded;
      return Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    }
    return null;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Build error state with specific error messages and retry button
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    String title = 'Failed to load habit details';
    String message = 'An unexpected error occurred. Please try again.';
    IconData icon = Icons.error_outline;
    bool showBackButton = false;

    // Customize message based on error type
    if (error is HabitValidationException) {
      title = 'Validation Error';
      message = error.message;
      icon = Icons.warning_amber_outlined;
    } else if (error is HabitDatabaseException) {
      title = 'Database Error';
      message = 'There was a problem accessing the database. Please try again.';
      icon = Icons.storage_outlined;
    } else if (error is HabitNotFoundException) {
      title = 'Habit Not Found';
      message = 'This habit no longer exists or has been deleted.';
      icon = Icons.search_off_outlined;
      showBackButton = true;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (showBackButton)
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(habitDetailProvider(widget.habitId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
