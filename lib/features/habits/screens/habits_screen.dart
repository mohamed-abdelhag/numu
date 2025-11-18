import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import '../providers/habits_provider.dart';
import '../widgets/empty_habits_state.dart';
import '../widgets/habit_list_item.dart';
import '../models/exceptions/habit_exception.dart';

/// Main screen displaying the list of active habits
/// Handles loading, error, and empty states
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoreLoggingUtility.info('HabitsScreen', 'build', 'Building habits screen');
    final habitsAsync = ref.watch(habitsProvider);

    return Column(
      children: [
        const NumuAppBar(
          title: 'Habits',
        ),
        Expanded(
          child: Stack(
            children: [
              habitsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => _buildErrorState(context, ref, error),
                data: (habits) {
                  if (habits.isEmpty) {
                    return const EmptyHabitsState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      return HabitListItem(habit: habits[index]);
                    },
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => context.push('/habits/add'),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build error state with specific error messages and retry button
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    String title = 'Failed to load habits';
    String message = 'An unexpected error occurred. Please try again.';
    IconData icon = Icons.error_outline;

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
      message = error.message;
      icon = Icons.search_off_outlined;
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
            ElevatedButton.icon(
              onPressed: () => ref.refresh(habitsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
