import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/tutorial_cards_provider.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Tutorial detail screen showing full tutorial content with error handling
class TutorialDetailScreen extends ConsumerWidget {
  final String tutorialId;

  const TutorialDetailScreen({
    super.key,
    required this.tutorialId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorialAsync = ref.watch(tutorialCardByIdProvider(tutorialId));

    return Scaffold(
      appBar: AppBar(
        title: tutorialAsync.when(
          data: (tutorial) => Text(tutorial?.title ?? 'Tutorial'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Tutorial'),
        ),
      ),
      body: tutorialAsync.when(
        data: (tutorial) {
          if (tutorial == null) {
            return _buildNotFoundState(context, ref);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tutorial header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _getIconData(tutorial.iconName),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutorial.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tutorial.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // Tutorial content
                MarkdownBody(
                  data: tutorial.content,
                  styleSheet: MarkdownStyleSheet(
                    h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    p: Theme.of(context).textTheme.bodyLarge,
                    listBullet: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading tutorial...'),
            ],
          ),
        ),
        error: (error, stack) {
          CoreLoggingUtility.error(
            'TutorialDetailScreen',
            'build',
            'Error loading tutorial $tutorialId: $error\n$stack',
          );
          
          return _buildErrorState(context, ref, error);
        },
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Tutorial Not Found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested tutorial could not be found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Help'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    // Determine user-friendly error message
    String errorMessage = 'Unable to Load Tutorial';
    String errorDetails = 'Please try again';
    
    if (error.toString().contains('database')) {
      errorMessage = 'Database Error';
      errorDetails = 'There was a problem accessing the tutorial';
    } else if (error.toString().contains('Failed to fetch')) {
      errorMessage = 'Loading Failed';
      errorDetails = 'Could not retrieve tutorial content';
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
                      'TutorialDetailScreen',
                      'retry',
                      'User requested retry for loading tutorial $tutorialId',
                    );
                    ref.invalidate(tutorialCardByIdProvider(tutorialId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
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
