import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_detail_provider.dart';
import 'habit_card.dart';

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
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(16),
      child: HabitCard(
        habit: widget.habit,
        onQuickActionComplete: () {
          // Refresh habit detail when quick action completes
          ref.invalidate(habitDetailProvider(widget.habit.id!));
        },
      ),
    );
  }
}
