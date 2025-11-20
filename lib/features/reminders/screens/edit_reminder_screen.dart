import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/reminder.dart';
import '../models/reminder_type.dart';
import '../models/reminder_schedule.dart';
import '../models/reminder_link.dart';
import '../providers/reminder_provider.dart';
import '../../habits/providers/habits_provider.dart';
import '../../tasks/tasks_provider.dart';

enum LinkOption { standalone, habit, task }

class EditReminderScreen extends ConsumerStatefulWidget {
  final Reminder reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customTextController;
  late final TextEditingController _minutesBeforeController;

  // Form state
  late ReminderType _reminderType;
  late LinkOption _linkOption;
  int? _selectedHabitId;
  int? _selectedTaskId;
  late ScheduleFrequency _frequency;
  DateTime? _specificDateTime;
  TimeOfDay? _timeOfDay;
  late List<int> _activeWeekdays;
  late int _dayOfMonth;
  late bool _useHabitTimeWindow;
  late bool _useHabitActiveDays;
  late bool _useDefaultText;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and state from existing reminder
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(
      text: widget.reminder.description ?? '',
    );

    _reminderType = widget.reminder.type;
    _frequency = widget.reminder.schedule.frequency;
    _specificDateTime = widget.reminder.schedule.specificDateTime;
    _timeOfDay = widget.reminder.schedule.timeOfDay;
    _activeWeekdays =
        widget.reminder.schedule.activeWeekdays ?? [1, 2, 3, 4, 5];
    _dayOfMonth = widget.reminder.schedule.dayOfMonth ?? 1;
    _useHabitTimeWindow = widget.reminder.schedule.useHabitTimeWindow;
    _useHabitActiveDays = widget.reminder.schedule.useHabitActiveDays;

    // Initialize link option and related fields
    if (widget.reminder.link == null) {
      _linkOption = LinkOption.standalone;
    } else if (widget.reminder.link!.type == LinkType.habit) {
      _linkOption = LinkOption.habit;
      _selectedHabitId = widget.reminder.link!.entityId;
      _useDefaultText = widget.reminder.link!.useDefaultText;

      // If custom text, extract it from title
      if (!_useDefaultText) {
        _customTextController = TextEditingController(
          text: widget.reminder.title,
        );
      } else {
        _customTextController = TextEditingController();
      }
    } else {
      _linkOption = LinkOption.task;
      _selectedTaskId = widget.reminder.link!.entityId;
      _customTextController = TextEditingController();
      _useDefaultText = true;
    }

    // Initialize minutes before controller
    _minutesBeforeController = TextEditingController(
      text: widget.reminder.schedule.minutesBefore?.toString() ?? '15',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customTextController.dispose();
    _minutesBeforeController.dispose();
    super.dispose();
  }

  Future<void> _updateReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    if (_linkOption == LinkOption.task && _selectedTaskId != null) {
      final task = await ref.read(taskDetailProvider(_selectedTaskId!).future);
      if (task == null || task.dueDate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selected task must have a due date'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
    }

    if (_linkOption == LinkOption.habit &&
        _selectedHabitId != null &&
        _useHabitTimeWindow) {
      final habitsAsync = ref.read(habitsProvider);
      final habits = habitsAsync.value ?? [];
      final habit = habits.firstWhere((h) => h.id == _selectedHabitId);
      if (!habit.timeWindowEnabled || habit.timeWindowStart == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Selected habit must have a time window configured',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
    }

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();

      // Build schedule
      final schedule = ReminderSchedule(
        frequency: _frequency,
        specificDateTime: _frequency == ScheduleFrequency.none
            ? _specificDateTime
            : null,
        timeOfDay: _frequency != ScheduleFrequency.none ? _timeOfDay : null,
        activeWeekdays: _frequency == ScheduleFrequency.weekly
            ? _activeWeekdays
            : null,
        dayOfMonth: _frequency == ScheduleFrequency.monthly
            ? _dayOfMonth
            : null,
        minutesBefore:
            (_linkOption == LinkOption.task ||
                (_linkOption == LinkOption.habit && _useHabitTimeWindow))
            ? int.tryParse(_minutesBeforeController.text.trim())
            : null,
        useHabitTimeWindow:
            _linkOption == LinkOption.habit &&
            _selectedHabitId != null &&
            _useHabitTimeWindow,
        useHabitActiveDays:
            _linkOption == LinkOption.habit &&
            _selectedHabitId != null &&
            _useHabitActiveDays,
      );

      // Build link
      ReminderLink? link;
      if (_linkOption == LinkOption.habit && _selectedHabitId != null) {
        final habitsAsync = ref.read(habitsProvider);
        final habits = habitsAsync.value ?? [];
        final habit = habits.firstWhere((h) => h.id == _selectedHabitId);
        link = ReminderLink(
          type: LinkType.habit,
          entityId: _selectedHabitId!,
          entityName: habit.name,
          useDefaultText: _useDefaultText,
        );
      } else if (_linkOption == LinkOption.task && _selectedTaskId != null) {
        final task = await ref.read(
          taskDetailProvider(_selectedTaskId!).future,
        );
        link = ReminderLink(
          type: LinkType.task,
          entityId: _selectedTaskId!,
          entityName: task!.title,
          useDefaultText: true,
        );
      }

      // Determine title
      String title;
      if (_linkOption == LinkOption.habit &&
          _selectedHabitId != null &&
          _useDefaultText) {
        final habitsAsync = ref.read(habitsProvider);
        final habits = habitsAsync.value ?? [];
        final habit = habits.firstWhere((h) => h.id == _selectedHabitId);
        title = 'Do ${habit.name}';
      } else if (_linkOption == LinkOption.task && _selectedTaskId != null) {
        final task = await ref.read(
          taskDetailProvider(_selectedTaskId!).future,
        );
        title = task!.title;
      } else if (_linkOption == LinkOption.habit && !_useDefaultText) {
        title = _customTextController.text.trim();
      } else {
        title = _titleController.text.trim();
      }

      final updatedReminder = widget.reminder.copyWith(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _reminderType,
        schedule: schedule,
        link: link,
        updatedAt: now,
      );

      await ref.read(reminderProvider.notifier).updateReminder(updatedReminder);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reminder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text(
          'Are you sure you want to delete this reminder? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref
          .read(reminderProvider.notifier)
          .deleteReminder(widget.reminder.id!);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete reminder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildReminderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reminder Type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ReminderType>(
          segments: const [
            ButtonSegment(
              value: ReminderType.notification,
              label: Text('Notification'),
              icon: Icon(Icons.notifications),
            ),
            ButtonSegment(
              value: ReminderType.fullScreenAlarm,
              label: Text('Alarm'),
              icon: Icon(Icons.alarm),
            ),
          ],
          selected: {_reminderType},
          onSelectionChanged: (Set<ReminderType> selected) {
            if (selected.isNotEmpty) {
              setState(() {
                _reminderType = selected.first;
              });
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          _reminderType == ReminderType.notification
              ? 'Standard notification in notification tray'
              : 'Full-screen alarm requiring dismissal',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Link To', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<LinkOption>(
          segments: const [
            ButtonSegment(
              value: LinkOption.standalone,
              label: Text('Standalone'),
            ),
            ButtonSegment(value: LinkOption.habit, label: Text('Habit')),
            ButtonSegment(value: LinkOption.task, label: Text('Task')),
          ],
          selected: {_linkOption},
          onSelectionChanged: (Set<LinkOption> selected) {
            if (selected.isNotEmpty) {
              setState(() {
                _linkOption = selected.first;
                _selectedHabitId = null;
                _selectedTaskId = null;
                _useHabitTimeWindow = false;
                _useHabitActiveDays = false;
                _useDefaultText = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildHabitPicker() {
    final habitsAsync = ref.watch(habitsProvider);

    return habitsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Text(
        'Failed to load habits',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (habits) {
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Select Habit',
            border: OutlineInputBorder(),
          ),
          initialValue: _selectedHabitId,
          items: habits.map((habit) {
            return DropdownMenuItem<int>(
              value: habit.id,
              child: Text(habit.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedHabitId = value;
            });
          },
          validator: (value) {
            if (_linkOption == LinkOption.habit && value == null) {
              return 'Please select a habit';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildTaskPicker() {
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Text(
        'Failed to load tasks',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (tasks) {
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Select Task',
            border: OutlineInputBorder(),
          ),
          initialValue: _selectedTaskId,
          items: tasks.map((task) {
            return DropdownMenuItem<int>(
              value: task.id,
              child: Text(task.title),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTaskId = value;
            });
          },
          validator: (value) {
            if (_linkOption == LinkOption.task && value == null) {
              return 'Please select a task';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequency', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<ScheduleFrequency>(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          initialValue: _frequency,
          items: const [
            DropdownMenuItem(
              value: ScheduleFrequency.none,
              child: Text('One-time'),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.daily,
              child: Text('Daily'),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.weekly,
              child: Text('Weekly'),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.monthly,
              child: Text('Monthly'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _frequency = value!;
              // Reset date/time fields when frequency changes
              if (value == ScheduleFrequency.none) {
                _timeOfDay = null;
              } else {
                _specificDateTime = null;
                _timeOfDay ??= const TimeOfDay(hour: 9, minute: 0);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePickers() {
    if (_frequency == ScheduleFrequency.none) {
      // One-time reminder: show date and time picker
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date & Time'),
            subtitle: Text(
              _specificDateTime != null
                  ? '${_specificDateTime!.day}/${_specificDateTime!.month}/${_specificDateTime!.year} at ${_specificDateTime!.hour}:${_specificDateTime!.minute.toString().padLeft(2, '0')}'
                  : 'Not set',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _specificDateTime ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    _specificDateTime ?? DateTime.now(),
                  ),
                );
                if (time != null) {
                  setState(() {
                    _specificDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              }
            },
          ),
          if (_specificDateTime == null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'Please select a date and time',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    } else {
      // Repeating reminder: show time picker
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Time of Day'),
            subtitle: Text(
              _timeOfDay != null
                  ? '${_timeOfDay!.hour}:${_timeOfDay!.minute.toString().padLeft(2, '0')}'
                  : 'Not set',
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _timeOfDay ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _timeOfDay = time;
                });
              }
            },
          ),
        ],
      );
    }
  }

  Widget _buildWeekdaySelector() {
    if (_frequency != ScheduleFrequency.weekly) {
      return const SizedBox.shrink();
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Active Days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final isSelected = _activeWeekdays.contains(dayNumber);
            return FilterChip(
              label: Text(weekdays[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _activeWeekdays.add(dayNumber);
                  } else {
                    _activeWeekdays.remove(dayNumber);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayOfMonthSelector() {
    if (_frequency != ScheduleFrequency.monthly) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Day of Month', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          initialValue: _dayOfMonth,
          items: List.generate(31, (index) {
            final day = index + 1;
            return DropdownMenuItem(value: day, child: Text('Day $day'));
          }),
          onChanged: (value) {
            setState(() {
              _dayOfMonth = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHabitOptions() {
    if (_linkOption != LinkOption.habit || _selectedHabitId == null) {
      return const SizedBox.shrink();
    }

    final habitsAsync = ref.watch(habitsProvider);
    final habits = habitsAsync.value ?? [];
    final habit = habits.firstWhere((h) => h.id == _selectedHabitId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Habit Options', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (habit.timeWindowEnabled && habit.timeWindowStart != null)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use habit time window'),
            subtitle: const Text('Trigger before habit\'s time window'),
            value: _useHabitTimeWindow,
            onChanged: (value) {
              setState(() {
                _useHabitTimeWindow = value ?? false;
              });
            },
          ),
        if (habit.activeWeekdays != null && habit.activeWeekdays!.isNotEmpty)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use habit active days'),
            subtitle: const Text('Only trigger on habit\'s active days'),
            value: _useHabitActiveDays,
            onChanged: (value) {
              setState(() {
                _useHabitActiveDays = value ?? false;
              });
            },
          ),
        if (_useHabitTimeWindow) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _minutesBeforeController,
            decoration: const InputDecoration(
              labelText: 'Minutes Before',
              hintText: 'e.g., 15, 30, 60',
              border: OutlineInputBorder(),
              suffixText: 'minutes',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (_useHabitTimeWindow) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter minutes before';
                }
                final minutes = int.tryParse(value.trim());
                if (minutes == null || minutes <= 0) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTaskOptions() {
    if (_linkOption != LinkOption.task || _selectedTaskId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Task Options', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _minutesBeforeController,
          decoration: const InputDecoration(
            labelText: 'Remind Before Due Date',
            hintText: 'e.g., 15, 30, 60',
            border: OutlineInputBorder(),
            suffixText: 'minutes',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (_linkOption == LinkOption.task) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter minutes before';
              }
              final minutes = int.tryParse(value.trim());
              if (minutes == null || minutes <= 0) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextConfiguration() {
    if (_linkOption != LinkOption.habit || _selectedHabitId == null) {
      return const SizedBox.shrink();
    }

    final habitsAsync = ref.watch(habitsProvider);
    final habits = habitsAsync.value ?? [];
    final habit = habits.firstWhere((h) => h.id == _selectedHabitId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Reminder Text', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          title: Text('Do ${habit.name}'),
          subtitle: const Text('Use default habit text'),
          value: true,
          groupValue: _useDefaultText,
          onChanged: (value) {
            setState(() {
              _useDefaultText = value ?? true;
            });
          },
        ),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Custom text'),
          subtitle: const Text('Enter your own reminder text'),
          value: false,
          groupValue: _useDefaultText,
          onChanged: (value) {
            setState(() {
              _useDefaultText = value ?? true;
            });
          },
        ),
        if (!_useDefaultText) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customTextController,
            decoration: const InputDecoration(
              labelText: 'Custom Text',
              hintText: 'Enter reminder text',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_linkOption == LinkOption.habit && !_useDefaultText) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter custom text';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteReminder,
            tooltip: 'Delete Reminder',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_linkOption == LinkOption.standalone) ...[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Take medication',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_linkOption == LinkOption.standalone) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            _buildReminderTypeSelector(),
            const SizedBox(height: 24),
            _buildLinkSelector(),
            const SizedBox(height: 16),
            if (_linkOption == LinkOption.habit) _buildHabitPicker(),
            if (_linkOption == LinkOption.task) _buildTaskPicker(),
            const SizedBox(height: 24),
            _buildFrequencySelector(),
            _buildDateTimePickers(),
            _buildWeekdaySelector(),
            _buildDayOfMonthSelector(),
            _buildHabitOptions(),
            _buildTaskOptions(),
            _buildTextConfiguration(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateReminder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Update Reminder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
