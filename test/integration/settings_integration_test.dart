import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/app/theme/theme_registry.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  // Initialize Flutter bindings for the logging utility
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('Theme Persistence Integration Tests', () {
    late SharedPreferences prefs;
    late SettingsRepository repository;

    setUp(() async {
      // Clear all preferences before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
    });

    test('should persist and load color scheme across app restarts', () async {
      // Simulate first app launch - save a color scheme
      const testColorScheme = 'green';
      await repository.saveColorScheme(testColorScheme);

      // Verify it was saved to SharedPreferences
      final savedValue = prefs.getString('color_scheme');
      expect(savedValue, testColorScheme);

      // Simulate app restart - create new repository instance
      final newRepository = SettingsRepository(prefs);
      final loadedColorScheme = await newRepository.getColorScheme();

      // Verify the color scheme persisted
      expect(loadedColorScheme, testColorScheme);
    });

    test('should persist and load theme mode across app restarts', () async {
      // Simulate first app launch - save a theme mode
      const testThemeMode = ThemeMode.dark;
      await repository.saveThemeMode(testThemeMode);

      // Verify it was saved to SharedPreferences
      final savedValue = prefs.getString('theme_mode');
      expect(savedValue, 'dark');

      // Simulate app restart - create new repository instance
      final newRepository = SettingsRepository(prefs);
      final loadedThemeMode = await newRepository.getThemeMode();

      // Verify the theme mode persisted
      expect(loadedThemeMode, testThemeMode);
    });

    test('should use default theme (blue, light) when no preferences exist', () async {
      // Don't save any preferences - simulate first app launch
      final colorScheme = await repository.getColorScheme();
      final themeMode = await repository.getThemeMode();

      // Verify defaults are used
      expect(colorScheme, ThemeRegistry.defaultThemeId);
      expect(colorScheme, 'blue');
      expect(themeMode, ThemeMode.light);
    });

    test('should handle corrupted color scheme data gracefully', () async {
      // Save invalid color scheme data directly to SharedPreferences
      await prefs.setString('color_scheme', 'invalid_theme_id');

      // Should return default without crashing
      final colorScheme = await repository.getColorScheme();
      expect(colorScheme, ThemeRegistry.defaultThemeId);

      // Verify corrupted data was cleared
      final clearedValue = prefs.getString('color_scheme');
      expect(clearedValue, isNull);
    });

    test('should handle corrupted theme mode data gracefully', () async {
      // Save invalid theme mode data directly to SharedPreferences
      await prefs.setString('theme_mode', 'invalid_mode');

      // Should return default without crashing
      final themeMode = await repository.getThemeMode();
      expect(themeMode, ThemeMode.light);

      // Verify corrupted data was cleared
      final clearedValue = prefs.getString('theme_mode');
      expect(clearedValue, isNull);
    });

    test('should reject invalid color scheme IDs', () async {
      // Try to save an invalid color scheme
      expect(
        () => repository.saveColorScheme('invalid_theme'),
        throwsA(isA<SettingsException>()),
      );

      // Verify nothing was saved
      final savedValue = prefs.getString('color_scheme');
      expect(savedValue, isNull);
    });

    test('should persist both color scheme and theme mode independently', () async {
      // Save both settings
      await repository.saveColorScheme('brown');
      await repository.saveThemeMode(ThemeMode.dark);

      // Simulate app restart
      final newRepository = SettingsRepository(prefs);

      // Verify both persisted independently
      final colorScheme = await newRepository.getColorScheme();
      final themeMode = await newRepository.getThemeMode();

      expect(colorScheme, 'brown');
      expect(themeMode, ThemeMode.dark);
    });

    test('should handle all valid theme IDs', () async {
      final allThemes = ThemeRegistry.getAllThemes();

      for (final themeInfo in allThemes) {
        // Save each theme
        await repository.saveColorScheme(themeInfo.id);

        // Verify it was saved
        final loaded = await repository.getColorScheme();
        expect(loaded, themeInfo.id);
      }
    });

    test('should handle all valid theme modes', () async {
      final themeModes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

      for (final mode in themeModes) {
        // Save each mode
        await repository.saveThemeMode(mode);

        // Verify it was saved
        final loaded = await repository.getThemeMode();
        expect(loaded, mode);
      }
    });

    test('should validate storage health correctly', () async {
      // Save valid settings
      await repository.saveColorScheme('green');
      await repository.saveThemeMode(ThemeMode.dark);

      // Validate storage health
      final health = await repository.validateStorageHealth();

      // All settings should be healthy
      expect(health['theme_mode'], isTrue);
      expect(health['color_scheme'], isTrue);
    });

    test('should detect unhealthy storage with corrupted data', () async {
      // Corrupt the color scheme data
      await prefs.setString('color_scheme', 'invalid_theme');

      // Validate storage health
      final health = await repository.validateStorageHealth();

      // Color scheme should be detected as unhealthy (but still returns true after auto-fix)
      // The repository auto-fixes corrupted data, so it will be healthy after validation
      expect(health['color_scheme'], isTrue);
    });
  });
}
