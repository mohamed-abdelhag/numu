import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../providers/habits_provider.dart';
import '../repositories/habit_repository.dart';

/// Dialog for logging habit events
/// Supports binary, value, and timed tracking types
class LogHabitEventDialog extends ConsumerStatefulWidget {
  final Habit habit;

  const LogHabitEventDialog({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<LogHabitEventDialog> createState() => _LogHabitEventDialogState();
}

class _LogHabitEventDialogState extends ConsumerState<LogHabitEventDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  double? _todayTotal;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
    
    // Load today's total for value habits
    if (widget.habit.trackingType == TrackingType.value) {
      _loadTodayTotal();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Load today's total value for value-based habits
  Future<void> _loadTodayTotal() async {
    try {
      final repository = HabitRepository();
      final events = await repository.getEventsForDate(widget.habit.id!, _selectedDate);
      final total = events.fold<double>(0, (sum, event) => sum + (event.valueDelta ?? 0));
      if (mounted) {
        setState(() {
          _todayTotal = total;
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(int.parse(widget.habit.color)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.habit.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log ${widget.habit.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            _buildDatePicker(),
            const SizedBox(height: 16),
            
            // Tracking type specific inputs
            if (widget.habit.trackingType == TrackingType.value)
              ..._buildValueInputs(),
            
            if (widget.habit.trackingType == TrackingType.timed)
              ..._buildTimedInputs(),
            
            // Notes field (optional for all types)
            const SizedBox(height: 16),
            _buildNotesField(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.habit.trackingType == TrackingType.binary
                  ? 'Mark Complete'
                  : 'Save'),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _formatDate(_selectedDate),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  List<Widget> _buildValueInputs() {
    return [
      TextField(
        controller: _valueController,
        decoration: InputDecoration(
          labelText: 'Amount',
          border: const OutlineInputBorder(),
          suffixText: widget.habit.unit ?? '',
          helperText: widget.habit.unit != null ? null : 'Enter value',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        autofocus: true,
      ),
      const SizedBox(height: 16),
      
      // Show today's total and progress
      if (_todayTotal != null) ...[
        _buildTodayProgress(),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildTodayProgress() {
    final currentTotal = _todayTotal ?? 0;
    final valueToAdd = double.tryParse(_valueController.text) ?? 0;
    final newTotal = currentTotal + valueToAdd;
    final target = widget.habit.targetValue ?? 0;
    
    double progress = 0;
    if (target > 0) {
      if (widget.habit.goalType == GoalType.minimum) {
        progress = (newTotal / target).clamp(0.0, 1.0);
      } else if (widget.habit.goalType == GoalType.maximum) {
        progress = newTotal <= target ? 1.0 : 0.0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Total: ${newTotal.toStringAsFixed(1)}${widget.habit.unit != null ? ' ${widget.habit.unit}' : ''}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (widget.habit.goalType != GoalType.none && target > 0) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of ${target.toStringAsFixed(1)}${widget.habit.unit != null ? ' ${widget.habit.unit}' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildTimedInputs() {
    return [
      InkWell(
        onTap: _pickTime,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Time',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
          ),
          child: Text(
            _selectedTime.format(context),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    ];
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        border: OutlineInputBorder(),
        hintText: 'Add any notes about this entry...',
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      
      // Reload today's total if date changed for value habits
      if (widget.habit.trackingType == TrackingType.value) {
        _loadTodayTotal();
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    // Validate value input for value habits
    if (widget.habit.trackingType == TrackingType.value) {
      final value = double.tryParse(_valueController.text);
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid value'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final event = _createEvent(now);
      
      await ref.read(habitsProvider.notifier).logEvent(event);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.habit.name} logged successfully!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  HabitEvent _createEvent(DateTime now) {
    switch (widget.habit.trackingType) {
      case TrackingType.binary:
        return HabitEvent(
          habitId: widget.habit.id!,
          eventDate: _selectedDate,
          eventTimestamp: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            now.hour,
            now.minute,
          ),
          completed: true,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: now,
          updatedAt: now,
        );
      
      case TrackingType.value:
        final value = double.parse(_valueController.text);
        return HabitEvent(
          habitId: widget.habit.id!,
          eventDate: _selectedDate,
          eventTimestamp: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            now.hour,
            now.minute,
          ),
          valueDelta: value,
          value: (_todayTotal ?? 0) + value,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: now,
          updatedAt: now,
        );
      
      case TrackingType.timed:
        return HabitEvent(
          habitId: widget.habit.id!,
          eventDate: _selectedDate,
          eventTimestamp: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ),
          timeRecorded: _selectedTime,
          completed: true,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: now,
          updatedAt: now,
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
