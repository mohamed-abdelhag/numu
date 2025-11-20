import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/router/router.dart';
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/features/reminders/services/notification_navigation_service.dart';
import 'package:numu/features/reminders/services/reminder_background_handler.dart';


class MyApp extends ConsumerStatefulWidget {
  
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    CoreLoggingUtility.info(
      'MyApp',
      'didChangeAppLifecycleState',
      'App lifecycle changed to: $state',
    );
    
    // Handle app lifecycle changes for reminder background tasks
    ReminderBackgroundHandler().handleAppLifecycleChange(state);
    
    // Ensure shell stability when app resumes
    if (state == AppLifecycleState.resumed) {
      CoreLoggingUtility.info(
        'MyApp',
        'didChangeAppLifecycleState',
        'App resumed, verifying navigation state',
      );
      
      // Verify router is still valid
      try {
        final router = ref.read(routerProvider);
        final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();
        CoreLoggingUtility.info(
          'MyApp',
          'didChangeAppLifecycleState',
          'Current location: $currentLocation',
        );
        
        // If location is invalid or empty, navigate to home
        if (currentLocation.isEmpty || currentLocation == '/') {
          CoreLoggingUtility.info(
            'MyApp',
            'didChangeAppLifecycleState',
            'Invalid location detected, navigating to home',
          );
          Future.microtask(() => router.go('/home'));
        }
      } catch (e, stackTrace) {
        CoreLoggingUtility.error(
          'MyApp',
          'didChangeAppLifecycleState',
          'Error verifying navigation state: $e\n$stackTrace',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(themeProvider);
    final lightThemeAsync = ref.watch(lightThemeProvider);
    final darkThemeAsync = ref.watch(darkThemeProvider);
    
    // Initialize navigation service with router
    NotificationNavigationService().initialize(router);
    
    CoreLoggingUtility.info('app dart file','starting my app ','returning material app router');

    // Wait for all theme data to load
    return themeModeAsync.when(
      data: (themeMode) {
        return lightThemeAsync.when(
          data: (lightTheme) {
            return darkThemeAsync.when(
              data: (darkTheme) {
                return MaterialApp.router(
                  title: 'Numu App',
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: themeMode,
                  routerConfig: router,
                );
              },
              loading: () => _buildLoadingApp(),
              error: (error, stackTrace) {
                CoreLoggingUtility.error(
                  'MyApp',
                  'build',
                  'Error loading dark theme: $error',
                );
                // Use light theme for both if dark theme fails
                return MaterialApp.router(
                  title: 'Numu App',
                  theme: lightTheme,
                  darkTheme: lightTheme,
                  themeMode: themeMode,
                  routerConfig: router,
                );
              },
            );
          },
          loading: () => _buildLoadingApp(),
          error: (error, stackTrace) {
            CoreLoggingUtility.error(
              'MyApp',
              'build',
              'Error loading light theme: $error',
            );
            // Fallback to default theme on error
            return MaterialApp.router(
              title: 'Numu App',
              themeMode: themeMode,
              routerConfig: router,
            );
          },
        );
      },
      loading: () => _buildLoadingApp(),
      error: (error, stackTrace) {
        CoreLoggingUtility.error(
          'MyApp',
          'build',
          'Error loading theme mode: $error',
        );
        // Fallback to light mode on error
        return lightThemeAsync.when(
          data: (lightTheme) {
            return darkThemeAsync.when(
              data: (darkTheme) {
                return MaterialApp.router(
                  title: 'Numu App',
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: ThemeMode.light,
                  routerConfig: router,
                );
              },
              loading: () => _buildLoadingApp(),
              error: (e, s) => MaterialApp.router(
                title: 'Numu App',
                theme: lightTheme,
                darkTheme: lightTheme,
                themeMode: ThemeMode.light,
                routerConfig: router,
              ),
            );
          },
          loading: () => _buildLoadingApp(),
          error: (e, s) => MaterialApp.router(
            title: 'Numu App',
            themeMode: ThemeMode.light,
            routerConfig: router,
          ),
        );
      },
    );
  }

  /// Builds a loading screen while theme data is being loaded
  Widget _buildLoadingApp() {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}