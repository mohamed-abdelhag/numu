import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/router/router.dart';
import 'package:numu/app/theme/green_color_theme.dart' as green_theme;
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';


class MyApp extends ConsumerWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeAsync = ref.watch(themeProvider);
    
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