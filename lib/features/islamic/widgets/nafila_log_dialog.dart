import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums/nafila_type.dart';
import '../providers/nafila_provider.dart';

/// Dialog for logging a Nafila prayer as completed.
/// Allows selecting rakat count, optional time, and notes.
///
/// **Validates: Requirements 1.2, 2.1**
class NafilaLogDialog extends ConsumerStatefulWidget {
  final NafilaType type;
  final DateTime? scheduledWindowStart;
  final DateTime? scheduledWindowEnd;

  const NafilaLogDialog({
    super.key,
    required this.type,
    this.scheduledWindowStart,
    this.scheduledWindowEnd,
  });

  @override
  ConsumerState<NafilaLogDialog> createState() => _NafilaLogDialogState();
}

class _NafilaLogDialogState extends ConsumerState<NafilaLogDialog> {
  late int _selectedRakats;
  bool _specifyTime = false;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRakats = widget.type.defaultRakats;
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Check if the selected/current time is within the valid window
  bool _isTimeInWindow() {
    if (widget.scheduledWindowStart == null || widget.scheduledWindowEnd == null) {
      return true; // No window specified, allow any time
    }

    final now = DateTime.now();
    final checkTime = _specifyTime
        ? DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute)
        : now;

    // Handle window crossing midnight (for Shaf'i/Witr)
    if (widget.scheduledWindowEnd!.isBefore(widget.scheduledWindowStart!)) {
      return !checkTime.isBefore(widget.scheduledWindowStart!) ||
          checkTime.isBefore(widget.scheduledWindowEnd!);
    }

    return !checkTime.isBefore(widget.scheduledWindowStart!) &&
        checkTime.isBefore(widget.scheduledWindowEnd!);
  }

  /// Get the time that will be used for logging
  DateTime _getEffectivePrayerTime() {
    final now = DateTime.now();
    if (_specifyTime) {
      return DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
    }
    return now;
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
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mosque,
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
                  'Log ${widget.type.englishName}',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  widget.type.arabicName,
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

            // Specify time option
            _buildSpecifyTimeOption(theme, colorScheme),

            // Time picker (if specifying time)
            if (_specifyTime) ...[
              const SizedBox(height: 12),
              _buildTimePicker(theme, colorScheme),
            ],

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
          onPressed: _isLoading || !_isTimeInWindow() ? null : _logNafila,
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
              : const Text('Log Prayer'),
        ),
      ],
    );
  }

  Widget _buildTimeValidationBanner(ThemeData theme, ColorScheme colorScheme) {
    final isValid = _isTimeInWindow();
    final effectiveTime = _getEffectivePrayerTime();

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
              'Will be logged at ${_formatTime(effectiveTime)}',
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
    final minRakats = widget.type.minRakats;
    final maxRakats = widget.type.maxRakats;

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

  Widget _buildSpecifyTimeOption(ThemeData theme, ColorScheme colorScheme) {
    return CheckboxListTile(
      title: const Text('Specify actual prayer time'),
      subtitle: const Text('When you actually prayed'),
      value: _specifyTime,
      onChanged: (value) {
        setState(() {
          _specifyTime = value ?? false;
        });
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildTimePicker(ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Actual Prayer Time',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(
          _formatTimeOfDay(_selectedTime),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
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

  Future<void> _logNafila() async {
    if (!_isTimeInWindow()) {
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
      DateTime? actualPrayerTime;
      if (_specifyTime) {
        final now = DateTime.now();
        actualPrayerTime = DateTime(
          now.year,
          now.month,
          now.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      }

      await ref.read(nafilaProvider.notifier).logNafila(
            type: widget.type,
            rakats: _selectedRakats,
            actualTime: actualPrayerTime,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.type.englishName} logged successfully!'),
            backgroundColor: Colors.green,
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
            content: Text('Failed to log prayer: $e'),
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
