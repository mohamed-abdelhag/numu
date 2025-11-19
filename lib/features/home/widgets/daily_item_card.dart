import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/daily_item.dart';
import '../../habits/models/habit.dart';
import '../../habits/widgets/habit_quick_action_button.dart';
import '../../habits/repositories/habit_repository.dart';
import '../../tasks/tasks_provider.dart';

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
              _buildIcon(theme),
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
                    if (item.type == DailyItemType.habit && 
                        item.currentValue != null && 
                        item.targetValue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${item.currentValue!.toInt()}/${item.targetValue!.toInt()} ${item.unit ?? ''}',
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
              _buildQuickAction(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    if (item.type == DailyItemType.habit && item.icon != null) {
      // Parse icon from string (e.g., "0xe047" or "fitness_center")
      IconData iconData;
      try {
        if (item.icon!.startsWith('0x')) {
          iconData = IconData(
            int.parse(item.icon!),
            fontFamily: 'MaterialIcons',
          );
        } else {
          // Default icon if parsing fails
          iconData = Icons.check_circle_outline;
        }
      } catch (e) {
        iconData = Icons.check_circle_outline;
      }

      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: item.color?.withValues(alpha: 0.1) ?? theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          iconData,
          color: item.color ?? theme.colorScheme.primary,
          size: 24,
        ),
      );
    } else {
      // Task icon
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
  }

  Widget _buildQuickAction(BuildContext context, WidgetRef ref) {
    if (item.type == DailyItemType.habit && item.habitId != null) {
      // Use habit quick action button
      return FutureBuilder<Habit?>(
        future: HabitRepository().getHabitById(item.habitId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(width: 48);
          }

          final habit = snapshot.data!;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          return HabitQuickActionButton(
            habit: habit,
            date: today,
            onActionComplete: onActionComplete,
          );
        },
      );
    } else if (item.type == DailyItemType.task && item.taskId != null) {
      // Task checkbox
      return Checkbox(
        value: item.isCompleted,
        onChanged: (value) async {
          if (value != null) {
            await _toggleTask(ref);
          }
        },
      );
    }

    return const SizedBox(width: 48);
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
      context.push('/habits/detail/${item.habitId}');
    } else if (item.type == DailyItemType.task && item.taskId != null) {
      context.push('/tasks/detail/${item.taskId}');
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
