import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/features/tasks/task.dart';
import 'package:numu/features/tasks/tasks_provider.dart';
import 'package:numu/features/tasks/widgets/task_form.dart';
import 'package:numu/features/habits/providers/categories_provider.dart';

/// Screen for editing an existing task
/// 
/// Features:
/// - Form pre-filled with existing task data
/// - Title validation (required, non-empty)
/// - Update action with validation
/// - Cancel action to discard changes
/// - Delete option in app bar menu
/// - Navigation back on successful update or cancel
class EditTaskScreen extends ConsumerStatefulWidget {
  final int taskId;

  const EditTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  int? _selectedCategoryId;
  bool _isSaving = false;
  bool _isDeleting = false;
  Task? _originalTask;
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Initialize form with task data
  void _initializeForm(Task task) {
    if (_isInitialized) return;
    
    _originalTask = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _selectedDueDate = task.dueDate;
    _selectedCategoryId = task.categoryId;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        leading: Semantics(
          label: 'Cancel and go back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: (_isSaving || _isDeleting) ? null : _handleCancel,
            tooltip: 'Cancel',
          ),
        ),
        actions: [
          // Delete button in menu
          Semantics(
            label: 'Delete task',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: (_isSaving || _isDeleting) ? null : _handleDelete,
              tooltip: 'Delete',
            ),
          ),
          // Save button
          Semantics(
            label: 'Save changes',
            button: true,
            child: TextButton(
              onPressed: (_isSaving || _isDeleting) ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
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

          // Initialize form with task data
          _initializeForm(task);

          return categoriesAsync.when(
            data: (categories) => SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: TaskForm(
                formKey: _formKey,
                titleController: _titleController,
                descriptionController: _descriptionController,
                initialDueDate: _selectedDueDate,
                initialCategoryId: _selectedCategoryId,
                categories: categories,
                onDueDateChanged: (date) {
                  setState(() {
                    _selectedDueDate = date;
                  });
                },
                onCategoryChanged: (categoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                  });
                },
              ),
            ),
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
                      'Error loading categories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
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

  /// Check if there are unsaved changes
  bool _hasChanges() {
    if (_originalTask == null) return false;

    return _titleController.text.trim() != _originalTask!.title ||
        (_descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim()) !=
            _originalTask!.description ||
        _selectedDueDate != _originalTask!.dueDate ||
        _selectedCategoryId != _originalTask!.categoryId;
  }

  /// Handle cancel action - discard changes and navigate back
  void _handleCancel() {
    // Check if there are unsaved changes
    if (_hasChanges()) {
      // Show confirmation dialog
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: Semantics(
            label: 'You have unsaved changes. Are you sure you want to discard them?',
            child: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
          ),
          actions: [
            Semantics(
              label: 'Cancel and continue editing',
              button: true,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            Semantics(
              label: 'Discard changes and go back',
              button: true,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          context.pop();
        }
      });
    } else {
      // No changes, just go back
      context.pop();
    }
  }

  /// Handle save action - validate and update task
  Future<void> _handleSave() async {
    if (_originalTask == null) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      // Show error message with semantic announcement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            child: const Text('Please fix the errors before saving'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set saving state
    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated task
      final updatedTask = _originalTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        categoryId: _selectedCategoryId,
        updatedAt: DateTime.now(),
      );

      // Update task using provider
      await ref.read(tasksProvider.notifier).updateTask(updatedTask);

      // Show success message with semantic announcement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: const Text('Task updated successfully'),
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
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text('Error updating task: $error'),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleSave,
            ),
          ),
        );
      }
    }
  }

  /// Handle delete action - show confirmation and delete task
  Future<void> _handleDelete() async {
    if (_originalTask == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Semantics(
          label: 'Are you sure you want to delete ${_originalTask!.title}? This action cannot be undone.',
          child: Text(
            'Are you sure you want to delete "${_originalTask!.title}"? This action cannot be undone.',
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
      await ref.read(tasksProvider.notifier).deleteTask(_originalTask!.id!);

      // Show success message with semantic announcement
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
}
