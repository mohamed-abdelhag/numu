import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/app/theme/theme_registry.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('Settings Profile Theme Integration Tests', () {
    late SharedPreferences prefs;
    late SettingsRepository settingsRepository;

    setUp(() async {
      // Initialize SharedPreferences with clean state
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settingsRepository = SettingsRepository(prefs);
    });

    tearDown(() async {
      // Clear all preferences after each test
      await prefs.clear();
    });

    test('12.1: Complete theme selection flow - navigate, preview, save, verify persistence', () async {
      // Initial state - save default theme
      await settingsRepository.saveColorScheme('blue');
      await settingsRepository.saveThemeMode(ThemeMode.light);

      // Verify initial state
      final initialColorScheme = await settingsRepository.getColorScheme();
      final initialThemeMode = await settingsRepository.getThemeMode();
      expect(initialColorScheme, 'blue');
      expect(initialThemeMode, ThemeMode.light);

      // Simulate theme selection - change to green
      const newColorScheme = 'green';
      await settingsRepository.saveColorScheme(newColorScheme);

      // Verify theme was saved
      final savedColorScheme = await settingsRepository.getColorScheme();
      expect(savedColorScheme, newColorScheme);

      // Verify it persists in SharedPreferences
      final persistedValue = prefs.getString('color_scheme');
      expect(persistedValue, newColorScheme);

      // Simulate app restart - create new repository instance
      final newRepository = SettingsRepository(prefs);
      final loadedColorScheme = await newRepository.getColorScheme();
      final loadedThemeMode = await newRepository.getThemeMode();

      // Verify persistence across restart
      expect(loadedColorScheme, newColorScheme);
      expect(loadedThemeMode, ThemeMode.light);

      // Verify theme is valid and can be retrieved from registry
      expect(ThemeRegistry.isValidThemeId(loadedColorScheme), isTrue);
      final themeInfo = ThemeRegistry.getTheme(loadedColorScheme);
      expect(themeInfo.id, newColorScheme);
      expect(themeInfo.displayName, isNotEmpty);
    });

    test('12.2: Theme changes apply immediately without app restart', () async {
      // Set initial theme
      await settingsRepository.saveColorScheme('blue');
      await settingsRepository.saveThemeMode(ThemeMode.light);

      // Change theme multiple times rapidly
      await settingsRepository.saveColorScheme('green');
      await settingsRepository.saveColorScheme('brown');
      await settingsRepository.saveColorScheme('cool_pink');

      // Verify final theme is immediately available
      final colorScheme = await settingsRepository.getColorScheme();
      expect(colorScheme, 'cool_pink');

      // Verify theme can be retrieved from registry
      final themeInfo = ThemeRegistry.getTheme(colorScheme);
      expect(themeInfo.id, 'cool_pink');
      expect(themeInfo.displayName, isNotEmpty);
    });

    test('12.3: Theme mode + color theme independence', () async {
      // Set initial state
      await settingsRepository.saveColorScheme('blue');
      await settingsRepository.saveThemeMode(ThemeMode.light);

      // Change only color scheme
      await settingsRepository.saveColorScheme('green');
      
      // Verify theme mode unchanged
      final themeMode1 = await settingsRepository.getThemeMode();
      expect(themeMode1, ThemeMode.light);

      // Change only theme mode
      await settingsRepository.saveThemeMode(ThemeMode.dark);
      
      // Verify color scheme unchanged
      final colorScheme1 = await settingsRepository.getColorScheme();
      expect(colorScheme1, 'green');

      // Change both simultaneously
      await settingsRepository.saveColorScheme('brown');
      await settingsRepository.saveThemeMode(ThemeMode.system);

      // Verify both changed
      final colorScheme2 = await settingsRepository.getColorScheme();
      final themeMode2 = await settingsRepository.getThemeMode();
      expect(colorScheme2, 'brown');
      expect(themeMode2, ThemeMode.system);

      // Simulate app restart
      final newRepository = SettingsRepository(prefs);
      final loadedColorScheme = await newRepository.getColorScheme();
      final loadedThemeMode = await newRepository.getThemeMode();

      // Verify both persisted independently
      expect(loadedColorScheme, 'brown');
      expect(loadedThemeMode, ThemeMode.system);
    });

    test('12.4: App restart with saved preferences', () async {
      // Set up complete theme preferences
      await settingsRepository.saveColorScheme('fancy_green');
      await settingsRepository.saveThemeMode(ThemeMode.dark);

      // Verify all preferences are saved to SharedPreferences
      expect(prefs.getString('color_scheme'), 'fancy_green');
      expect(prefs.getString('theme_mode'), 'dark');

      // Simulate app restart - create new repository instance
      final newSettingsRepo = SettingsRepository(prefs);
      
      // Load all preferences
      final colorScheme = await newSettingsRepo.getColorScheme();
      final themeMode = await newSettingsRepo.getThemeMode();

      // Verify all preferences loaded correctly after restart
      expect(colorScheme, 'fancy_green');
      expect(themeMode, ThemeMode.dark);

      // Verify theme can be built from loaded preferences
      final themeInfo = ThemeRegistry.getTheme(colorScheme);
      expect(themeInfo.id, 'fancy_green');
      expect(themeInfo.displayName, isNotEmpty);
      
      // Verify theme builder can create theme data for both light and dark modes
      final lightTheme = themeInfo.themeBuilder(const TextTheme(), Brightness.light);
      final darkTheme = themeInfo.themeBuilder(const TextTheme(), Brightness.dark);
      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
    });

    test('12.5: Error scenarios - corrupted color scheme data', () async {
      // Save invalid color scheme directly to SharedPreferences
      await prefs.setString('color_scheme', 'invalid_theme_xyz');

      // Should return default without crashing
      final colorScheme = await settingsRepository.getColorScheme();
      expect(colorScheme, ThemeRegistry.defaultThemeId);
      expect(colorScheme, 'blue');

      // Verify corrupted data was cleared
      final clearedValue = prefs.getString('color_scheme');
      expect(clearedValue, isNull);
    });

    test('12.6: Error scenarios - corrupted theme mode data', () async {
      // Save invalid theme mode directly to SharedPreferences
      await prefs.setString('theme_mode', 'invalid_mode_xyz');

      // Should return default without crashing
      final themeMode = await settingsRepository.getThemeMode();
      expect(themeMode, ThemeMode.light);

      // Verify corrupted data was cleared
      final clearedValue = prefs.getString('theme_mode');
      expect(clearedValue, isNull);
    });

    test('12.7: Error scenarios - invalid theme ID rejection', () async {
      // Try to save an invalid color scheme
      expect(
        () => settingsRepository.saveColorScheme('invalid_theme'),
        throwsA(isA<SettingsException>()),
      );

      // Verify nothing was saved
      final savedValue = prefs.getString('color_scheme');
      expect(savedValue, isNull);
    });

    test('12.8: Error scenarios - recovery from corrupted data', () async {
      // Corrupt both theme settings
      await prefs.setString('color_scheme', 'corrupted_theme');
      await prefs.setString('theme_mode', 'corrupted_mode');

      // Load settings - should recover with defaults
      final colorScheme = await settingsRepository.getColorScheme();
      final themeMode = await settingsRepository.getThemeMode();

      expect(colorScheme, 'blue');
      expect(themeMode, ThemeMode.light);

      // Verify corrupted data was cleared
      expect(prefs.getString('color_scheme'), isNull);
      expect(prefs.getString('theme_mode'), isNull);

      // Save valid settings after recovery
      await settingsRepository.saveColorScheme('green');
      await settingsRepository.saveThemeMode(ThemeMode.dark);

      // Verify recovery was successful
      final recoveredColorScheme = await settingsRepository.getColorScheme();
      final recoveredThemeMode = await settingsRepository.getThemeMode();

      expect(recoveredColorScheme, 'green');
      expect(recoveredThemeMode, ThemeMode.dark);
    });

    test('12.9: All available themes can be selected and persisted', () async {
      final allThemes = ThemeRegistry.getAllThemes();
      expect(allThemes.length, greaterThanOrEqualTo(6));

      for (final themeInfo in allThemes) {
        // Save each theme
        await settingsRepository.saveColorScheme(themeInfo.id);

        // Verify it was saved
        final loaded = await settingsRepository.getColorScheme();
        expect(loaded, themeInfo.id);

        // Verify persistence
        final persisted = prefs.getString('color_scheme');
        expect(persisted, themeInfo.id);

        // Verify theme can be retrieved from registry
        final retrievedTheme = ThemeRegistry.getTheme(loaded);
        expect(retrievedTheme.id, themeInfo.id);
        expect(retrievedTheme.displayName, themeInfo.displayName);
      }
    });

    test('12.10: All theme modes can be selected and persisted', () async {
      final themeModes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

      for (final mode in themeModes) {
        // Save each mode
        await settingsRepository.saveThemeMode(mode);

        // Verify it was saved
        final loaded = await settingsRepository.getThemeMode();
        expect(loaded, mode);

        // Verify persistence
        final persisted = prefs.getString('theme_mode');
        expect(persisted, mode.name);
      }
    });

    test('12.11: Theme preview and revert functionality', () async {
      // Set initial theme
      await settingsRepository.saveColorScheme('blue');
      final originalTheme = await settingsRepository.getColorScheme();
      expect(originalTheme, 'blue');

      // Simulate theme preview (user tapping different themes)
      await settingsRepository.saveColorScheme('green');
      await settingsRepository.saveColorScheme('brown');
      
      // User decides not to save, revert to original
      await settingsRepository.saveColorScheme(originalTheme);
      
      // Verify reverted to original
      final revertedTheme = await settingsRepository.getColorScheme();
      expect(revertedTheme, 'blue');
      
      // Now actually change and save
      await settingsRepository.saveColorScheme('fancy_green');
      final finalTheme = await settingsRepository.getColorScheme();
      expect(finalTheme, 'fancy_green');
    });

    test('12.12: Storage health validation', () async {
      // Save valid settings
      await settingsRepository.saveColorScheme('aqua_green');
      await settingsRepository.saveThemeMode(ThemeMode.dark);

      // Validate storage health
      final health = await settingsRepository.validateStorageHealth();

      // All settings should be healthy
      expect(health['theme_mode'], isTrue);
      expect(health['color_scheme'], isTrue);
    });

    test('12.13: Theme selection with multiple rapid changes', () async {
      // Simulate rapid theme changes (user quickly tapping different themes)
      final themes = ['blue', 'green', 'brown', 'cool_pink', 'fancy_green'];

      for (final theme in themes) {
        await settingsRepository.saveColorScheme(theme);
      }

      // Verify final theme is persisted
      final finalTheme = await settingsRepository.getColorScheme();
      expect(finalTheme, 'fancy_green');

      // Verify only final theme is in storage
      final persisted = prefs.getString('color_scheme');
      expect(persisted, 'fancy_green');
    });

    test('12.14: Complete user flow - browse, preview, save, restart', () async {
      // Step 1: User opens app with default theme
      var colorScheme = await settingsRepository.getColorScheme();
      var themeMode = await settingsRepository.getThemeMode();
      expect(colorScheme, 'blue'); // Default
      expect(themeMode, ThemeMode.light); // Default

      // Step 2: User navigates to theme selector and previews themes
      await settingsRepository.saveColorScheme('green');
      await settingsRepository.saveColorScheme('brown');
      await settingsRepository.saveColorScheme('aqua_green');

      // Step 3: User saves selected theme
      colorScheme = await settingsRepository.getColorScheme();
      expect(colorScheme, 'aqua_green');

      // Step 4: User also changes theme mode
      await settingsRepository.saveThemeMode(ThemeMode.dark);
      themeMode = await settingsRepository.getThemeMode();
      expect(themeMode, ThemeMode.dark);

      // Step 5: Simulate app restart
      final newRepository = SettingsRepository(prefs);
      final loadedColorScheme = await newRepository.getColorScheme();
      final loadedThemeMode = await newRepository.getThemeMode();

      // Step 6: Verify preferences persisted
      expect(loadedColorScheme, 'aqua_green');
      expect(loadedThemeMode, ThemeMode.dark);

      // Step 7: Verify theme can be built
      final themeInfo = ThemeRegistry.getTheme(loadedColorScheme);
      expect(themeInfo.id, 'aqua_green');
      expect(themeInfo.displayName, isNotEmpty);
    });
  });
}
