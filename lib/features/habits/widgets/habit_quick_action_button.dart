import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../providers/habits_provider.dart';
import '../repositories/habit_repository.dart';
import 'log_habit_event_dialog.dart';

/// Quick action button for habit cards
/// Provides context-aware actions based on habit type and configuration
/// 
/// Behavior by tracking type:
/// - Binary without quality: Simple checkbox that marks complete
/// - Binary with quality: Checkbox that opens quality dialog on second click
/// - Value: Plus button to increment by 1, opens full dialog when goal reached
/// - Timed: Add button that opens log dialog
/// 
/// Special case: Minimum goal habits with quality layer
/// Quick actions only increment value. Quality layer must be set via calendar
/// in habit detail screen to prevent accidental quality logging.
class HabitQuickActionButton extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback? onActionComplete;

  const HabitQuickActionButton({
    super.key,
    required this.habit,
    required this.date,
    this.onActionComplete,
  });

  @override
  ConsumerState<HabitQuickActionButton> createState() => _HabitQuickActionButtonState();
}

class _HabitQuickActionButtonState extends ConsumerState<HabitQuickActionButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (widget.habit.trackingType) {
      case TrackingType.binary:
        return _buildBinaryAction();
      case TrackingType.value:
        return _buildValueAction();
    }
  }

  /// Build action button for binary habits
  /// - Without quality: Simple checkbox
  /// - With quality: Checkbox that opens quality dialog on second click
  Widget _buildBinaryAction() {
    return FutureBuilder<bool>(
      future: _isCompletedToday(),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return Checkbox(
          value: isCompleted,
          onChanged: (value) async {
            if (value == true) {
              // First click: mark complete
              if (!widget.habit.qualityLayerEnabled) {
                // No quality layer: just mark complete
                await _markBinaryComplete(qualityAchieved: false);
              } else {
                // Has quality layer: check if already completed
                if (isCompleted) {
                  // Second click: open quality dialog
                  await _showQualityDialog();
                } else {
                  // First click: mark complete without quality
                  await _markBinaryComplete(qualityAchieved: false);
                }
              }
            }
          },
        );
      },
    );
  }

  /// Build action button for value habits
  /// Plus button to increment by 1, opens full dialog when goal reached
  Widget _buildValueAction() {
    return FutureBuilder<double>(
      future: _getTodayTotal(),
      builder: (context, snapshot) {
        final todayTotal = snapshot.data ?? 0;
        final target = widget.habit.targetValue ?? 0;
        final goalReached = todayTotal >= target;

        return IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            if (goalReached && widget.habit.qualityLayerEnabled) {
              // Goal reached and has quality layer: open full dialog
              await _showFullLogDialog();
            } else {
              // Increment value by 1
              // NOTE: For minimum goal habits with quality layer,
              // quick actions only increment value. Quality layer
              // must be set via calendar in habit detail screen.
              // This is by design to prevent accidental quality logging.
              await _incrementValue();
            }
          },
        );
      },
    );
  }

  /// Check if habit is completed today
  Future<bool> _isCompletedToday() async {
    try {
      final repository = HabitRepository();
      final events = await repository.getEventsForDate(widget.habit.id!, widget.date);
      
      if (events.isEmpty) return false;
      
      // For binary habits, check if completed
      return events.any((e) => e.completed == true);
    } catch (e) {
      return false;
    }
  }

  /// Get today's total value for value habits
  Future<double> _getTodayTotal() async {
    try {
      final repository = HabitRepository();
      final events = await repository.getEventsForDate(widget.habit.id!, widget.date);
      return events.fold<double>(0, (sum, event) => sum + (event.valueDelta ?? 0));
    } catch (e) {
      return 0;
    }
  }

  /// Mark binary habit as complete
  Future<void> _markBinaryComplete({required bool qualityAchieved}) async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final event = HabitEvent(
        habitId: widget.habit.id!,
        eventDate: widget.date,
        eventTimestamp: DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          now.hour,
          now.minute,
        ),
        completed: true,
        qualityAchieved: widget.habit.qualityLayerEnabled ? qualityAchieved : null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(habitsProvider.notifier).logEvent(event);

      if (mounted) {
        widget.onActionComplete?.call();
        _showSuccessSnackbar('${widget.habit.name} marked complete!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to mark complete: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Increment value by 1 for value habits
  Future<void> _incrementValue() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final todayTotal = await _getTodayTotal();
      
      final event = HabitEvent(
        habitId: widget.habit.id!,
        eventDate: widget.date,
        eventTimestamp: DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          now.hour,
          now.minute,
        ),
        valueDelta: 1.0,
        value: todayTotal + 1.0,
        // NOTE: Quality layer is NOT set here for minimum goal habits.
        // Quality must be set via calendar in habit detail screen.
        qualityAchieved: null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(habitsProvider.notifier).logEvent(event);

      if (mounted) {
        widget.onActionComplete?.call();
        final newTotal = todayTotal + 1.0;
        _showSuccessSnackbar(
          '+1 ${widget.habit.unit ?? ''} (Total: ${newTotal.toInt()} ${widget.habit.unit ?? ''})',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to log value: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show quality dialog for binary habits with quality layer
  Future<void> _showQualityDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.habit.name} - Quality'),
        content: Text(
          'Did you achieve quality for this habit?\n\n${widget.habit.qualityLayerLabel ?? 'Quality criteria'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _markBinaryComplete(qualityAchieved: result);
    }
  }

  /// Show full log dialog for value habits when goal reached
  Future<void> _showFullLogDialog() async {
    await showDialog(
      context: context,
      builder: (context) => LogHabitEventDialog(
        habit: widget.habit,
        prefilledDate: widget.date,
      ),
    );

    if (mounted) {
      widget.onActionComplete?.call();
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
