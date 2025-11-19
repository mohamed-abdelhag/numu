import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/providers/navigation_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/features/profile/providers/user_profile_provider.dart';

class NumuAppShell extends ConsumerWidget {
  final Widget child;

  const NumuAppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoreLoggingUtility.info('NumuAppShell', 'build', 'Building shell with drawer');
    
    final navigationState = ref.watch(navigationProvider);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final profileAsync = ref.watch(userProfileProvider);
                  
                  return profileAsync.when(
                    data: (profile) {
                      final userName = profile?.name ?? 'Guest';
                      CoreLoggingUtility.info(
                        'NumuAppShell',
                        'DrawerHeader',
                        'Displaying user name: $userName',
                      );
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 64,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome, $userName',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      );
                    },
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 64,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome, Guest',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    error: (error, stack) {
                      CoreLoggingUtility.error(
                        'NumuAppShell',
                        'DrawerHeader',
                        'Error loading user profile: $error',
                      );
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 64,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome, Guest',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            // Dynamically generate navigation items
            ...navigationState.when(
              data: (items) {
                // Filter to show only enabled items
                final enabledItems = items.where((item) => item.isEnabled).toList();
                
                // Sort by order property
                enabledItems.sort((a, b) => a.order.compareTo(b.order));
                
                CoreLoggingUtility.info(
                  'NumuAppShell',
                  'build',
                  'Rendering ${enabledItems.length} enabled navigation items',
                );
                
                // Find the index of settings item to add divider before it
                final settingsIndex = enabledItems.indexWhere((item) => item.id == 'settings');
                
                return enabledItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add divider before settings item
                      if (index == settingsIndex && settingsIndex > 0)
                        const Divider(),
                      ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        onTap: () {
                          CoreLoggingUtility.info(
                            'NumuAppShell',
                            'Drawer',
                            '${item.label} item tapped',
                          );
                          Navigator.pop(context);
                          context.go(item.route);
                        },
                      ),
                    ],
                  );
                }).toList();
              },
              loading: () => [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
              error: (error, stack) {
                CoreLoggingUtility.error(
                  'NumuAppShell',
                  'build',
                  'Error loading navigation items: $error',
                );
                // Fallback to basic navigation on error
                return [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                ];
              },
            ),
          ],
        ),
      ),
      body: _SafeChildWrapper(child: child),
    );
  }
}


/// Error boundary wrapper for child widgets
/// Catches and handles errors during child widget rendering
class _SafeChildWrapper extends StatelessWidget {
  final Widget child;

  const _SafeChildWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        '_SafeChildWrapper',
        'build',
        'Error rendering child widget: $e\n$stackTrace',
      );
      
      // Navigate to home on next frame to recover from error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            context.go('/home');
          } catch (navError) {
            CoreLoggingUtility.error(
              '_SafeChildWrapper',
              'build',
              'Failed to navigate to home: $navError',
            );
          }
        }
      });
      
      // Show error UI
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Navigation Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                try {
                  context.go('/home');
                } catch (navError) {
                  CoreLoggingUtility.error(
                    '_SafeChildWrapper',
                    'onPressed',
                    'Manual navigation failed: $navError',
                  );
                }
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    }
  }
}
