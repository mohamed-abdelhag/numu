import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import 'providers/daily_items_provider.dart';
import 'widgets/daily_progress_header.dart';
import 'widgets/daily_item_card.dart';
import '../profile/providers/user_profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoreLoggingUtility.info('HomeScreen', 'build', 'Building home screen');
    
    final dailyItemsAsync = ref.watch(dailyItemsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Column(
      children: [
        NumuAppBar(
          title: 'Home',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.go('/settings');
              },
            ),
          ],
        ),
        Expanded(
          child: dailyItemsAsync.when(
            data: (dailyState) {
              return userProfileAsync.when(
                data: (profile) {
                  final userName = profile?.name ?? 'there';
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(dailyItemsProvider);
                    },
                    child: dailyState.items.isEmpty
                        ? _buildEmptyState(context)
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              DailyProgressHeader(
                                userName: userName,
                                habitCount: dailyState.habitCount,
                                taskCount: dailyState.taskCount,
                                completionPercentage: dailyState.completionPercentage,
                              ),
                              const SizedBox(height: 16),
                              ...dailyState.items.map((item) => DailyItemCard(
                                item: item,
                                onActionComplete: () {
                                  // Refresh the daily items when an action is completed
                                  ref.invalidate(dailyItemsProvider);
                                },
                              )),
                            ],
                          ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) {
                  CoreLoggingUtility.error(
                    'HomeScreen',
                    'build',
                    'Error loading user profile: $error',
                  );
                  // Use default name if profile fails to load
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(dailyItemsProvider);
                    },
                    child: dailyState.items.isEmpty
                        ? _buildEmptyState(context)
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              DailyProgressHeader(
                                userName: 'there',
                                habitCount: dailyState.habitCount,
                                taskCount: dailyState.taskCount,
                                completionPercentage: dailyState.completionPercentage,
                              ),
                              const SizedBox(height: 16),
                              ...dailyState.items.map((item) => DailyItemCard(
                                item: item,
                                onActionComplete: () {
                                  ref.invalidate(dailyItemsProvider);
                                },
                              )),
                            ],
                          ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              CoreLoggingUtility.error(
                'HomeScreen',
                'build',
                'Error loading daily items: $error\n$stack',
              );
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load daily items',
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
                        ref.invalidate(dailyItemsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 24),
        Text(
          'No items due today',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You have no habits or tasks scheduled for today.\nEnjoy your free time!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
