import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/nafila_event.dart';
import '../providers/nafila_provider.dart';

/// Dialog for editing an existing Nafila prayer event.
/// Allows editing rakat count, time, and notes, with delete option.
///
/// **Validates: Requirements 2.2**
class NafilaEditDialog extends ConsumerStatefulWidget {
  final NafilaEvent existingEvent;
  final DateTime? scheduledWindowStart;
  final DateTime? scheduledWindowEnd;

  const NafilaEditDialog({
    super.key,
    required this.existingEvent,
    this.scheduledWindowStart,
    this.scheduledWindowEnd,
  });

  @override
  ConsumerState<NafilaEditDialog> createState() => _NafilaEditDialogState();
}

class _NafilaEditDialogState extends ConsumerState<NafilaEditDialog> {
  late int _selectedRakats;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    CoreLoggingUtility.info(
      'NafilaEditDialog',
      'initState',
      'Opening edit dialog for ${widget.existingEvent.nafilaType.englishName}, event ID: ${widget.existingEvent.id}',
    );
    _selectedRakats = widget.existingEvent.rakatCount;
    final actualTime = widget.existingEvent.actualPrayerTime ??
        widget.existingEvent.eventTimestamp;
    _selectedTime = TimeOfDay.fromDateTime(actualTime);
    _notesController = TextEditingController(text: widget.existingEvent.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Check if the selected time is within the valid window
  bool _isTimeInWindow() {
    if (widget.scheduledWindowStart == null || widget.scheduledWindowEnd == null) {
      return true; // No window specified, allow any time
    }

    final now = DateTime.now();
    final checkTime = DateTime(
      now.year, now.month, now.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    // Handle window crossing midnight (for Shaf'i/Witr)
    if (widget.scheduledWindowEnd!.isBefore(widget.scheduledWindowStart!)) {
      return !checkTime.isBefore(widget.scheduledWindowStart!) ||
          checkTime.isBefore(widget.scheduledWindowEnd!);
    }

    return !checkTime.isBefore(widget.scheduledWindowStart!) &&
        checkTime.isBefore(widget.scheduledWindowEnd!);
  }

  /// Get the selected prayer time as DateTime
  DateTime _getSelectedPrayerTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nafilaType = widget.existingEvent.nafilaType;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${nafilaType.englishName}',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  nafilaType.arabicName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Honest reminder banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Be honest — this is for your improvement, not to impress anyone 💙',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time window info
            if (widget.scheduledWindowStart != null && widget.scheduledWindowEnd != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Valid: ${_formatTime(widget.scheduledWindowStart!)} - ${_formatTime(widget.scheduledWindowEnd!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Time validation status banner
            _buildTimeValidationBanner(theme, colorScheme),
            const SizedBox(height: 16),

            // Rakat count selector
            Text(
              'Number of Rakats',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildRakatSelector(theme, colorScheme),
            const SizedBox(height: 16),

            // Time picker
            Text(
              'Actual Prayer Time',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  _formatTimeOfDay(_selectedTime),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any notes...',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete this entry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || !_isTimeInWindow() ? null : _updateNafila,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildTimeValidationBanner(ThemeData theme, ColorScheme colorScheme) {
    final isValid = _isTimeInWindow();
    final effectiveTime = _getSelectedPrayerTime();

    if (!isValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 20,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selected time is outside the valid window',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Time: ${_formatTime(effectiveTime)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRakatSelector(ThemeData theme, ColorScheme colorScheme) {
    final nafilaType = widget.existingEvent.nafilaType;
    final minRakats = nafilaType.minRakats;
    final maxRakats = nafilaType.maxRakats;

    // For types with fixed rakats (like Sunnah Fajr), show simple display
    if (minRakats == maxRakats) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minRakats ركعة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // For types with variable rakats, show selector
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _selectedRakats > minRakats
                ? () => setState(() => _selectedRakats--)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_selectedRakats',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _selectedRakats < maxRakats
                ? () => setState(() => _selectedRakats++)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      CoreLoggingUtility.info(
        'NafilaEditDialog',
        '_pickTime',
        'Time picked: ${picked.hour}:${picked.minute}',
      );
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete this ${widget.existingEvent.nafilaType.englishName} entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteNafila();
    }
  }

  Future<void> _deleteNafila() async {
    if (widget.existingEvent.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      CoreLoggingUtility.info(
        'NafilaEditDialog',
        '_deleteNafila',
        'Deleting Nafila event ID ${widget.existingEvent.id}',
      );

      await ref.read(nafilaProvider.notifier).deleteNafila(widget.existingEvent.id!);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.existingEvent.nafilaType.englishName} entry deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaEditDialog',
        '_deleteNafila',
        'Failed to delete Nafila: $e\n$stackTrace',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _updateNafila() async {
    if (!_isTimeInWindow()) {
      CoreLoggingUtility.warning(
        'NafilaEditDialog',
        '_updateNafila',
        'Attempted to set time outside valid window',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected time is outside the valid window'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final newActualPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      CoreLoggingUtility.info(
        'NafilaEditDialog',
        '_updateNafila',
        'Updating ${widget.existingEvent.nafilaType.englishName}: '
        'newTime=${newActualPrayerTime.toIso8601String()}, '
        'rakats=$_selectedRakats, '
        'eventId=${widget.existingEvent.id}',
      );

      final updatedEvent = widget.existingEvent.copyWith(
        rakatCount: _selectedRakats,
        actualPrayerTime: newActualPrayerTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        updatedAt: now,
      );

      await ref.read(nafilaProvider.notifier).updateNafila(updatedEvent);

      CoreLoggingUtility.info(
        'NafilaEditDialog',
        '_updateNafila',
        'Update completed successfully, closing dialog',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.existingEvent.nafilaType.englishName} updated — honesty is the best policy! 🙏',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'NafilaEditDialog',
        '_updateNafila',
        'Failed to update Nafila: $e\n$stackTrace',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
