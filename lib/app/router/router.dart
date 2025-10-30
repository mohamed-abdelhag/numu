import 'package:go_router/go_router.dart';
import 'package:numu/features/home/home_screen.dart';
import 'package:numu/features/profile/profile_screen.dart';
import 'package:numu/features/settings/settings_screen.dart';
import 'package:numu/features/tasks/tasks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/shell/numu_app_shell.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return NumuAppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            pageBuilder: (context, state) => NoTransitionPage(
              child: TasksScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});