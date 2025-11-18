import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import '../models/exceptions/category_exception.dart';
import '../providers/category_detail_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/habit_list_item.dart';

/// Screen displaying detailed information about a single category
/// Shows category info, associated habits, and associated tasks
class CategoryDetailScreen extends ConsumerWidget {
  final int categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoreLoggingUtility.info(
      'CategoryDetailScreen',
      'build',
      'Building category detail screen for category ID: $categoryId',
    );
    final categoryDetailAsync = ref.watch(categoryDetailProvider(categoryId));

    return Column(
      children: [
        NumuAppBar(
          title: categoryDetailAsync.when(
            data: (state) => state.category.name,
            loading: () => 'Loading...',
            error: (_, __) => 'Error',
          ),
          showDrawerButton: false,
          leading: Semantics(
            label: 'Go back to categories list',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Go back',
              onPressed: () {
                CoreLoggingUtility.info(
                  'CategoryDetailScreen',
                  'back',
                  'User navigating back from category detail',
                );
                context.pop();
              },
            ),
          ),
          actions: [
            categoryDetailAsync.when(
              data: (state) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pin/Unpin button
                  Semantics(
                    label: state.category.isPinnedToSidebar
                        ? 'Unpin ${state.category.name} from sidebar'
                        : 'Pin ${state.category.name} to sidebar',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        state.category.isPinnedToSidebar
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                      ),
                      tooltip: state.category.isPinnedToSidebar
                          ? 'Unpin from sidebar'
                          : 'Pin to sidebar',
                      onPressed: () => _togglePin(context, ref, state.category.id!),
                    ),
                  ),
                  // Edit button
                  Semantics(
                    label: 'Edit ${state.category.name} category',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit category',
                      onPressed: () {
                        CoreLoggingUtility.info(
                          'CategoryDetailScreen',
                          'edit',
                          'User tapped edit for category ID: $categoryId',
                        );
                        context.push('/categories/$categoryId/edit');
                      },
                    ),
                  ),
                  // Delete button
                  if (!state.category.isSystem)
                    Semantics(
                      label: 'Delete ${state.category.name} category',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete category',
                        onPressed: () => _showDeleteDialog(
                          context,
                          ref,
                          state.category.id!,
                          state.category.name,
                          state.habits.length,
                          state.tasks.length,
                        ),
                      ),
                    ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        Expanded(
          child: categoryDetailAsync.when(
            loading: () {
              CoreLoggingUtility.info(
                'CategoryDetailScreen',
                'loading',
                'Loading category details',
              );
              return Center(
                child: Semantics(
                  label: 'Loading category details',
                  child: const CircularProgressIndicator(),
                ),
              );
            },
            error: (error, stack) {
              CoreLoggingUtility.error(
                'CategoryDetailScreen',
                'error',
                'Error loading category details: $error',
              );
              return _buildErrorState(context, ref, error);
            },
            data: (state) {
              CoreLoggingUtility.info(
                'CategoryDetailScreen',
                'data',
                'Category details loaded successfully (${state.habits.length} habits, ${state.tasks.length} tasks)',
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category header
                    _buildCategoryHeader(context, state),
                    const SizedBox(height: 32),

                    // Habits section
                    _buildHabitsSection(context, state),
                    const SizedBox(height: 24),

                    // Tasks section
                    _buildTasksSection(context, state),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(BuildContext context, CategoryDetailState state) {
    final category = state.category;
    final color = Color(int.parse(category.color));

    return Center(
      child: Column(
        children: [
          // Category icon with color
          Semantics(
            label: 'Category icon: ${category.icon ?? 'folder'}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  category.icon ?? '📁',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category name
          Text(
            category.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          // Category description
          if (category.description != null && category.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              category.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Stats chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(
                context,
                Icons.track_changes,
                state.habits.length,
                'Habits',
                color,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                context,
                Icons.check_circle_outline,
                state.tasks.length,
                'Tasks',
                color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    int count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSection(BuildContext context, CategoryDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.track_changes,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Habits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.habits.length.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.habits.isEmpty)
          _buildEmptyState(
            context,
            Icons.track_changes,
            'No habits yet',
            'Habits assigned to this category will appear here',
          )
        else
          ...state.habits.map((habit) => HabitListItem(habit: habit)),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context, CategoryDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 24,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.tasks.length.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.tasks.isEmpty)
          _buildEmptyState(
            context,
            Icons.check_circle_outline,
            'No tasks yet',
            'Tasks assigned to this category will appear here',
          )
        else
          ...state.tasks.map((task) => _buildTaskItem(context, task)),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, dynamic task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: null, // Read-only in category detail view
        ),
        title: Text(
          task.text,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: Icon(
          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: task.isCompleted ? Colors.green : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    String title = 'Failed to load category details';
    String message = 'An unexpected error occurred. Please try again.';
    IconData icon = Icons.error_outline;
    bool showBackButton = false;

    // Customize message based on error type
    if (error is CategoryValidationException) {
      title = 'Validation Error';
      message = error.message;
      icon = Icons.warning_amber_outlined;
    } else if (error is CategoryDatabaseException) {
      title = 'Database Error';
      message = 'There was a problem accessing the database. Please try again.';
      icon = Icons.storage_outlined;
    } else if (error is CategoryNotFoundException) {
      title = 'Category Not Found';
      message = 'This category no longer exists or has been deleted.';
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
              Semantics(
                label: 'Go back to categories list',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              )
            else
              Semantics(
                label: 'Retry loading category details',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(categoryDetailProvider(categoryId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) async {
    try {
      CoreLoggingUtility.info(
        'CategoryDetailScreen',
        'togglePin',
        'Toggling sidebar pin for category ID: $categoryId',
      );
      
      await ref.read(categoriesProvider.notifier).toggleSidebarPin(categoryId);
      
      // Refresh the category detail to show updated pin status
      ref.invalidate(categoryDetailProvider(categoryId));
      
      if (context.mounted) {
        final categoryDetailAsync = ref.read(categoryDetailProvider(categoryId));
        final isPinned = categoryDetailAsync.value?.category.isPinnedToSidebar ?? false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPinned
                  ? 'Category pinned to sidebar'
                  : 'Category unpinned from sidebar',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'CategoryDetailScreen',
        'togglePin',
        'Failed to toggle pin: $e\n$stackTrace',
      );
      
      if (context.mounted) {
        String errorMessage = 'Failed to update pin status';
        
        if (e is CategoryNotFoundException) {
          errorMessage = 'Category not found. It may have been deleted.';
        } else if (e is CategoryDatabaseException) {
          errorMessage = 'Database error. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _togglePin(context, ref, categoryId),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
    String categoryName,
    int habitCount,
    int taskCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$categoryName"?'),
            const SizedBox(height: 16),
            if (habitCount > 0 || taskCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warning',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This category is assigned to:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (habitCount > 0)
                      Text(
                        '• $habitCount habit${habitCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    if (taskCount > 0)
                      Text(
                        '• $taskCount task${taskCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'They will not be deleted, but will lose their category assignment.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          Semantics(
            label: 'Cancel deletion',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            label: 'Confirm delete category $categoryName',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        CoreLoggingUtility.info(
          'CategoryDetailScreen',
          'deleteCategory',
          'Deleting category ID: $categoryId',
        );
        
        await ref.read(categoriesProvider.notifier).deleteCategory(categoryId);
        
        if (context.mounted) {
          // Navigate back to categories list
          context.go('/categories');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$categoryName" deleted'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'CategoryDetailScreen',
          'deleteCategory',
          'Failed to delete category: $e\n$stackTrace',
        );
        
        if (context.mounted) {
          String errorMessage = 'Failed to delete category';
          bool canRetry = true;
          
          if (e is CategoryNotFoundException) {
            errorMessage = 'Category not found. It may have already been deleted.';
            canRetry = false;
            // Navigate back since category doesn't exist
            context.go('/categories');
          } else if (e is CategoryDatabaseException) {
            errorMessage = 'Database error. Please try again.';
          } else {
            errorMessage = 'Failed to delete category: ${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
              action: canRetry
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _showDeleteDialog(
                        context,
                        ref,
                        categoryId,
                        categoryName,
                        habitCount,
                        taskCount,
                      ),
                    )
                  : null,
            ),
          );
        }
      }
    }
  }
}
