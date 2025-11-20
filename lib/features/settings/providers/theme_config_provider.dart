import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/settings_repository.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/core_logging_utility.dart';
import '../../../app/theme/theme_registry.dart';
import '../models/theme_config.dart';

part 'theme_config_provider.g.dart';

/// Notifier for managing theme configuration state
@riverpod
class ThemeConfig extends _$ThemeConfig {
  late final SettingsRepository _repository;

  @override
  Future<ThemeConfigModel> build() async {
    try {
      _repository = ref.read(settingsRepositoryProvider);
      CoreLoggingUtility.info(
        'ThemeConfig',
        'build',
        'Loading initial theme configuration',
      );

      // Load both color scheme and theme mode from repository
      final colorSchemeId = await _repository.getColorScheme();
      final themeMode = await _repository.getThemeMode();

      final config = ThemeConfigModel(
        colorSchemeId: colorSchemeId,
        themeMode: themeMode,
      );

      CoreLoggingUtility.info(
        'ThemeConfig',
        'build',
        'Successfully loaded theme configuration: $config',
      );

      return config;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeConfig',
        'build',
        'Failed to load theme configuration: $e\nStack trace: $stackTrace',
      );
      // Return default configuration on initialization error
      return ThemeConfigModel(
        colorSchemeId: ThemeRegistry.defaultThemeId,
        themeMode: ThemeMode.light,
      );
    }
  }

  /// Updates the color scheme and persists it to storage
  Future<void> setColorScheme(String colorSchemeId) async {
    // Store previous state for rollback on error
    final previousState = state;

    try {
      CoreLoggingUtility.info(
        'ThemeConfig',
        'setColorScheme',
        'Setting color scheme to: $colorSchemeId',
      );

      // Validate the color scheme ID
      if (!ThemeRegistry.isValidThemeId(colorSchemeId)) {
        throw SettingsException('Invalid color scheme ID: $colorSchemeId');
      }

      // Get current config
      final currentConfig = await future;

      // Update state immediately for instant UI feedback
      final newConfig = currentConfig.copyWith(colorSchemeId: colorSchemeId);
      state = AsyncValue.data(newConfig);

      // Persist to storage
      await _repository.saveColorScheme(colorSchemeId);

      CoreLoggingUtility.info(
        'ThemeConfig',
        'setColorScheme',
        'Color scheme successfully saved to storage',
      );

      // Invalidate theme provider to trigger rebuild with new theme
      ref.invalidate(themeProvider);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeConfig',
        'setColorScheme',
        'Failed to save color scheme: $e\nStack trace: $stackTrace',
      );

      // Revert to previous state on error
      state = previousState;

      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }

  /// Updates the theme mode and persists it to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    // Store previous state for rollback on error
    final previousState = state;

    try {
      CoreLoggingUtility.info(
        'ThemeConfig',
        'setThemeMode',
        'Setting theme mode to: ${mode.name}',
      );

      // Get current config
      final currentConfig = await future;

      // Update state immediately for instant UI feedback
      final newConfig = currentConfig.copyWith(themeMode: mode);
      state = AsyncValue.data(newConfig);

      // Persist to storage
      await _repository.saveThemeMode(mode);

      CoreLoggingUtility.info(
        'ThemeConfig',
        'setThemeMode',
        'Theme mode successfully saved to storage',
      );

      // Invalidate theme provider to trigger rebuild with new mode
      ref.invalidate(themeProvider);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeConfig',
        'setThemeMode',
        'Failed to save theme mode: $e\nStack trace: $stackTrace',
      );

      // Revert to previous state on error
      state = previousState;

      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }

  /// Saves the complete theme configuration
  Future<void> saveConfig(ThemeConfigModel config) async {
    // Store previous state for rollback on error
    final previousState = state;

    try {
      CoreLoggingUtility.info(
        'ThemeConfig',
        'saveConfig',
        'Saving complete theme configuration: $config',
      );

      // Validate the color scheme ID
      if (!ThemeRegistry.isValidThemeId(config.colorSchemeId)) {
        throw SettingsException('Invalid color scheme ID: ${config.colorSchemeId}');
      }

      // Update state immediately for instant UI feedback
      state = AsyncValue.data(config);

      // Persist both settings to storage
      await _repository.saveColorScheme(config.colorSchemeId);
      await _repository.saveThemeMode(config.themeMode);

      CoreLoggingUtility.info(
        'ThemeConfig',
        'saveConfig',
        'Theme configuration successfully saved to storage',
      );

      // Invalidate theme provider to trigger rebuild with new configuration
      ref.invalidate(themeProvider);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeConfig',
        'saveConfig',
        'Failed to save theme configuration: $e\nStack trace: $stackTrace',
      );

      // Revert to previous state on error
      state = previousState;

      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }
}
