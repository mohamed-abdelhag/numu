import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/features/tasks/tasks_provider.dart';
import 'package:numu/features/tasks/widgets/task_form.dart';
import 'package:numu/features/habits/providers/categories_provider.dart';

/// Screen for creating a new task
/// 
/// Features:
/// - Form with title, description, due date, and category fields
/// - Title validation (required, non-empty)
/// - Save action with validation
/// - Cancel action to discard changes
/// - Inline validation error display
/// - Navigation back to tasks list on successful save
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  int? _selectedCategoryId;
  bool _isSaving = false;
  bool _reminderEnabled = false;
  int _reminderMinutesBefore = 60;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        leading: Semantics(
          label: 'Cancel and go back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isSaving ? null : _handleCancel,
            tooltip: 'Cancel',
          ),
        ),
        actions: [
          Semantics(
            label: 'Save task',
            button: true,
            child: TextButton(
              onPressed: _isSaving ? null : _handleSave,
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
      body: categoriesAsync.when(
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
                // Disable reminder if due date is removed
                if (date == null) {
                  _reminderEnabled = false;
                }
              });
            },
            onCategoryChanged: (categoryId) {
              setState(() {
                _selectedCategoryId = categoryId;
              });
            },
            initialReminderEnabled: _reminderEnabled,
            initialReminderMinutesBefore: _reminderMinutesBefore,
            onReminderEnabledChanged: (enabled) {
              setState(() {
                _reminderEnabled = enabled;
              });
            },
            onReminderMinutesBeforeChanged: (minutes) {
              setState(() {
                _reminderMinutesBefore = minutes;
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
      ),
    );
  }

  /// Handle cancel action - discard changes and navigate back
  void _handleCancel() {
    // Check if there are unsaved changes
    final hasChanges = _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _selectedDueDate != null ||
        _selectedCategoryId != null;

    if (hasChanges) {
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

  /// Handle save action - validate and create task
  Future<void> _handleSave() async {
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
      // Create task using provider
      await ref.read(tasksProvider.notifier).addTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            dueDate: _selectedDueDate,
            categoryId: _selectedCategoryId,
            reminderEnabled: _reminderEnabled,
            reminderMinutesBefore: _reminderMinutesBefore,
          );

      // Show success message with semantic announcement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: const Text('Task created successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to tasks list
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
              child: Text('Error creating task: $error'),
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
}
