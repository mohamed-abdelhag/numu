import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/features/home/home_screen.dart';
import 'package:numu/features/profile/profile_screen.dart';
import 'package:numu/features/settings/settings_screen.dart';
import 'package:numu/features/tasks/tasks_screen.dart';
import 'package:numu/features/tasks/screens/add_task_screen.dart';
import 'package:numu/features/tasks/screens/edit_task_screen.dart';
import 'package:numu/features/tasks/screens/task_detail_screen.dart';
import 'package:numu/features/habits/screens/habits_screen.dart';
import 'package:numu/features/habits/screens/add_habit_screen.dart';
import 'package:numu/features/habits/screens/habit_detail_screen.dart';
import 'package:numu/features/habits/screens/edit_habit_screen.dart';
import 'package:numu/features/onboarding/screens/splash_screen.dart';
import 'package:numu/features/onboarding/screens/onboarding_screen.dart';
import 'package:numu/features/help/screens/help_screen.dart';
import 'package:numu/features/help/screens/tutorial_detail_screen.dart';
import 'package:numu/features/habits/screens/categories_screen.dart';
import 'package:numu/features/habits/screens/create_category_screen.dart';
import 'package:numu/features/habits/screens/edit_category_screen.dart';
import 'package:numu/features/habits/screens/category_detail_screen.dart';
import 'package:numu/features/reminders/screens/reminder_list_screen.dart';
import 'package:numu/features/reminders/screens/create_reminder_screen.dart';
import 'package:numu/features/reminders/screens/edit_reminder_screen.dart';
import 'package:numu/features/reminders/models/reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/core/widgets/shell/numu_app_shell.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash screen route (outside ShellRoute - no drawer)
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      // Onboarding screen route (outside ShellRoute - no drawer)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => const MaterialPage(
          child: OnboardingScreen(),
        ),
      ),
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
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-task',
                pageBuilder: (context, state) => const MaterialPage(
                  child: AddTaskScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'task-detail',
                pageBuilder: (context, state) {
                  final taskId = int.parse(state.pathParameters['id']!);
                  return MaterialPage(
                    child: TaskDetailScreen(taskId: taskId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-task',
                    pageBuilder: (context, state) {
                      final taskId = int.parse(state.pathParameters['id']!);
                      return MaterialPage(
                        child: EditTaskScreen(taskId: taskId),
                      );
                    },
                  ),
                ],
              ),
            ],
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
          
          GoRoute(
            path: '/reminders',
            name: 'reminders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReminderListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-reminder',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return MaterialPage(
                    child: CreateReminderScreen(
                      preSelectedHabitId: extra?['habitId'] as int?,
                      preSelectedHabitName: extra?['habitName'] as String?,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'edit-reminder',
                pageBuilder: (context, state) {
                  final reminder = state.extra as Reminder;
                  return MaterialPage(
                    child: EditReminderScreen(reminder: reminder),
                  );
                },
              ),
            ],
          ),
          
          GoRoute(
            path: '/help',
            name: 'help',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HelpScreen(),
            ),
            routes: [
              GoRoute(
                path: ':tutorialId',
                name: 'tutorial-detail',
                pageBuilder: (context, state) {
                  final tutorialId = state.pathParameters['tutorialId']!;
                  return MaterialPage(
                    child: TutorialDetailScreen(tutorialId: tutorialId),
                  );
                },
              ),
            ],
          ),
          
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-category',
                pageBuilder: (context, state) => const MaterialPage(
                  child: CreateCategoryScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'category-detail',
                pageBuilder: (context, state) {
                  final categoryId = int.parse(state.pathParameters['id']!);
                  return MaterialPage(
                    child: CategoryDetailScreen(categoryId: categoryId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-category',
                    pageBuilder: (context, state) {
                      final categoryId = int.parse(state.pathParameters['id']!);
                      return MaterialPage(
                        child: EditCategoryScreen(categoryId: categoryId),
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