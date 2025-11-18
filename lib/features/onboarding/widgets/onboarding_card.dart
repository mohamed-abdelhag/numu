import 'package:flutter/material.dart';
import '../../help/models/tutorial_card_model.dart';

/// Widget that displays a tutorial card in the onboarding flow
/// Reuses TutorialCardModel for content consistency with help screen
class OnboardingCard extends StatelessWidget {
  final TutorialCardModel tutorial;

  const OnboardingCard({
    super.key,
    required this.tutorial,
  });

  IconData _getIconFromName(String iconName) {
    // Map icon names to IconData
    switch (iconName) {
      case 'info':
        return Icons.info_outline;
      case 'celebration':
        return Icons.celebration;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'task':
        return Icons.task_alt;
      case 'help':
        return Icons.help_outline;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getIconFromName(tutorial.iconName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: theme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            tutorial.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            tutorial.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Full content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tutorial.content,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
