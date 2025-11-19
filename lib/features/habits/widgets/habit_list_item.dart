import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../models/enums/frequency.dart';
import '../providers/categories_provider.dart';
import 'habit_quick_log_button.dart';
import 'habit_streak_display.dart';
import 'habit_progress_indicator.dart';

/// Widget displaying a single habit in the list
/// Shows habit icon, name, and basic information
/// Tapping navigates to the habit detail screen
class HabitListItem extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitListItem({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitListItem> createState() => _HabitListItemState();
}

class _HabitListItemState extends ConsumerState<HabitListItem> {
  DateTime? _lastClickTime;

  void _handleTap(BuildContext context) {
    final now = DateTime.now();
    
    // Implement 500ms debounce logic
    if (_lastClickTime != null && 
        now.difference(_lastClickTime!).inMilliseconds < 500) {
      // Ignore rapid successive clicks
      return;
    }
    
    // Update last click time
    _lastClickTime = now;
    
    // Navigate to habit detail screen
    context.push('/habits/${widget.habit.id}');
  }

  @override
  Widget build(BuildContext context) {
    // Get category if habit has one
    final categoriesAsync = ref.watch(categoriesProvider);
    final category = widget.habit.categoryId != null
        ? categoriesAsync.whenOrNull(
            data: (categories) => categories.firstWhere(
              (c) => c.id == widget.habit.categoryId,
              orElse: () => categories.first,
            ),
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon with color
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(widget.habit.color.replaceFirst('0x', ''), radix: 16)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.habit.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.habit.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16))
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (category.icon != null) ...[
                                  Text(
                                    category.icon!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.habit.description != null && widget.habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Show progress indicator for weekly/monthly habits
                    // Show streak display for daily habits
                    if (widget.habit.id != null)
                      widget.habit.frequency == Frequency.daily
                          ? HabitStreakDisplay(
                              habitId: widget.habit.id!,
                              compact: true,
                            )
                          : HabitProgressIndicator(
                              habitId: widget.habit.id!,
                            ),
                  ],
                ),
              ),

              // Quick log button
              HabitQuickLogButton(habit: widget.habit),
            ],
          ),
        ),
      ),
    );
  }
}
