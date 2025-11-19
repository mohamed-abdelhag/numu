import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import '../providers/habit_detail_provider.dart';
import '../widgets/habit_streak_display.dart';
import '../widgets/habit_calendar_view.dart';
import '../widgets/log_habit_event_dialog.dart';
import '../models/enums/streak_type.dart';
import '../models/exceptions/habit_exception.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import '../../reminders/providers/reminder_provider.dart';

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
    CoreLoggingUtility.info('HabitDetailScreen', 'build', 'Building habit detail screen for habit ID: ${widget.habitId}');
    final habitDetailAsync = ref.watch(habitDetailProvider(widget.habitId));

    return Column(
      children: [
        NumuAppBar(
          title: habitDetailAsync.when(
            data: (state) => state.habit.name,
            loading: () => 'Loading...',
            error: (_, __) => 'Error',
          ),
          showDrawerButton: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              CoreLoggingUtility.info('HabitDetailScreen', 'back', 'User navigating back from habit detail');
              context.pop();
            },
          ),
          actions: [
            habitDetailAsync.when(
              data: (state) => IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  CoreLoggingUtility.info('HabitDetailScreen', 'edit', 'User tapped edit for habit ID: ${widget.habitId}');
                  context.go('/habits/${widget.habitId}/edit');
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              habitDetailAsync.when(
                loading: () {
                  CoreLoggingUtility.info('HabitDetailScreen', 'loading', 'Loading habit details');
                  return const Center(child: CircularProgressIndicator());
                },
                error: (error, stack) {
                  CoreLoggingUtility.error('HabitDetailScreen', 'error', 'Error loading habit details: $error');
                  return _buildErrorState(context, ref, error);
                },
                data: (state) {
                  CoreLoggingUtility.info('HabitDetailScreen', 'data', 'Habit details loaded successfully');
                  return SingleChildScrollView(
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

                        // Statistics section
                        _buildStatisticsSection(context, state),
                        const SizedBox(height: 24),

                        // Calendar view showing last 4 weeks
                        HabitCalendarView(
                          habitId: widget.habitId,
                          weeksToShow: 4,
                        ),
                        const SizedBox(height: 24),

                        // Recent activity section
                        _buildRecentActivitySection(context, state),
                        const SizedBox(height: 24),

                        // Reminders section
                        _buildRemindersSection(context, state),
                        const SizedBox(height: 80), // Space for FAB
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: habitDetailAsync.when(
                  data: (state) => FloatingActionButton(
                    onPressed: () {
                      CoreLoggingUtility.info('HabitDetailScreen', 'logEvent', 'User tapped to log habit event');
                      showDialog(
                        context: context,
                        builder: (context) => LogHabitEventDialog(habit: state.habit),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildStatisticsSection(BuildContext context, HabitDetailState state) {
    final habit = state.habit;
    final stats = state.statistics;
    final unit = habit.unit ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        // Main statistics grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatisticCard(
              context,
              'Total',
              '${stats.totalValue.toStringAsFixed(stats.totalValue % 1 == 0 ? 0 : 1)} $unit',
              Icons.analytics_outlined,
            ),
            _buildStatisticCard(
              context,
              'This Week',
              '${stats.weeklyValue.toStringAsFixed(stats.weeklyValue % 1 == 0 ? 0 : 1)} $unit',
              Icons.calendar_view_week_outlined,
            ),
            _buildStatisticCard(
              context,
              'This Month',
              '${stats.monthlyValue.toStringAsFixed(stats.monthlyValue % 1 == 0 ? 0 : 1)} $unit',
              Icons.calendar_month_outlined,
            ),
            _buildStatisticCard(
              context,
              'Average/Day',
              '${stats.averagePerDay.toStringAsFixed(1)} $unit',
              Icons.trending_up_outlined,
            ),
          ],
        ),
        
        // Quality statistics (only if quality tracking is enabled)
        if (habit.qualityLayerEnabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatisticCard(
                  context,
                  'Quality Days',
                  '${stats.qualityDays}',
                  Icons.star_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatisticCard(
                  context,
                  'Quality Rate',
                  '${stats.qualityPercentage.toStringAsFixed(1)}%',
                  Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatisticCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

  Widget _buildRemindersSection(BuildContext context, HabitDetailState state) {
    final remindersAsync = ref.watch(habitRemindersProvider(widget.habitId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reminders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                CoreLoggingUtility.info(
                  'HabitDetailScreen',
                  'addReminder',
                  'User tapped to add reminder for habit ID: ${widget.habitId}',
                );
                context.push(
                  '/reminders/create',
                  extra: {'habitId': widget.habitId, 'habitName': state.habit.name},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        remindersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Failed to load reminders',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          data: (reminders) {
            if (reminders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reminders set',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a reminder to stay on track',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: reminders.map((reminder) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: Icon(
                      reminder.type.toString().contains('notification')
                          ? Icons.notifications
                          : Icons.alarm,
                      color: reminder.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(reminder.title),
                    subtitle: reminder.nextTriggerTime != null
                        ? Text(
                            'Next: ${_formatReminderTime(reminder.nextTriggerTime!)}',
                          )
                        : const Text('Not scheduled'),
                    trailing: Switch(
                      value: reminder.isActive,
                      onChanged: (value) async {
                        CoreLoggingUtility.info(
                          'HabitDetailScreen',
                          'toggleReminder',
                          'Toggling reminder ${reminder.id} to $value',
                        );
                        await ref
                            .read(reminderProvider.notifier)
                            .toggleReminderActive(reminder.id!);
                        // Refresh the reminders list
                        ref.invalidate(habitRemindersProvider(widget.habitId));
                      },
                    ),
                    onTap: () {
                      CoreLoggingUtility.info(
                        'HabitDetailScreen',
                        'editReminder',
                        'User tapped to edit reminder ${reminder.id}',
                      );
                      context.push('/reminders/edit/${reminder.id}', extra: reminder);
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatReminderTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final difference = reminderDate.difference(today).inDays;
    
    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Tomorrow';
    } else if (difference < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dateStr = weekdays[dateTime.weekday - 1];
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    
    return '$dateStr at $timeStr';
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
