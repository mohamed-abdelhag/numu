import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Splash screen that displays an animated emoji sequence during app initialization
/// 
/// The animation sequence is: 🌱 → 🌿 → 🌳 → 🍎
/// Each emoji is displayed for 500ms, for a total duration of 2 seconds
/// 
/// After the animation completes, the screen checks the onboarding status:
/// - If onboarding is not completed, navigates to /onboarding
/// - If onboarding is completed, navigates to /home
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  int _currentEmojiIndex = 0;
  final List<String> _emojis = ['🌱', '🌿', '🌳', '🍎'];
  
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }
  
  /// Starts the emoji animation sequence and handles navigation after completion
  Future<void> _startAnimation() async {
    try {
      // Cycle through emojis every 500ms
      for (int i = 0; i < _emojis.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _currentEmojiIndex = i;
          });
        }
      }
      
      // After animation completes (2 seconds total), check onboarding status
      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SplashScreen',
        '_startAnimation',
        'Error during splash animation: $e\n$stackTrace',
      );
      // On error, navigate to home as fallback
      if (mounted) {
        context.go('/home');
      }
    }
  }
  
  /// Checks onboarding status and navigates to the appropriate screen
  Future<void> _navigateToNextScreen() async {
    try {
      // Check if onboarding has been completed
      final isOnboardingCompleted = await ref.read(onboardingCompletedProvider.future);
      
      CoreLoggingUtility.info(
        'SplashScreen',
        '_navigateToNextScreen',
        'Onboarding completed: $isOnboardingCompleted',
      );
      
      if (!mounted) return;
      
      if (isOnboardingCompleted) {
        // Navigate to home if onboarding is completed
        context.go('/home');
      } else {
        // Navigate to onboarding if this is first launch
        context.go('/onboarding');
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SplashScreen',
        '_navigateToNextScreen',
        'Error checking onboarding status: $e\n$stackTrace',
      );
      // On error, navigate to home as fallback (fail gracefully)
      if (mounted) {
        context.go('/home');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: Text(
            _emojis[_currentEmojiIndex],
            key: ValueKey<int>(_currentEmojiIndex),
            style: const TextStyle(fontSize: 120),
          ),
        ),
      ),
    );
  }
}
