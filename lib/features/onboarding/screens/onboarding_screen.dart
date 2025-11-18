import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../help/providers/tutorial_cards_provider.dart';
import '../widgets/onboarding_card.dart';
import '../../../core/utils/core_logging_utility.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      // Mark onboarding as completed
      await ref.read(onboardingProvider.notifier).markCompleted();
      
      CoreLoggingUtility.info(
        'OnboardingScreen',
        '_completeOnboarding',
        'Onboarding completed, navigating to home',
      );
      
      // Navigate to home screen
      if (mounted) {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'OnboardingScreen',
        '_completeOnboarding',
        'Failed to complete onboarding: $e\n$stackTrace',
      );
      
      // Show error and navigate anyway
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save onboarding status'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/home');
      }
    }
  }

  void _skipOnboarding() {
    CoreLoggingUtility.info(
      'OnboardingScreen',
      '_skipOnboarding',
      'User skipped onboarding',
    );
    _completeOnboarding();
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page, complete onboarding
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorialsAsync = ref.watch(tutorialCardsProvider);

    return Scaffold(
      body: SafeArea(
        child: tutorialsAsync.when(
          data: (tutorials) {
            // Filter to only show onboarding-relevant tutorials
            // Based on requirements: "What's this app?" and "How to use the app"
            final onboardingTutorials = tutorials.where((tutorial) {
              return tutorial.id == 'whats_this_app' || 
                     tutorial.id == 'enjoy_using_app';
            }).toList();

            if (onboardingTutorials.isEmpty) {
              // Fallback if no tutorials found
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to Numu!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Your habit tracking companion'),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Get Started'),
                    ),
                  ],
                ),
              );
            }

            final totalPages = onboardingTutorials.length;

            return Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentPage + 1} of $totalPages',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                
                // PageView with tutorial cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: totalPages,
                    itemBuilder: (context, index) {
                      return OnboardingCard(
                        tutorial: onboardingTutorials[index],
                      );
                    },
                  ),
                ),
                
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (only show if not on first page)
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox(width: 80),
                      
                      // Page indicators (dots)
                      Row(
                        children: List.generate(
                          totalPages,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                      
                      // Next/Finish button
                      ElevatedButton(
                        onPressed: () => _nextPage(totalPages),
                        child: Text(
                          _currentPage < totalPages - 1 ? 'Next' : 'Finish',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) {
            CoreLoggingUtility.error(
              'OnboardingScreen',
              'build',
              'Failed to load tutorials: $error\n$stack',
            );
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text('Failed to load onboarding content'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Continue Anyway'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
