import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/router/router.dart';
import 'package:numu/app/theme/green_color_theme.dart' as green_theme;
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
    final themeAsync = ref.watch(themeProvider);
    
    // Initialize navigation service with router
    NotificationNavigationService().initialize(router);
    
    CoreLoggingUtility.info('app dart file','starting my app ','returning material app router');

    return themeAsync.when(
      data: (themeMode) {
        return MaterialApp.router(
          title: 'Numu App',
          theme: _buildLightTheme(context),
          darkTheme: _buildDarkTheme(context),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
      loading: () {
        // Show a loading indicator while theme is being loaded
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        // On error, fallback to light theme
        CoreLoggingUtility.error(
          'MyApp',
          'build',
          'Error loading theme: $error',
        );
        return MaterialApp.router(
          title: 'Numu App',
          theme: _buildLightTheme(context),
          darkTheme: _buildDarkTheme(context),
          themeMode: ThemeMode.light,
          routerConfig: router,
        );
      },
    );
  }

  /// Builds the light theme with appropriate colors and Material 3 styling
  ThemeData _buildLightTheme(BuildContext context) {
    const textTheme = TextTheme();
    final materialTheme = green_theme.MaterialTheme(textTheme);
    return materialTheme.light().copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }

  /// Builds the dark theme with appropriate colors and Material 3 styling
  ThemeData _buildDarkTheme(BuildContext context) {
    const textTheme = TextTheme();
    final materialTheme = green_theme.MaterialTheme(textTheme);
    return materialTheme.dark().copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}