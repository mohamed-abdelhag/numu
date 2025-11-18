import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/providers/navigation_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

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
              child: Column(
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
                    'Numu App',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
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
      body: child,
    );
  }
}