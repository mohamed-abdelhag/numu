import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reminder.dart';
import '../services/alarm_service.dart';

/// Full-screen alarm dialog that displays when an alarm reminder triggers
/// 
/// This widget creates an intrusive full-screen overlay that requires explicit
/// user interaction to dismiss. It prevents dismissal via back button and
/// displays the alarm prominently with sound playback.
/// 
/// Requirements: 13.3, 13.4, 13.5
class FullScreenAlarmDialog extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onDismiss;

  const FullScreenAlarmDialog({
    super.key,
    required this.reminder,
    required this.onDismiss,
  });

  /// Show the full-screen alarm dialog
  /// 
  /// This method displays the alarm as a full-screen dialog that cannot be
  /// dismissed by tapping outside or pressing the back button.
  static Future<void> show(
    BuildContext context,
    Reminder reminder,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      barrierColor: Colors.black87,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button dismissal
        child: FullScreenAlarmDialog(
          reminder: reminder,
          onDismiss: () {
            Navigator.of(context).pop();
            // Dismiss the alarm in the service
            if (reminder.id != null) {
              AlarmService().dismissAlarm(reminder.id!);
            }
          },
        ),
      ),
    );
  }

  @override
  State<FullScreenAlarmDialog> createState() => _FullScreenAlarmDialogState();
}

class _FullScreenAlarmDialogState extends State<FullScreenAlarmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Update current time
    _updateTime();
    
    // Update time every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateTime();
        return true;
      }
      return false;
    });

    // Vibrate on show
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        final timeOfDay = TimeOfDay.fromDateTime(now);
        _currentTime = timeOfDay.format(context);
      });
    }
  }

  String _getAlarmTitle() {
    if (widget.reminder.link != null) {
      final link = widget.reminder.link!;
      if (link.useDefaultText) {
        return 'Do ${link.entityName}';
      }
    }
    return widget.reminder.title;
  }

  String? _getAlarmDescription() {
    return widget.reminder.description;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Current time display
              Text(
                _currentTime,
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Animated alarm icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.errorContainer,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.error.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.alarm,
                      size: 80,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Alarm title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _getAlarmTitle(),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Alarm description (if available)
              if (_getAlarmDescription() != null &&
                  _getAlarmDescription()!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _getAlarmDescription()!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              
              const Spacer(flex: 3),
              
              // Dismiss button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onDismiss();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 8,
                      shadowColor: colorScheme.primary.withValues(alpha:0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      'DISMISS',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
