import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';
import '../providers/categories_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/empty_categories_state.dart';
import '../models/exceptions/category_exception.dart';

/// Main screen displaying the list of categories
/// Handles loading, error, and empty states
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoreLoggingUtility.info('CategoriesScreen', 'build', 'Building categories screen');
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        const NumuAppBar(
          title: 'Categories',
        ),
        Expanded(
          child: Stack(
            children: [
              categoriesAsync.when(
                loading: () => Center(
                  child: Semantics(
                    label: 'Loading categories',
                    child: const CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => _buildErrorState(context, ref, error),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const EmptyCategoriesState();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final categoryId = categories[index].id!;
                      return CategoryCard(
                        category: categories[index],
                        onTap: () => context.push('/categories/$categoryId'),
                        onEdit: () => context.push('/categories/$categoryId/edit'),
                        onDelete: () => _showDeleteDialog(context, ref, categoryId, categories[index].name),
                      );
                    },
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Semantics(
                  label: 'Create new category',
                  button: true,
                  child: FloatingActionButton(
                    onPressed: () => context.push('/categories/create'),
                    tooltip: 'Create new category',
                    child: const Icon(Icons.add),
                  ),
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
    String title = 'Failed to load categories';
    String message = 'An unexpected error occurred. Please try again.';
    String detailMessage = '';
    IconData icon = Icons.error_outline;

    // Customize message based on error type
    if (error is CategoryValidationException) {
      title = 'Validation Error';
      message = error.message;
      icon = Icons.warning_amber_outlined;
    } else if (error is CategoryDatabaseException) {
      title = 'Database Error';
      message = 'There was a problem accessing the database. Please try again.';
      detailMessage = error.originalError?.toString() ?? '';
      icon = Icons.storage_outlined;
    } else if (error is CategoryNotFoundException) {
      title = 'Category Not Found';
      message = error.message;
      icon = Icons.search_off_outlined;
    } else {
      detailMessage = error.toString();
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
            if (detailMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detailMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Retry loading categories',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      CoreLoggingUtility.info(
                        'CategoriesScreen',
                        'retry',
                        'User initiated retry',
                      );
                      ref.invalidate(categoriesProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Automatically retry loading categories with backoff',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      CoreLoggingUtility.info(
                        'CategoriesScreen',
                        'retryWithBackoff',
                        'User initiated retry with backoff',
                      );
                      try {
                        await ref.read(categoriesProvider.notifier).retryOperation();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Retry failed: ${e.toString()}'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Auto Retry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "$categoryName"?\n\n'
          'This will unassign the category from all habits and tasks, but will not delete them.',
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
          'CategoriesScreen',
          'deleteCategory',
          'Deleting category: $categoryName (ID: $categoryId)',
        );
        
        await ref.read(categoriesProvider.notifier).deleteCategory(categoryId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$categoryName" deleted'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        CoreLoggingUtility.error(
          'CategoriesScreen',
          'deleteCategory',
          'Failed to delete category: $e',
        );
        
        if (context.mounted) {
          String errorMessage = 'Failed to delete category';
          
          if (e is CategoryNotFoundException) {
            errorMessage = 'Category not found. It may have already been deleted.';
          } else if (e is CategoryDatabaseException) {
            errorMessage = 'Database error. Please try again.';
          } else {
            errorMessage = 'Failed to delete category: ${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  _showDeleteDialog(context, ref, categoryId, categoryName);
                },
              ),
            ),
          );
        }
      }
    }
  }
}
