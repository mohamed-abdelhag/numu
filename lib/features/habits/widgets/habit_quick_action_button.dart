import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../providers/habits_provider.dart';
import '../providers/habit_detail_provider.dart';
import 'log_habit_event_dialog.dart';

/// Quick action button for habit cards
/// Provides context-aware actions based on habit type and configuration
/// 
/// Behavior by tracking type:
/// - Binary without quality: Simple checkbox that marks complete
/// - Binary with quality: Checkbox that opens quality dialog on second click
/// - Value: Plus button to increment by 1, opens full dialog when goal reached
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
  Timer? _debounceTimer;
  int _pendingIncrements = 0;
  double _startingTotal = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Watch habit detail provider for current status
    final habitDetailAsync = ref.watch(habitDetailProvider(widget.habit.id!));

    return habitDetailAsync.when(
      data: (detailState) {
        switch (widget.habit.trackingType) {
          case TrackingType.binary:
            return _buildBinaryAction(detailState.events);
          case TrackingType.value:
            return _buildValueAction(detailState.events);
        }
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error_outline),
    );
  }

  /// Build action button for binary habits
  /// - Without quality: Simple checkbox
  /// - With quality: Checkbox that opens quality dialog on second click
  Widget _buildBinaryAction(List<HabitEvent> events) {
    final isCompleted = _isCompletedForDate(events, widget.date);

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
  }

  /// Build action button for value habits
  /// Plus button to increment by 1, opens full dialog when goal reached
  Widget _buildValueAction(List<HabitEvent> events) {
    final todayTotal = _getTotalForDate(events, widget.date);
    final target = widget.habit.targetValue ?? 0;
    final goalReached = todayTotal >= target;
    
    debugPrint('flutter_logs: {HabitQuickActionButton} {_buildValueAction} {Habit: ${widget.habit.name}, Today Total: $todayTotal, Target: $target, Goal Reached: $goalReached} {INFO}');

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
          await _incrementValue(todayTotal);
        }
      },
    );
  }

  /// Check if habit is completed for a specific date from provider events
  bool _isCompletedForDate(List<HabitEvent> events, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final dayEvents = events.where((e) {
      final eventDate = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
      return eventDate.isAtSameMomentAs(dateOnly);
    }).toList();
    
    if (dayEvents.isEmpty) return false;
    
    // For binary habits, check if completed
    return dayEvents.any((e) => e.completed == true);
  }

  /// Get total value for a specific date from provider events
  double _getTotalForDate(List<HabitEvent> events, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final dayEvents = events.where((e) {
      final eventDate = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
      return eventDate.isAtSameMomentAs(dateOnly);
    }).toList();
    
    final total = dayEvents.fold<double>(0, (sum, event) => sum + (event.valueDelta ?? 0));
    
    debugPrint('flutter_logs: {HabitQuickActionButton} {_getTotalForDate} {Date: $dateOnly, Events Count: ${dayEvents.length}, Total: $total} {INFO}');
    for (var i = 0; i < dayEvents.length; i++) {
      debugPrint('flutter_logs: {HabitQuickActionButton} {_getTotalForDate} {Event $i: valueDelta=${dayEvents[i].valueDelta}, value=${dayEvents[i].value}} {INFO}');
    }
    
    return total;
  }

  /// Mark binary habit as complete
  Future<void> _markBinaryComplete({required bool qualityAchieved}) async {
    if (!context.mounted) return;
    
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
  Future<void> _incrementValue(double currentTotal) async {
    if (!context.mounted) return;
    
    debugPrint('flutter_logs: {HabitQuickActionButton} {_incrementValue} {Starting - Current Total: $currentTotal} {INFO}');
    
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
        valueDelta: 1.0,
        value: currentTotal + 1.0,
        // NOTE: Quality layer is NOT set here for minimum goal habits.
        // Quality must be set via calendar in habit detail screen.
        qualityAchieved: null,
        createdAt: now,
        updatedAt: now,
      );
      
      debugPrint('flutter_logs: {HabitQuickActionButton} {_incrementValue} {Created Event - habitId: ${event.habitId}, valueDelta: ${event.valueDelta}, value: ${event.value}, date: ${event.eventDate}} {INFO}');

      await ref.read(habitsProvider.notifier).logEvent(event);
      
      debugPrint('flutter_logs: {HabitQuickActionButton} {_incrementValue} {Event logged successfully} {INFO}');

      if (mounted) {
        widget.onActionComplete?.call();
        
        // Debounce the success message to avoid spam
        _pendingIncrements++;
        if (_pendingIncrements == 1) {
          _startingTotal = currentTotal;
        }
        
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            final incrementsCount = _pendingIncrements;
            final finalTotal = _startingTotal + incrementsCount;
            
            if (incrementsCount == 1) {
              _showSuccessSnackbar(
                '+1 ${widget.habit.unit ?? ''} (Total: ${finalTotal.toInt()} ${widget.habit.unit ?? ''})',
              );
            } else {
              _showSuccessSnackbar(
                '+${widget.habit.unit ?? ''} added $incrementsCount times (Total: ${finalTotal.toInt()} ${widget.habit.unit ?? ''})',
              );
            }
            
            _pendingIncrements = 0;
          }
        });
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
    if (!context.mounted) return;
    
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

    if (result != null && mounted) {
      await _markBinaryComplete(qualityAchieved: result);
    }
  }

  /// Show full log dialog for value habits when goal reached
  Future<void> _showFullLogDialog() async {
    if (!context.mounted) return;
    
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
