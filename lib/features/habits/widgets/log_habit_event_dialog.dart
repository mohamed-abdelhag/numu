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
/// Supports binary and value tracking types
/// Can be used for both creating new entries (FAB) and editing existing entries (calendar)
///
/// QUALITY LAYER LOGIC:
/// The quality layer is a binary attribute that applies to the primary habit metric,
/// NOT a separate counter. When quality layer is enabled:
/// 
/// - For binary habits: qualityAchieved indicates if the completion met quality criteria
///   Example: "Completed workout with proper form" = completed: true, qualityAchieved: true
/// 
/// - For value habits: qualityAchieved applies to the logged value
///   Example: "20 reps with focused quality" = valueDelta: 20, qualityAchieved: true
///   NOT: valueDelta: 20 (unfocused) + qualityDelta: 20 (focused)
/// 
/// This means one event can have both a value AND a quality status, where quality
/// describes HOW the value was achieved, not a separate measurement.
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
  HabitEvent? _loadedExistingEvent;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    // Initialize date: use prefilledDate if provided, otherwise today
    _selectedDate = widget.prefilledDate ?? DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
    
    // Load existing event data asynchronously
    _initializeEventData();
  }

  /// Load existing event data for the selected date
  /// This method handles both cases:
  /// 1. When existingEvent is passed directly (already loaded)
  /// 2. When only prefilledDate is provided (need to fetch from repository)
  Future<void> _initializeEventData() async {
    HabitEvent? eventToLoad;
    
    // Case 1: Event already provided
    if (widget.existingEvent != null) {
      eventToLoad = widget.existingEvent;
    } 
    // Case 2: Need to fetch event for the prefilled date
    else if (widget.prefilledDate != null) {
      eventToLoad = await _loadExistingEventForDate(widget.prefilledDate!);
    }
    
    // Pre-fill form fields if we have an event
    if (eventToLoad != null && mounted) {
      setState(() {
        _loadedExistingEvent = eventToLoad;
        
        // Pre-fill value for value habits
        final valueDelta = eventToLoad?.valueDelta;
        if (valueDelta != null) {
          _valueController.text = valueDelta.toString();
        }
        
        // Pre-fill quality status
        final qualityAchieved = eventToLoad?.qualityAchieved;
        if (qualityAchieved != null) {
          _qualityAchieved = qualityAchieved;
        }
        
        // Pre-fill notes
        final notes = eventToLoad?.notes;
        if (notes != null) {
          _notesController.text = notes;
        }
      });
    }
    
    // Load today's total for value habits
    if (widget.habit.trackingType == TrackingType.value) {
      _loadTodayTotal();
    }
  }

  /// Helper method to fetch existing event from repository for a specific date
  /// Returns null if no event exists for the date
  Future<HabitEvent?> _loadExistingEventForDate(DateTime date) async {
    try {
      final repository = HabitRepository();
      final events = await repository.getEventsForDate(widget.habit.id!, date);
      
      // Return the first event if any exist for this date
      return events.isNotEmpty ? events.first : null;
    } catch (e) {
      // Silently fail - not critical, user can still create new event
      return null;
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
    // Check if we're editing an existing event (either passed or loaded)
    final isEditing = widget.existingEvent != null || _loadedExistingEvent != null;
    
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
        if (target > 0) ...[
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

  /// Build quality layer checkbox
  /// 
  /// Quality is a binary attribute that describes HOW the habit was performed,
  /// not a separate measurement. For value habits, this applies to the entered value.
  /// Example: Entering "20" with quality checked means "20 reps done with quality",
  /// not "20 regular reps + 20 quality reps".
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
        final isEditing = widget.existingEvent != null || _loadedExistingEvent != null;
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
    
    // Quality layer is a binary attribute that applies to the primary value/completion
    // For example: "20 reps with focused quality" = valueDelta: 20, qualityAchieved: true
    // NOT: valueDelta: 20 (unfocused) + qualityDelta: 20 (focused)
    final qualityAchieved = widget.habit.qualityLayerEnabled ? _qualityAchieved : null;
    
    // Preserve existing event ID and creation time if editing
    // Use _loadedExistingEvent which may have been fetched from repository
    final existingEvent = widget.existingEvent ?? _loadedExistingEvent;
    final eventId = existingEvent?.id;
    final createdAt = existingEvent?.createdAt ?? now;
    
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
