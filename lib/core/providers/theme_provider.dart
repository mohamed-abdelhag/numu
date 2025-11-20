import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/settings_repository.dart';
import '../utils/core_logging_utility.dart';
import '../../app/theme/theme_registry.dart';
import '../../features/settings/providers/theme_config_provider.dart';

part 'theme_provider.g.dart';

/// Provider for SettingsRepository
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  throw UnimplementedError('SettingsRepository must be overridden in main.dart');
}

/// Notifier for managing theme mode state
/// This provider now reads from ThemeConfigProvider for backward compatibility
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemeMode> build() async {
    try {
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'build',
        'Loading theme mode from ThemeConfigProvider',
      );
      
      // Read theme mode from ThemeConfigProvider
      final config = await ref.watch(themeConfigProvider.future);
      final themeMode = config.themeMode;
      
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'build',
        'Successfully loaded theme mode: ${themeMode.name}',
      );
      return themeMode;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeNotifier',
        'build',
        'Failed to load theme mode: $e\nStack trace: $stackTrace',
      );
      // Return default theme on initialization error
      return ThemeMode.light;
    }
  }

  /// Updates the theme mode and persists it to storage
  /// Delegates to ThemeConfigProvider for consistency
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'setThemeMode',
        'Delegating theme mode update to ThemeConfigProvider: ${mode.name}',
      );
      
      // Delegate to ThemeConfigProvider
      await ref.read(themeConfigProvider.notifier).setThemeMode(mode);
      
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'setThemeMode',
        'Theme mode successfully updated',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeNotifier',
        'setThemeMode',
        'Failed to update theme mode: $e\nStack trace: $stackTrace',
      );
      
      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }
}

/// Provider for light theme data based on current color scheme
@riverpod
Future<ThemeData> lightTheme(Ref ref) async {
  try {
    CoreLoggingUtility.info(
      'lightTheme',
      'build',
      'Building light theme from ThemeConfigProvider',
    );
    
    // Get current theme configuration
    final config = await ref.watch(themeConfigProvider.future);
    
    // Get theme info from registry
    final themeInfo = ThemeRegistry.getTheme(config.colorSchemeId);
    
    // Build light theme using the theme builder
    const textTheme = TextTheme();
    final themeData = themeInfo.themeBuilder(textTheme, Brightness.light);
    
    CoreLoggingUtility.info(
      'lightTheme',
      'build',
      'Successfully built light theme with color scheme: ${config.colorSchemeId}',
    );
    
    // Apply common customizations
    return themeData.copyWith(
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
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'lightTheme',
      'build',
      'Failed to build light theme: $e\nStack trace: $stackTrace',
    );
    
    // Fallback to default blue theme
    const textTheme = TextTheme();
    final defaultTheme = ThemeRegistry.getTheme(ThemeRegistry.defaultThemeId);
    return defaultTheme.themeBuilder(textTheme, Brightness.light);
  }
}

/// Provider for dark theme data based on current color scheme
@riverpod
Future<ThemeData> darkTheme(Ref ref) async {
  try {
    CoreLoggingUtility.info(
      'darkTheme',
      'build',
      'Building dark theme from ThemeConfigProvider',
    );
    
    // Get current theme configuration
    final config = await ref.watch(themeConfigProvider.future);
    
    // Get theme info from registry
    final themeInfo = ThemeRegistry.getTheme(config.colorSchemeId);
    
    // Build dark theme using the theme builder
    const textTheme = TextTheme();
    final themeData = themeInfo.themeBuilder(textTheme, Brightness.dark);
    
    CoreLoggingUtility.info(
      'darkTheme',
      'build',
      'Successfully built dark theme with color scheme: ${config.colorSchemeId}',
    );
    
    // Apply common customizations
    return themeData.copyWith(
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
  } catch (e, stackTrace) {
    CoreLoggingUtility.error(
      'darkTheme',
      'build',
      'Failed to build dark theme: $e\nStack trace: $stackTrace',
    );
    
    // Fallback to default blue theme
    const textTheme = TextTheme();
    final defaultTheme = ThemeRegistry.getTheme(ThemeRegistry.defaultThemeId);
    return defaultTheme.themeBuilder(textTheme, Brightness.dark);
  }
}
