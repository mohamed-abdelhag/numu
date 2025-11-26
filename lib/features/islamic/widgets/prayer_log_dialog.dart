import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums/prayer_type.dart';
import '../providers/prayer_provider.dart';

/// Dialog for logging a prayer as completed.
/// Allows marking prayer with Jamaah option and specifying actual prayer time.
///
/// **Validates: Requirements 2.1, 2.2, 2.3, 6.4**
class PrayerLogDialog extends ConsumerStatefulWidget {
  final PrayerType prayerType;
  final DateTime? scheduledTime;

  const PrayerLogDialog({
    super.key,
    required this.prayerType,
    this.scheduledTime,
  });

  @override
  ConsumerState<PrayerLogDialog> createState() => _PrayerLogDialogState();
}

class _PrayerLogDialogState extends ConsumerState<PrayerLogDialog> {
  bool _prayedInJamaah = false;
  bool _specifyTime = false;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
              Icons.mosque,
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
                  'Log ${widget.prayerType.englishName}',
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
              const SizedBox(height: 16),
            ],

            // Jamaah checkbox
            _buildJamaahCheckbox(theme, colorScheme),
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
          onPressed: _isLoading ? null : _logPrayer,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark Complete'),
        ),
      ],
    );
  }

  Widget _buildJamaahCheckbox(ThemeData theme, ColorScheme colorScheme) {
    return Container(
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

  Future<void> _logPrayer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate actual prayer time if specified
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

      await ref.read(prayerProvider.notifier).logPrayer(
            prayerType: widget.prayerType,
            actualPrayerTime: actualPrayerTime,
            prayedInJamaah: _prayedInJamaah,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.prayerType.englishName} logged successfully!'),
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
