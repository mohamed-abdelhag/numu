import 'package:flutter/material.dart';
import 'package:numu/features/habits/models/category.dart';

/// A reusable form widget for creating and editing tasks
/// 
/// Features:
/// - Title input field with validation
/// - Multi-line description field
/// - Date picker for due date selection
/// - Category dropdown selector
/// - Accessibility labels for all fields
class TaskForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? initialDueDate;
  final int? initialCategoryId;
  final List<Category> categories;
  final ValueChanged<DateTime?> onDueDateChanged;
  final ValueChanged<int?> onCategoryChanged;
  final GlobalKey<FormState>? formKey;

  const TaskForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    this.initialDueDate,
    this.initialCategoryId,
    required this.categories,
    required this.onDueDateChanged,
    required this.onCategoryChanged,
    this.formKey,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  DateTime? _selectedDueDate;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedDueDate = widget.initialDueDate;
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field (required)
          Semantics(
            label: 'Task title, required field',
            textField: true,
            child: TextFormField(
              controller: widget.titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter task title...',
                border: OutlineInputBorder(),
                helperText: 'Required',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title cannot be empty';
                }
                return null;
              },
              autofocus: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description field (optional)
          Semantics(
            label: 'Task description, optional field',
            textField: true,
            multiline: true,
            child: TextFormField(
              controller: widget.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task description...',
                border: OutlineInputBorder(),
                helperText: 'Optional',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              maxLines: 4,
              minLines: 3,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Due date picker
          Semantics(
            label: _selectedDueDate != null
                ? 'Due date selected: ${_formatDateForDisplay(_selectedDueDate!)}'
                : 'Select due date, optional',
            button: true,
            child: InkWell(
              onTap: () => _selectDueDate(context),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  helperText: 'Optional',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDueDate != null
                            ? _formatDateForDisplay(_selectedDueDate!)
                            : 'Select date...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _selectedDueDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedDueDate != null)
                          Semantics(
                            label: 'Clear due date',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedDueDate = null;
                                });
                                widget.onDueDateChanged(null);
                              },
                              tooltip: 'Clear date',
                            ),
                          ),
                        Icon(
                          Icons.calendar_today,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category dropdown
          Semantics(
            label: _selectedCategoryId != null
                ? 'Category selected: ${_getCategoryName(_selectedCategoryId!)}'
                : 'Select category, optional',
            button: true,
            child: DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                helperText: 'Optional',
              ),
              initialValue: _selectedCategoryId,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None'),
                ),
                ...widget.categories.map((category) {
                  return DropdownMenuItem<int?>(
                    value: category.id,
                    child: Row(
                      children: [
                        if (category.icon != null) ...[
                          Text(
                            category.icon!,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _parseCategoryColor(category.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
                widget.onCategoryChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show date picker dialog
  Future<void> _selectDueDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Select Due Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
      widget.onDueDateChanged(pickedDate);
    }
  }

  /// Format date for display
  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;

    if (date.year == now.year) {
      return '$weekday, $month $day';
    } else {
      return '$weekday, $month $day, ${date.year}';
    }
  }

  /// Get category name by ID
  String _getCategoryName(int categoryId) {
    try {
      final category = widget.categories.firstWhere(
        (cat) => cat.id == categoryId,
      );
      return category.name;
    } catch (e) {
      return 'Unknown';
    }
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
}
