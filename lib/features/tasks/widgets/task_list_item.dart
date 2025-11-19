import 'package:flutter/material.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/habits/models/category.dart';
import 'package:numu/features/tasks/widgets/due_date_badge.dart';

/// A reusable widget for displaying a task in a list view
/// 
/// Displays:
/// - Completion checkbox
/// - Task title (with strikethrough if completed)
/// - Truncated description (max 2 lines)
/// - Due date badge with color coding
/// - Category badge if assigned
/// 
/// Handles tap to navigate to detail screen
class TaskListItem extends StatelessWidget {
  final Task task;
  final Category? category;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleComplete;

  const TaskListItem({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue;

    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion checkbox
              Semantics(
                label: isCompleted 
                    ? 'Mark task as incomplete: ${task.title}'
                    : 'Mark task as complete: ${task.title}',
                button: true,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: onToggleComplete,
                ),
              ),
              const SizedBox(width: 12),
              
              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted 
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : isOverdue 
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Description (if present)
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Due date and category badges
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Due date badge
                        DueDateBadge(
                          dueDate: task.dueDate,
                          isCompleted: isCompleted,
                          isOverdue: isOverdue,
                          isDueToday: task.isDueToday,
                          isDueSoon: task.isDueSoon,
                        ),
                        
                        // Category badge
                        if (category != null) _buildCategoryBadge(context, category!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build category badge with icon and color
  Widget _buildCategoryBadge(BuildContext context, Category category) {
    final theme = Theme.of(context);
    final categoryColor = _parseCategoryColor(category.color);

    return Semantics(
      label: 'Category: ${category.name}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.5),
            width: 1,
          ),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parse category color string to Color object
  Color _parseCategoryColor(String colorString) {
    try {
      // Handle both formats: "0xFFRRGGBB" and "#RRGGBB"
      if (colorString.startsWith('#')) {
        colorString = '0xFF${colorString.substring(1)}';
      } else if (!colorString.startsWith('0x')) {
        colorString = '0xFF$colorString';
      }
      return Color(int.parse(colorString.replaceFirst('0x', ''), radix: 16));
    } catch (e) {
      // Fallback to grey if parsing fails
      return const Color(0xFF808080);
    }
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel() {
    final buffer = StringBuffer();
    
    if (task.isCompleted) {
      buffer.write('Completed task: ');
    } else if (task.isOverdue) {
      buffer.write('Overdue task: ');
    } else {
      buffer.write('Task: ');
    }
    
    buffer.write(task.title);
    
    if (task.description != null && task.description!.isNotEmpty) {
      buffer.write('. ${task.description}');
    }
    
    if (task.dueDate != null) {
      buffer.write('. Due ${task.dueDateFormatted}');
    }
    
    if (category != null) {
      buffer.write('. Category: ${category!.name}');
    }
    
    buffer.write('. Tap to view details.');
    
    return buffer.toString();
  }
}
