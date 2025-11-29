import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../models/enums/prayer_type.dart';
import '../models/prayer_event.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_settings_provider.dart';

/// Dialog for editing a completed prayer event.
/// Allows editing the actual prayer time and jamaah status.
/// Includes honest messaging - this is for improvement, not to impress.
class PrayerEditDialog extends ConsumerStatefulWidget {
  final PrayerType prayerType;
  final PrayerEvent existingEvent;
  final DateTime? scheduledTime;

  const PrayerEditDialog({
    super.key,
    required this.prayerType,
    required this.existingEvent,
    this.scheduledTime,
  });

  @override
  ConsumerState<PrayerEditDialog> createState() => _PrayerEditDialogState();
}

class _PrayerEditDialogState extends ConsumerState<PrayerEditDialog> {
  late bool _prayedInJamaah;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;
  late TextEditingController _notesController;
  int _timeWindowMinutes = 30;

  @override
  void initState() {
    super.initState();
    CoreLoggingUtility.info(
      'PrayerEditDialog',
      'initState',
      'Opening edit dialog for ${widget.prayerType.englishName}, event ID: ${widget.existingEvent.id}',
    );
    _prayedInJamaah = widget.existingEvent.prayedInJamaah;
    final actualTime = widget.existingEvent.actualPrayerTime ?? 
                       widget.existingEvent.eventTimestamp;
    _selectedTime = TimeOfDay.fromDateTime(actualTime);
    _notesController = TextEditingController(text: widget.existingEvent.notes ?? '');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(prayerSettingsProvider.future);
      if (mounted) {
        setState(() {
          _timeWindowMinutes = settings.timeWindowMinutes;
        });
      }
    } catch (_) {
      // Use default value if loading fails
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Check if the selected time is before the prayer's scheduled time
  bool _isBeforePrayerTime() {
    if (widget.scheduledTime == null) return false;
    
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year, now.month, now.day, 
      _selectedTime.hour, _selectedTime.minute
    );
    
    return selectedDateTime.isBefore(widget.scheduledTime!);
  }

  /// Check if the selected time is after the time window (late)
  bool _isLate() {
    if (widget.scheduledTime == null) return false;
    
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year, now.month, now.day, 
      _selectedTime.hour, _selectedTime.minute
    );
    
    final windowEnd = widget.scheduledTime!.add(Duration(minutes: _timeWindowMinutes));
    return selectedDateTime.isAfter(windowEnd);
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

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${widget.prayerType.englishName}',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  widget.prayerType.arabicName,
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

            // Scheduled time info
            if (widget.scheduledTime != null) ...[
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
                    Text(
                      'Scheduled: ${_formatTime(widget.scheduledTime!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Status info banner - shows validation status
            _buildStatusInfoBanner(theme, colorScheme),
            const SizedBox(height: 12),

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

            // Jamaah checkbox
            Container(
              decoration: BoxDecoration(
                color: _prayedInJamaah
                    ? Colors.green.withValues(alpha: 0.1)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: _prayedInJamaah
                    ? Border.all(color: Colors.green.withValues(alpha: 0.5))
                    : null,
              ),
              child: CheckboxListTile(
                title: const Text('Prayed in Jamaah (جماعة)'),
                subtitle: const Text('Congregational prayer'),
                value: _prayedInJamaah,
                onChanged: (value) {
                  setState(() {
                    _prayedInJamaah = value ?? false;
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Icon(
                  Icons.groups,
                  color: _prayedInJamaah ? Colors.green : colorScheme.onSurfaceVariant,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || _isBeforePrayerTime() ? null : _updatePrayer,
          style: _isLate()
              ? FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                )
              : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLate() ? 'Save as Late' : 'Save Changes'),
        ),
      ],
    );
  }

  /// Build status info banner showing validation status
  Widget _buildStatusInfoBanner(ThemeData theme, ColorScheme colorScheme) {
    final isBeforePrayer = _isBeforePrayerTime();
    final isLate = _isLate();
    final effectiveTime = _getSelectedPrayerTime();

    // If before prayer time, show error banner
    if (isBeforePrayer) {
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
                'Cannot set time before the scheduled prayer time',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If late, show warning banner
    if (isLate) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Will be marked as late (${_formatTime(effectiveTime)})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal case - within time window
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
              'On time (${_formatTime(effectiveTime)})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green.shade800,
              ),
            ),
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
        'PrayerEditDialog',
        '_pickTime',
        'Time picked: ${picked.hour}:${picked.minute}',
      );
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updatePrayer() async {
    // Validate - cannot set time before prayer time
    if (_isBeforePrayerTime()) {
      CoreLoggingUtility.warning(
        'PrayerEditDialog',
        '_updatePrayer',
        'Attempted to set time before scheduled prayer time',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot set time before the scheduled prayer time'),
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
      // Calculate new actual prayer time
      final now = DateTime.now();
      final newActualPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      CoreLoggingUtility.info(
        'PrayerEditDialog',
        '_updatePrayer',
        'Updating ${widget.prayerType.englishName}: '
        'newTime=${newActualPrayerTime.toIso8601String()}, '
        'jamaah=$_prayedInJamaah, '
        'eventId=${widget.existingEvent.id}',
      );

      await ref.read(prayerProvider.notifier).updatePrayerEvent(
            existingEvent: widget.existingEvent,
            newActualPrayerTime: newActualPrayerTime,
            prayedInJamaah: _prayedInJamaah,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      CoreLoggingUtility.info(
        'PrayerEditDialog',
        '_updatePrayer',
        'Update completed successfully, closing dialog',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.prayerType.englishName} updated — honesty is the best policy! 🙏',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'PrayerEditDialog',
        '_updatePrayer',
        'Failed to update prayer: $e\n$stackTrace',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update prayer: $e'),
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
