import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/settings_repository.dart';
import '../utils/core_logging_utility.dart';

part 'theme_provider.g.dart';

/// Provider for SettingsRepository
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  throw UnimplementedError('SettingsRepository must be overridden in main.dart');
}

/// Notifier for managing theme mode state
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  late final SettingsRepository _repository;

  @override
  Future<ThemeMode> build() async {
    try {
      _repository = ref.read(settingsRepositoryProvider);
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'build',
        'Loading initial theme mode',
      );
      final themeMode = await _repository.getThemeMode();
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
        'Failed to load initial theme mode: $e\nStack trace: $stackTrace',
      );
      // Return default theme on initialization error
      return ThemeMode.light;
    }
  }

  /// Updates the theme mode and persists it to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    // Store previous state for rollback on error
    final previousState = state;
    
    try {
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'setThemeMode',
        'Setting theme mode to: ${mode.name}',
      );
      
      // Update state immediately for instant UI feedback
      state = AsyncValue.data(mode);
      
      // Persist to storage
      await _repository.saveThemeMode(mode);
      
      CoreLoggingUtility.info(
        'ThemeNotifier',
        'setThemeMode',
        'Theme mode successfully saved to storage',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'ThemeNotifier',
        'setThemeMode',
        'Failed to save theme mode: $e\nStack trace: $stackTrace',
      );
      
      // Revert to previous state on error
      state = previousState;
      
      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }
}
