import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../providers/habits_provider.dart';

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
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
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

            // Time picker for timed tracking
            if (widget.habit.trackingType == TrackingType.timed)
              ...[
                _buildTimePicker(),
                const SizedBox(height: 16),
              ],

            // Value input for value tracking
            if (widget.habit.trackingType == TrackingType.value)
              ...[
                _buildValueInput(),
                const SizedBox(height: 16),
              ],

            // Notes field
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
              : Text(_getSaveButtonLabel()),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
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

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
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
    );
  }

  Widget _buildValueInput() {
    return TextField(
      controller: _valueController,
      decoration: InputDecoration(
        labelText: 'Value',
        border: const OutlineInputBorder(),
        suffixText: widget.habit.unit ?? '',
        helperText: 'Enter the amount to log',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: true,
    );
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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

  String _getSaveButtonLabel() {
    switch (widget.habit.trackingType) {
      case TrackingType.binary:
        return 'Mark Complete';
      case TrackingType.value:
        return 'Save';
      case TrackingType.timed:
        return 'Save';
    }
  }

  Future<void> _saveEvent() async {
    // Validate value input for value tracking
    if (widget.habit.trackingType == TrackingType.value) {
      final valueText = _valueController.text.trim();
      if (valueText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a value'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final value = double.tryParse(valueText);
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid positive number'),
            backgroundColor: Colors.orange,
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
      final event = HabitEvent(
        habitId: widget.habit.id!,
        eventDate: _selectedDate,
        eventTimestamp: now,
        completed: widget.habit.trackingType == TrackingType.binary ? true : null,
        value: widget.habit.trackingType == TrackingType.value
            ? double.parse(_valueController.text.trim())
            : null,
        valueDelta: widget.habit.trackingType == TrackingType.value
            ? double.parse(_valueController.text.trim())
            : null,
        timeRecorded: widget.habit.trackingType == TrackingType.timed
            ? _selectedTime
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: now,
        updatedAt: now,
      );

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
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
