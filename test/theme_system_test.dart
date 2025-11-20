import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numu/app/theme/theme_registry.dart';
import 'package:numu/features/settings/models/theme_config.dart';
import 'package:numu/core/services/settings_repository.dart';
import 'package:numu/features/settings/providers/theme_config_provider.dart';
import 'package:numu/core/providers/theme_provider.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  // Initialize Flutter bindings for the logging utility
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('ThemeRegistry Tests', () {
    test('getTheme returns correct theme for valid ID', () {
      final theme = ThemeRegistry.getTheme('blue');
      expect(theme.id, 'blue');
      expect(theme.displayName, 'Blue');
    });

    test('getTheme returns default theme for invalid ID', () {
      final theme = ThemeRegistry.getTheme('invalid_theme_id');
      expect(theme.id, ThemeRegistry.defaultThemeId);
      expect(theme.id, 'blue');
    });

    test('getThemeStrict throws for invalid ID', () {
      expect(
        () => ThemeRegistry.getThemeStrict('invalid_theme_id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getThemeStrict returns theme for valid ID', () {
      final theme = ThemeRegistry.getThemeStrict('green');
      expect(theme.id, 'green');
      expect(theme.displayName, 'Green');
    });

    test('getAllThemes returns all 6 registered themes', () {
      final themes = ThemeRegistry.getAllThemes();
      expect(themes.length, 6);
      
      final themeIds = themes.map((t) => t.id).toList();
      expect(themeIds, containsAll([
        'blue',
        'green',
        'fancy_green',
        'aqua_green',
        'brown',
        'cool_pink',
      ]));
    });

    test('isValidThemeId returns true for valid IDs', () {
      expect(ThemeRegistry.isValidThemeId('blue'), isTrue);
      expect(ThemeRegistry.isValidThemeId('green'), isTrue);
      expect(ThemeRegistry.isValidThemeId('fancy_green'), isTrue);
      expect(ThemeRegistry.isValidThemeId('aqua_green'), isTrue);
      expect(ThemeRegistry.isValidThemeId('brown'), isTrue);
      expect(ThemeRegistry.isValidThemeId('cool_pink'), isTrue);
    });

    test('isValidThemeId returns false for invalid IDs', () {
      expect(ThemeRegistry.isValidThemeId('invalid'), isFalse);
      expect(ThemeRegistry.isValidThemeId(''), isFalse);
      expect(ThemeRegistry.isValidThemeId('BLUE'), isFalse);
    });

    test('defaultThemeId returns blue', () {
      expect(ThemeRegistry.defaultThemeId, 'blue');
    });

    test('all themes have required properties', () {
      final themes = ThemeRegistry.getAllThemes();
      
      for (final theme in themes) {
        expect(theme.id, isNotEmpty);
        expect(theme.displayName, isNotEmpty);
        expect(theme.previewColor, isNotNull);
        
        // Test that theme builder works for both light and dark modes
        final lightTheme = theme.themeBuilder(const TextTheme(), Brightness.light);
        final darkTheme = theme.themeBuilder(const TextTheme(), Brightness.dark);
        
        expect(lightTheme, isA<ThemeData>());
        expect(darkTheme, isA<ThemeData>());
        expect(lightTheme.brightness, Brightness.light);
        expect(darkTheme.brightness, Brightness.dark);
      }
    });
  });

  group('ThemeConfigModel Tests', () {
    test('creates model with required fields', () {
      const config = ThemeConfigModel(
        colorSchemeId: 'green',
        themeMode: ThemeMode.dark,
      );

      expect(config.colorSchemeId, 'green');
      expect(config.themeMode, ThemeMode.dark);
    });

    test('toJson serializes correctly', () {
      const config = ThemeConfigModel(
        colorSchemeId: 'brown',
        themeMode: ThemeMode.system,
      );

      final json = config.toJson();
      expect(json['colorSchemeId'], 'brown');
      expect(json['themeMode'], 'system');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'colorSchemeId': 'fancy_green',
        'themeMode': 'dark',
      };

      final config = ThemeConfigModel.fromJson(json);
      expect(config.colorSchemeId, 'fancy_green');
      expect(config.themeMode, ThemeMode.dark);
    });

    test('fromJson handles all theme modes', () {
      final lightConfig = ThemeConfigModel.fromJson({
        'colorSchemeId': 'blue',
        'themeMode': 'light',
      });
      expect(lightConfig.themeMode, ThemeMode.light);

      final darkConfig = ThemeConfigModel.fromJson({
        'colorSchemeId': 'blue',
        'themeMode': 'dark',
      });
      expect(darkConfig.themeMode, ThemeMode.dark);

      final systemConfig = ThemeConfigModel.fromJson({
        'colorSchemeId': 'blue',
        'themeMode': 'system',
      });
      expect(systemConfig.themeMode, ThemeMode.system);
    });

    test('fromJson defaults to light mode for invalid theme mode', () {
      final config = ThemeConfigModel.fromJson({
        'colorSchemeId': 'blue',
        'themeMode': 'invalid_mode',
      });
      expect(config.themeMode, ThemeMode.light);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = ThemeConfigModel(
        colorSchemeId: 'blue',
        themeMode: ThemeMode.light,
      );

      final withNewColor = original.copyWith(colorSchemeId: 'green');
      expect(withNewColor.colorSchemeId, 'green');
      expect(withNewColor.themeMode, ThemeMode.light);

      final withNewMode = original.copyWith(themeMode: ThemeMode.dark);
      expect(withNewMode.colorSchemeId, 'blue');
      expect(withNewMode.themeMode, ThemeMode.dark);

      final withBoth = original.copyWith(
        colorSchemeId: 'brown',
        themeMode: ThemeMode.system,
      );
      expect(withBoth.colorSchemeId, 'brown');
      expect(withBoth.themeMode, ThemeMode.system);
    });

    test('copyWith with no parameters returns identical values', () {
      const original = ThemeConfigModel(
        colorSchemeId: 'aqua_green',
        themeMode: ThemeMode.dark,
      );

      final copy = original.copyWith();
      expect(copy.colorSchemeId, original.colorSchemeId);
      expect(copy.themeMode, original.themeMode);
    });

    test('equality operator works correctly', () {
      const config1 = ThemeConfigModel(
        colorSchemeId: 'blue',
        themeMode: ThemeMode.light,
      );

      const config2 = ThemeConfigModel(
        colorSchemeId: 'blue',
        themeMode: ThemeMode.light,
      );

      const config3 = ThemeConfigModel(
        colorSchemeId: 'green',
        themeMode: ThemeMode.light,
      );

      expect(config1 == config2, isTrue);
      expect(config1 == config3, isFalse);
    });

    test('hashCode is consistent', () {
      const config1 = ThemeConfigModel(
        colorSchemeId: 'blue',
        themeMode: ThemeMode.light,
      );

      const config2 = ThemeConfigModel(
        colorSchemeId: 'blue',
        themeMode: ThemeMode.light,
      );

      expect(config1.hashCode, config2.hashCode);
    });

    test('toString returns readable format', () {
      const config = ThemeConfigModel(
        colorSchemeId: 'cool_pink',
        themeMode: ThemeMode.system,
      );

      final str = config.toString();
      expect(str, contains('cool_pink'));
      expect(str, contains('system'));
    });

    test('serialization round-trip preserves data', () {
      const original = ThemeConfigModel(
        colorSchemeId: 'fancy_green',
        themeMode: ThemeMode.dark,
      );

      final json = original.toJson();
      final restored = ThemeConfigModel.fromJson(json);

      expect(restored.colorSchemeId, original.colorSchemeId);
      expect(restored.themeMode, original.themeMode);
      expect(restored, original);
    });
  });

  group('SettingsRepository Color Scheme Tests', () {
    late SharedPreferences prefs;
    late SettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
    });

    test('getColorScheme returns default when no value saved', () async {
      final colorScheme = await repository.getColorScheme();
      expect(colorScheme, ThemeRegistry.defaultThemeId);
      expect(colorScheme, 'blue');
    });

    test('saveColorScheme persists valid color scheme', () async {
      await repository.saveColorScheme('green');
      
      final saved = prefs.getString('color_scheme');
      expect(saved, 'green');
      
      final loaded = await repository.getColorScheme();
      expect(loaded, 'green');
    });

    test('saveColorScheme rejects invalid color scheme ID', () async {
      expect(
        () => repository.saveColorScheme('invalid_theme'),
        throwsA(isA<SettingsException>()),
      );
      
      // Verify nothing was saved
      final saved = prefs.getString('color_scheme');
      expect(saved, isNull);
    });

    test('saveColorScheme accepts all valid theme IDs', () async {
      final validIds = ['blue', 'green', 'fancy_green', 'aqua_green', 'brown', 'cool_pink'];
      
      for (final id in validIds) {
        await repository.saveColorScheme(id);
        final loaded = await repository.getColorScheme();
        expect(loaded, id);
      }
    });

    test('getColorScheme handles corrupted data gracefully', () async {
      // Manually set invalid data
      await prefs.setString('color_scheme', 'corrupted_value');
      
      final colorScheme = await repository.getColorScheme();
      expect(colorScheme, ThemeRegistry.defaultThemeId);
      
      // Verify corrupted data was cleared
      final cleared = prefs.getString('color_scheme');
      expect(cleared, isNull);
    });

    test('getColorScheme handles empty string', () async {
      await prefs.setString('color_scheme', '');
      
      final colorScheme = await repository.getColorScheme();
      expect(colorScheme, ThemeRegistry.defaultThemeId);
    });

    test('color scheme persists across repository instances', () async {
      await repository.saveColorScheme('brown');
      
      // Create new repository instance
      final newRepository = SettingsRepository(prefs);
      final loaded = await newRepository.getColorScheme();
      
      expect(loaded, 'brown');
    });

    test('saveColorScheme throws SettingsException with descriptive message', () async {
      try {
        await repository.saveColorScheme('invalid');
        fail('Should have thrown SettingsException');
      } catch (e) {
        expect(e, isA<SettingsException>());
        expect(e.toString(), contains('Invalid color scheme ID'));
        expect(e.toString(), contains('invalid'));
      }
    });
  });

  group('ThemeConfigProvider Tests', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepository(prefs),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial build loads default configuration', () async {
      final config = await container.read(themeConfigProvider.future);
      
      expect(config.colorSchemeId, ThemeRegistry.defaultThemeId);
      expect(config.themeMode, ThemeMode.light);
    });

    test('initial build loads saved configuration', () async {
      // Pre-save configuration
      await prefs.setString('color_scheme', 'green');
      await prefs.setString('theme_mode', 'dark');
      
      final config = await container.read(themeConfigProvider.future);
      
      expect(config.colorSchemeId, 'green');
      expect(config.themeMode, ThemeMode.dark);
    });

    test('setColorScheme updates state and persists', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      await notifier.setColorScheme('brown');
      
      final config = await container.read(themeConfigProvider.future);
      expect(config.colorSchemeId, 'brown');
      
      // Verify persistence
      final saved = prefs.getString('color_scheme');
      expect(saved, 'brown');
    });

    test('setColorScheme rejects invalid theme ID', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      expect(
        () => notifier.setColorScheme('invalid'),
        throwsA(isA<SettingsException>()),
      );
    });

    test('setThemeMode updates state and persists', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      await notifier.setThemeMode(ThemeMode.dark);
      
      final config = await container.read(themeConfigProvider.future);
      expect(config.themeMode, ThemeMode.dark);
      
      // Verify persistence
      final saved = prefs.getString('theme_mode');
      expect(saved, 'dark');
    });

    test('saveConfig updates both settings', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      const newConfig = ThemeConfigModel(
        colorSchemeId: 'cool_pink',
        themeMode: ThemeMode.system,
      );
      
      await notifier.saveConfig(newConfig);
      
      final config = await container.read(themeConfigProvider.future);
      expect(config.colorSchemeId, 'cool_pink');
      expect(config.themeMode, ThemeMode.system);
      
      // Verify both persisted
      expect(prefs.getString('color_scheme'), 'cool_pink');
      expect(prefs.getString('theme_mode'), 'system');
    });

    test('saveConfig rejects invalid color scheme', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      const invalidConfig = ThemeConfigModel(
        colorSchemeId: 'invalid',
        themeMode: ThemeMode.light,
      );
      
      expect(
        () => notifier.saveConfig(invalidConfig),
        throwsA(isA<SettingsException>()),
      );
    });

    test('state reverts on save failure', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      // Wait for initial state to load
      await container.read(themeConfigProvider.future);
      
      // Set initial valid state
      await notifier.setColorScheme('blue');
      
      // Try to set invalid state
      try {
        await notifier.setColorScheme('invalid');
        fail('Should have thrown SettingsException');
      } catch (e) {
        expect(e, isA<SettingsException>());
      }
      
      // Verify state reverted to previous valid state
      final config = await container.read(themeConfigProvider.future);
      expect(config.colorSchemeId, 'blue');
    });

    test('multiple setColorScheme calls update correctly', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      // Wait for initial state
      await container.read(themeConfigProvider.future);
      
      await notifier.setColorScheme('green');
      await notifier.setColorScheme('brown');
      await notifier.setColorScheme('aqua_green');
      
      final config = await container.read(themeConfigProvider.future);
      expect(config.colorSchemeId, 'aqua_green');
    });

    test('setColorScheme and setThemeMode work independently', () async {
      final notifier = container.read(themeConfigProvider.notifier);
      
      await notifier.setColorScheme('fancy_green');
      await notifier.setThemeMode(ThemeMode.dark);
      
      final config = await container.read(themeConfigProvider.future);
      expect(config.colorSchemeId, 'fancy_green');
      expect(config.themeMode, ThemeMode.dark);
      
      // Change only color scheme
      await notifier.setColorScheme('brown');
      
      final updatedConfig = await container.read(themeConfigProvider.future);
      expect(updatedConfig.colorSchemeId, 'brown');
      expect(updatedConfig.themeMode, ThemeMode.dark); // Should remain unchanged
    });
  });
}
