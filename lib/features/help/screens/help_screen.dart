import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tutorial_cards_provider.dart';
import '../../../core/widgets/shell/numu_app_bar.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Help screen displaying tutorial cards with error handling and retry functionality
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorialsAsync = ref.watch(allTutorialCardsProvider);

    return Column(
      children: [
        const NumuAppBar(
          title: 'Help',
        ),
        Expanded(
          child: tutorialsAsync.when(
            data: (tutorials) {
              if (tutorials.isEmpty) {
                return _buildEmptyState(context, ref);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: tutorials.length,
                itemBuilder: (context, index) {
                  final tutorial = tutorials[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _getIconData(tutorial.iconName),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        tutorial.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        tutorial.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        CoreLoggingUtility.info(
                          'HelpScreen',
                          'onTap',
                          'Navigating to tutorial: ${tutorial.id}',
                        );
                        context.push('/help/${tutorial.id}');
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading help articles...'),
                ],
              ),
            ),
            error: (error, stack) {
              CoreLoggingUtility.error(
                'HelpScreen',
                'build',
                'Error loading tutorials: $error\n$stack',
              );
              
              return _buildErrorState(context, ref, error);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Help Articles Available',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Help articles will appear here once they are loaded',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(allTutorialCardsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    // Determine user-friendly error message
    String errorMessage = 'Unable to load help articles';
    String errorDetails = 'Please try again';
    
    if (error.toString().contains('database')) {
      errorMessage = 'Database Error';
      errorDetails = 'There was a problem accessing the help database';
    } else if (error.toString().contains('Failed to fetch')) {
      errorMessage = 'Loading Failed';
      errorDetails = 'Could not retrieve help articles';
    } else if (error.toString().contains('initialize')) {
      errorMessage = 'Initialization Error';
      errorDetails = 'Failed to set up help articles';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorDetails,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    CoreLoggingUtility.info(
                      'HelpScreen',
                      'retry',
                      'User requested retry for loading tutorials',
                    );
                    ref.invalidate(allTutorialCardsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    CoreLoggingUtility.info(
                      'HelpScreen',
                      'reinitialize',
                      'User requested reinitialization of tutorials',
                    );
                    // Try to reinitialize default tutorials
                    try {
                      final repository = ref.read(tutorialCardsRepositoryProvider);
                      await repository.initializeDefaultTutorials();
                      ref.invalidate(allTutorialCardsProvider);
                    } catch (e) {
                      CoreLoggingUtility.error(
                        'HelpScreen',
                        'reinitialize',
                        'Failed to reinitialize tutorials: $e',
                      );
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'info':
        return Icons.info_outline;
      case 'favorite':
        return Icons.favorite_outline;
      case 'add_circle':
        return Icons.add_circle_outline;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'help':
        return Icons.help_outline;
      default:
        return Icons.article_outlined;
    }
  }
}
