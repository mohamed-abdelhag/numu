import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/tasks/tasks_provider.dart';
import 'package:numu/features/habits/models/category.dart';
import 'package:numu/features/habits/providers/categories_provider.dart';

/// Screen for displaying complete task details
/// 
/// Features:
/// - Display task title prominently at top
/// - Show full description without truncation
/// - Display due date with day of week and formatted date
/// - Show category with color and icon
/// - Add completion toggle checkbox
/// - Include Edit and Delete action buttons
/// - Navigate to EditTaskScreen
/// - Handle Delete with confirmation dialog
class TaskDetailScreen extends ConsumerStatefulWidget {
  final int taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: Semantics(
          label: 'Go back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Back',
          ),
        ),
        actions: [
          // Edit button
          Semantics(
            label: 'Edit task',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _isDeleting ? null : () => _handleEdit(context),
              tooltip: 'Edit',
            ),
          ),
          // Delete button
          Semantics(
            label: 'Delete task',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _handleDelete,
              tooltip: 'Delete',
            ),
          ),
        ],
      ),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            // Task not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task not found'),
                    backgroundColor: Colors.red,
                  ),
                );
                context.pop();
              }
            });
            return const Center(
              child: Text('Task not found'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task title with completion checkbox
                _buildTitleSection(task, theme),
                
                const Divider(height: 1),
                
                // Description section
                _buildDescriptionSection(task, theme),
                
                const Divider(height: 1),
                
                // Due date section
                _buildDueDateSection(task, theme),
                
                const Divider(height: 1),
                
                // Category section
                _buildCategorySection(task, theme),
                
                const Divider(height: 1),
                
                // Metadata section
                _buildMetadataSection(task, theme),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading task',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build title section with completion checkbox
  Widget _buildTitleSection(Task task, ThemeData theme) {
    return Semantics(
      label: 'Task title: ${task.title}. ${task.isCompleted ? "Completed" : "Not completed"}',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion checkbox
            Semantics(
              label: task.isCompleted ? 'Mark as incomplete' : 'Mark as complete',
              button: true,
              child: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _handleToggleCompletion(task),
              ),
            ),
            const SizedBox(width: 8),
            // Task title
            Expanded(
              child: Text(
                task.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: task.isCompleted
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build description section
  Widget _buildDescriptionSection(Task task, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: task.description != null && task.description!.isNotEmpty
                ? 'Description: ${task.description}'
                : 'No description provided',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.description != null && task.description!.isNotEmpty
                    ? task.description!
                    : 'No description',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: task.description != null && task.description!.isNotEmpty
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: task.description == null || task.description!.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build due date section
  Widget _buildDueDateSection(Task task, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due Date',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildDueDateDisplay(task, theme),
        ],
      ),
    );
  }

  /// Build due date display with formatting and status
  Widget _buildDueDateDisplay(Task task, ThemeData theme) {
    if (task.dueDate == null) {
      return Semantics(
        label: 'No due date set',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'No due date',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Format due date with day of week
    final dueDate = task.dueDate!;
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    
    final dayOfWeek = weekdays[dueDate.weekday - 1];
    final month = months[dueDate.month - 1];
    final day = dueDate.day;
    final year = dueDate.year;
    
    final formattedDate = '$dayOfWeek, $month $day, $year';
    
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (task.isCompleted) {
      statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
      statusIcon = Icons.check_circle_outline;
      statusText = 'Completed';
    } else if (task.isOverdue) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.warning_amber_rounded;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysOverdue = today.difference(due).inDays;
      statusText = daysOverdue == 1 ? 'Overdue by 1 day' : 'Overdue by $daysOverdue days';
    } else if (task.isDueToday) {
      statusColor = Colors.orange;
      statusIcon = Icons.today;
      statusText = 'Due today';
    } else if (task.isDueSoon) {
      statusColor = Colors.amber.shade700;
      statusIcon = Icons.event;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysUntil = due.difference(today).inDays;
      statusText = daysUntil == 1 ? 'Due in 1 day' : 'Due in $daysUntil days';
    } else {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.event;
      statusText = 'Upcoming';
    }

    return Semantics(
      label: 'Due date: $formattedDate. Status: $statusText',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formatted date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status indicator
            Row(
              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build category section
  Widget _buildCategorySection(Task task, ThemeData theme) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              if (task.categoryId == null) {
                return Semantics(
                  label: 'No category assigned',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No category',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final category = categories.firstWhere(
                (c) => c.id == task.categoryId,
                orElse: () => Category(
                  name: 'Unknown',
                  color: '#808080',
                  createdAt: DateTime.now(),
                ),
              );

              return _buildCategoryCard(category, theme);
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stack) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Error loading category',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build category card with navigation
  Widget _buildCategoryCard(Category category, ThemeData theme) {
    final categoryColor = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );

    return Semantics(
      label: 'Category: ${category.name}. Tap to view category details',
      button: true,
      child: InkWell(
        onTap: () => _handleCategoryTap(category),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Category icon
              if (category.icon != null)
                Text(
                  category.icon!,
                  style: const TextStyle(fontSize: 20),
                )
              else
                Icon(
                  Icons.label,
                  size: 20,
                  color: categoryColor,
                ),
              const SizedBox(width: 12),
              // Category name
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Navigation arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: categoryColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build metadata section
  Widget _buildMetadataSection(Task task, ThemeData theme) {
    final createdDate = _formatMetadataDate(task.createdAt);
    final updatedDate = _formatMetadataDate(task.updatedAt);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Created: $createdDate',
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Created: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  createdDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: 'Updated: $updatedDate',
            child: Row(
              children: [
                Icon(
                  Icons.update,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Updated: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  updatedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format metadata date
  String _formatMetadataDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    return '$month $day, $year';
  }

  /// Handle completion toggle
  Future<void> _handleToggleCompletion(Task task) async {
    try {
      await ref.read(tasksProvider.notifier).toggleTask(task);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text(
                task.isCompleted
                    ? 'Task marked as incomplete'
                    : 'Task marked as complete',
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text('Error updating task: $error'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle edit button - navigate to EditTaskScreen
  void _handleEdit(BuildContext context) {
    context.pushNamed(
      'edit-task',
      pathParameters: {'id': widget.taskId.toString()},
    );
  }

  /// Handle delete button - show confirmation and delete task
  Future<void> _handleDelete() async {
    final taskAsync = ref.read(taskDetailProvider(widget.taskId));
    final task = taskAsync.value;
    
    if (task == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Semantics(
          label: 'Are you sure you want to delete ${task.title}? This action cannot be undone.',
          child: Text(
            'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          ),
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
            label: 'Confirm deletion',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Set deleting state
    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete task using provider
      await ref.read(tasksProvider.notifier).deleteTask(task.id!);

      // Show success message with semantic announcement and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: const Text('Task deleted successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        context.pop();
      }
    } catch (error) {
      // Show error message with semantic announcement
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text('Error deleting task: $error'),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleDelete,
            ),
          ),
        );
      }
    }
  }

  /// Handle category tap - navigate to category detail screen
  void _handleCategoryTap(Category category) {
    if (category.id != null) {
      context.pushNamed(
        'category-detail',
        pathParameters: {'id': category.id.toString()},
      );
    }
  }
}
