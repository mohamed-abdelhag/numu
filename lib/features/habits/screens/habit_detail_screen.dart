import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/habit_detail_provider.dart';
import '../widgets/habit_streak_display.dart';

/// Screen displaying detailed information about a single habit
/// Shows habit info, streak statistics, and recent activity
class HabitDetailScreen extends ConsumerWidget {
  final int habitId;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitDetailAsync = ref.watch(habitDetailProvider(habitId));

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
                context.push('/habits/$habitId/edit');
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: habitDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load habit details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(habitDetailProvider(habitId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit header with icon and name
              _buildHabitHeader(context, state),
              const SizedBox(height: 24),

              // Streak display
              HabitStreakDisplay(
                habitId: habitId,
                compact: false,
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
            // TODO: Open log event dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Log event dialog coming in next phase'),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
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
}
