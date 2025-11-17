import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/app/shell/numu_app_bar.dart';



class NumuAppShell extends StatelessWidget {
  final Widget child;

  const NumuAppShell({
    super.key,
    required this.child,
  });

  String _getTitle(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    
    switch (location) {
      case '/home':
        return 'Home';
      case '/profile':
        return 'Profile';
      case '/settings':
        return 'Settings';
      case '/habits':
        return 'Habits';
      default:
        return 'App';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NumuAppBar(
        title: _getTitle(context),
        showMenuButton: true,
      ),
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
                Navigator.pop(context);
                context.go('/home');
              },
            ),

            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                context.go('/tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text('Habits'),
              onTap: () {
                Navigator.pop(context);
                context.go('/habits');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
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
          ],
        ),
      ),
      body: child,
    );
  }
}