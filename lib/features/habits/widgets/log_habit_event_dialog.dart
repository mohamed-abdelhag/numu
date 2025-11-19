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
/// Can be used for both creating new entries (FAB) and editing existing entries (calendar)
class LogHabitEventDialog extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime? prefilledDate; // null for FAB, specific date for calendar click
  final HabitEvent? existingEvent; // null for new, populated for edit

  const LogHabitEventDialog({
    super.key,
    required this.habit,
    this.prefilledDate,
    this.existingEvent,
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
  bool _qualityAchieved = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    // Initialize date: use prefilledDate if provided, otherwise today
    _selectedDate = widget.prefilledDate ?? DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
    
    // Pre-fill values if editing existing event
    if (widget.existingEvent != null) {
      final event = widget.existingEvent!;
      
      // Pre-fill value for value habits
      if (event.valueDelta != null) {
        _valueController.text = event.valueDelta!.toString();
      }
      
      // Pre-fill time for timed habits
      if (event.timeRecorded != null) {
        _selectedTime = event.timeRecorded!;
      }
      
      // Pre-fill quality status
      if (event.qualityAchieved != null) {
        _qualityAchieved = event.qualityAchieved!;
      }
      
      // Pre-fill notes
      if (event.notes != null) {
        _notesController.text = event.notes!;
      }
    }
    
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
    final isEditing = widget.existingEvent != null;
    
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
              isEditing ? 'Edit ${widget.habit.name}' : 'Log ${widget.habit.name}',
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
            
            // Time window indicator
            if (widget.habit.timeWindowEnabled) ...[
              const SizedBox(height: 16),
              _buildTimeWindowIndicator(),
            ],
            
            // Quality layer checkbox
            if (widget.habit.qualityLayerEnabled) ...[
              const SizedBox(height: 16),
              _buildQualityCheckbox(),
            ],
            
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
              : Text(isEditing 
                  ? 'Update'
                  : (widget.habit.trackingType == TrackingType.binary
                      ? 'Mark Complete'
                      : 'Save')),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    // Make date field read-only if prefilledDate is provided (calendar-initiated)
    final isReadOnly = widget.prefilledDate != null;
    
    return InkWell(
      onTap: isReadOnly ? null : _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: const OutlineInputBorder(),
          suffixIcon: isReadOnly ? null : const Icon(Icons.calendar_today),
          enabled: !isReadOnly,
        ),
        child: Text(
          _formatDate(_selectedDate),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isReadOnly ? Theme.of(context).disabledColor : null,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildValueInputs() {
    // Build label with unit if available
    final label = widget.habit.unit != null 
        ? 'Amount (${widget.habit.unit})' 
        : 'Amount';
    
    return [
      TextField(
        controller: _valueController,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          helperText: 'Enter value',
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

  Widget _buildTimeWindowIndicator() {
    final isWithinWindow = _isWithinTimeWindow();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWithinWindow
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWithinWindow ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWithinWindow ? Icons.check_circle : Icons.info,
            color: isWithinWindow ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isWithinWindow
                  ? 'Within time window (${_formatTimeOfDay(widget.habit.timeWindowStart!)} - ${_formatTimeOfDay(widget.habit.timeWindowEnd!)})'
                  : 'Outside time window (${_formatTimeOfDay(widget.habit.timeWindowStart!)} - ${_formatTimeOfDay(widget.habit.timeWindowEnd!)})',
              style: TextStyle(
                color: isWithinWindow ? Colors.green[900] : Colors.orange[900],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCheckbox() {
    return CheckboxListTile(
      title: Text(widget.habit.qualityLayerLabel ?? 'Quality achieved'),
      subtitle: const Text('Check if you met the quality criteria'),
      value: _qualityAchieved,
      onChanged: (value) {
        setState(() {
          _qualityAchieved = value ?? false;
        });
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  bool _isWithinTimeWindow() {
    if (!widget.habit.timeWindowEnabled ||
        widget.habit.timeWindowStart == null ||
        widget.habit.timeWindowEnd == null) {
      return false;
    }

    final start = widget.habit.timeWindowStart!;
    final end = widget.habit.timeWindowEnd!;
    final current = _selectedTime;

    // Convert to minutes for easier comparison
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final currentMinutes = current.hour * 60 + current.minute;

    // Handle time window that crosses midnight
    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
        final isEditing = widget.existingEvent != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
                ? '${widget.habit.name} updated successfully!'
                : '${widget.habit.name} logged successfully!'),
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
            content: Text('Failed to save event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  HabitEvent _createEvent(DateTime now) {
    final withinTimeWindow = widget.habit.timeWindowEnabled ? _isWithinTimeWindow() : null;
    final qualityAchieved = widget.habit.qualityLayerEnabled ? _qualityAchieved : null;
    
    // Preserve existing event ID and creation time if editing
    final eventId = widget.existingEvent?.id;
    final createdAt = widget.existingEvent?.createdAt ?? now;
    
    switch (widget.habit.trackingType) {
      case TrackingType.binary:
        return HabitEvent(
          id: eventId,
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
          withinTimeWindow: withinTimeWindow,
          qualityAchieved: qualityAchieved,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: createdAt,
          updatedAt: now,
        );
      
      case TrackingType.value:
        final value = double.parse(_valueController.text);
        return HabitEvent(
          id: eventId,
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
          withinTimeWindow: withinTimeWindow,
          qualityAchieved: qualityAchieved,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: createdAt,
          updatedAt: now,
        );
      
      case TrackingType.timed:
        return HabitEvent(
          id: eventId,
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
          withinTimeWindow: withinTimeWindow,
          qualityAchieved: qualityAchieved,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: createdAt,
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
