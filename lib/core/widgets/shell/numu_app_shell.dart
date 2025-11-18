import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';



class NumuAppShell extends StatelessWidget {
  final Widget child;

  const NumuAppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('NumuAppShell', 'build', 'Building shell with drawer');
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
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                CoreLoggingUtility.info('NumuAppShell', 'Drawer', 'Home item tapped');
                Navigator.pop(context);
                context.go('/home');
              },
            ),

            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Tasks'),
              onTap: () {
                CoreLoggingUtility.info('NumuAppShell', 'Drawer', 'Tasks item tapped');
                Navigator.pop(context);
                context.go('/tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text('Habits'),
              onTap: () {
                CoreLoggingUtility.info('NumuAppShell', 'Drawer', 'Habits item tapped');
                Navigator.pop(context);
                context.go('/habits');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                CoreLoggingUtility.info('NumuAppShell', 'Drawer', 'Profile item tapped');
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                CoreLoggingUtility.info('NumuAppShell', 'Drawer', 'Settings item tapped');
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}