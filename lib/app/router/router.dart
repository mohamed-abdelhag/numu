import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/features/home/home_screen.dart';
import 'package:numu/features/profile/profile_screen.dart';
import 'package:numu/features/settings/settings_screen.dart';
import 'package:numu/features/tasks/tasks_screen.dart';
import 'package:numu/features/habits/screens/habits_screen.dart';
import 'package:numu/features/habits/screens/add_habit_screen.dart';
import 'package:numu/features/habits/screens/habit_detail_screen.dart';
import 'package:numu/features/habits/screens/edit_habit_screen.dart';
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
          
          GoRoute(
            path: '/habits',
            name: 'habits',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const HabitsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-habit',
                pageBuilder: (context, state) => const MaterialPage(
                  child: AddHabitScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'habit-detail',
                pageBuilder: (context, state) {
                  final habitId = int.parse(state.pathParameters['id']!);
                  return MaterialPage(
                    child: HabitDetailScreen(habitId: habitId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-habit',
                    pageBuilder: (context, state) {
                      final habitId = int.parse(state.pathParameters['id']!);
                      return MaterialPage(
                        child: EditHabitScreen(habitId: habitId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});