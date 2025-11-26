import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/daily_item.dart';
import '../../habits/models/habit.dart';
import '../../habits/models/enums/tracking_type.dart';
import '../../habits/models/enums/streak_type.dart';
import '../../habits/widgets/habit_quick_action_button.dart';
import '../../habits/providers/habit_detail_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../../core/utils/icon_helper.dart';

class DailyItemCard extends ConsumerWidget {
  final DailyItem item;
  final VoidCallback? onActionComplete;

  const DailyItemCard({
    super.key,
    required this.item,
    this.onActionComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // For habits, watch the HabitDetailProvider for real-time data
    if (item.type == DailyItemType.habit && item.habitId != null) {
      final habitDetailAsync = ref.watch(habitDetailProvider(item.habitId!));
      
      return habitDetailAsync.when(
        data: (detailState) => _buildHabitCard(context, ref, theme, detailState.habit, detailState),
        loading: () => _buildLoadingCard(theme),
        error: (_, __) => _buildErrorCard(context, theme),
      );
    }
    
    // For tasks, use the existing item data
    return _buildTaskCard(context, ref, theme);
  }

  Widget _buildHabitCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Habit habit,
    HabitDetailState detailState,
  ) {
    // Calculate today's value from provider events
    final todayValue = _calculateTodayValue(detailState);
    
    CoreLoggingUtility.info(
      'DailyItemCard',
      '_buildHabitCard',
      'Rebuilding card for habit ${habit.name} (ID: ${habit.id}) - Today Value: $todayValue, Events count: ${detailState.events.length}',
    );
    
    // Get current streak from provider
    final currentStreak = detailState.streaks[StreakType.completion]?.currentStreak ?? 0;
    
    // Determine if habit is completed today
    final isCompletedToday = _isCompletedToday(habit, detailState);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              _buildHabitIcon(theme, habit, isCompletedToday),
              const SizedBox(width: 16),
              
              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isCompletedToday 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: isCompletedToday
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    if (item.scheduledTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(item.scheduledTime!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    // Show current streak
                    if (currentStreak > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentStreak day${currentStreak != 1 ? 's' : ''} streak',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Show today's value for value-based habits
                    if (habit.trackingType == TrackingType.value && 
                        habit.targetValue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${todayValue.toInt()}/${habit.targetValue!.toInt()} ${habit.unit ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Quick action button
              _buildHabitQuickAction(context, ref, habit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              _buildTaskIcon(theme),
              const SizedBox(width: 16),
              
              // Title and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: item.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: item.isCompleted
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    if (item.scheduledTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(item.scheduledTime!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Task checkbox
              _buildTaskCheckbox(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Failed to load habit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitIcon(ThemeData theme, Habit habit, bool isCompleted) {
    // Get icon using helper to support tree-shaking
    final iconData = IconHelper.getIcon(habit.icon);

    // Parse color from hex string
    Color iconColor;
    try {
      iconColor = Color(int.parse(habit.color.replaceFirst('#', '0xff')));
    } catch (e) {
      iconColor = theme.colorScheme.primary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildTaskIcon(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.task_alt,
        color: theme.colorScheme.secondary,
        size: 24,
      ),
    );
  }

  Widget _buildHabitQuickAction(BuildContext context, WidgetRef ref, Habit habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return HabitQuickActionButton(
      habit: habit,
      date: today,
      onActionComplete: onActionComplete,
    );
  }

  Widget _buildTaskCheckbox(WidgetRef ref) {
    return Checkbox(
      value: item.isCompleted,
      onChanged: (value) async {
        if (value != null) {
          await _toggleTask(ref);
        }
      },
    );
  }

  /// Calculate today's total value from habit events
  /// Uses valueDelta sum to match the HabitCard implementation
  double _calculateTodayValue(HabitDetailState detailState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter events for today
    final todayEvents = detailState.events.where((event) {
      final eventDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      return eventDate.isAtSameMomentAs(today);
    }).toList();
    
    if (todayEvents.isEmpty) {
      return 0.0;
    }
    
    // Sum up valueDelta for all events today (same as HabitCard)
    double totalValue = 0.0;
    for (final event in todayEvents) {
      if (event.valueDelta != null) {
        totalValue += event.valueDelta!;
      } else if (event.value != null) {
        totalValue = event.value!;
      }
    }
    
    return totalValue;
  }

  /// Check if habit is completed today
  bool _isCompletedToday(Habit habit, HabitDetailState detailState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter events for today
    final todayEvents = detailState.events.where((event) {
      final eventDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      return eventDate.isAtSameMomentAs(today);
    }).toList();
    
    if (todayEvents.isEmpty) {
      return false;
    }
    
    // For binary habits, any event means completed
    if (habit.trackingType == TrackingType.binary) {
      return true;
    }
    
    // For value habits, check if target is met using valueDelta sum
    if (habit.trackingType == TrackingType.value && habit.targetValue != null) {
      double total = 0.0;
      for (final event in todayEvents) {
        // Use valueDelta for incremental tracking, not value (which is cumulative)
        total += event.valueDelta ?? 0.0;
      }
      return total >= habit.targetValue!;
    }
    
    return false;
  }

  Future<void> _toggleTask(WidgetRef ref) async {
    if (item.taskId == null) return;

    try {
      // Get the task from the provider
      final tasksAsync = ref.read(tasksProvider);
      await tasksAsync.when(
        data: (tasks) async {
          final task = tasks.firstWhere((t) => t.id == item.taskId);
          await ref.read(tasksProvider.notifier).toggleTask(task);
          onActionComplete?.call();
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  void _navigateToDetail(BuildContext context) {
    if (item.type == DailyItemType.habit && item.habitId != null) {
      context.push('/habits/${item.habitId}');
    } else if (item.type == DailyItemType.task && item.taskId != null) {
      context.push('/tasks/${item.taskId}');
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
