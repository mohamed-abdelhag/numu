import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/core_logging_utility.dart';

/// Exception thrown when settings operations fail
class SettingsException implements Exception {
  final String message;
  SettingsException(this.message);

  @override
  String toString() => 'SettingsException: $message';
}

/// Repository for managing app settings using SharedPreferences
class SettingsRepository {
  final SharedPreferences _prefs;

  // Storage keys
  static const String _themeKey = 'theme_mode';
  static const String _navItemsKey = 'navigation_items';
  static const String _navOrderKey = 'navigation_order';

  SettingsRepository(this._prefs);

  // Theme operations

  /// Gets the saved theme mode, defaults to light if not found or on error
  Future<ThemeMode> getThemeMode() async {
    try {
      final value = _prefs.getString(_themeKey);
      CoreLoggingUtility.info(
        'SettingsRepository',
        'getThemeMode',
        'Retrieved theme mode: $value',
      );

      if (value == null) {
        CoreLoggingUtility.info(
          'SettingsRepository',
          'getThemeMode',
          'No saved theme mode found, using default (light)',
        );
        return ThemeMode.light;
      }

      return _parseThemeMode(value);
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'getThemeMode',
        'Failed to load theme: $e\nStack trace: $stackTrace',
      );
      // Graceful fallback to default
      return ThemeMode.light;
    }
  }

  /// Saves the theme mode preference
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final value = mode.name;
      final success = await _prefs.setString(_themeKey, value);
      
      if (!success) {
        throw SettingsException('SharedPreferences returned false when saving theme');
      }
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'saveThemeMode',
        'Saved theme mode: $value',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'saveThemeMode',
        'Failed to save theme: $e\nStack trace: $stackTrace',
      );
      throw SettingsException('Failed to save theme preference: ${e.toString()}');
    }
  }

  // Navigation operations

  /// Gets the navigation items visibility map
  /// Returns empty map if not found or on error
  Future<Map<String, bool>> getNavigationItemsVisibility() async {
    try {
      final value = _prefs.getString(_navItemsKey);
      
      if (value == null) {
        CoreLoggingUtility.info(
          'SettingsRepository',
          'getNavigationItemsVisibility',
          'No saved navigation visibility found, using defaults',
        );
        return {};
      }

      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final result = decoded.map((key, value) => MapEntry(key, value as bool));
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'getNavigationItemsVisibility',
        'Retrieved navigation items visibility: ${result.length} items',
      );
      
      return result;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'getNavigationItemsVisibility',
        'Failed to load navigation items visibility: $e\nStack trace: $stackTrace',
      );
      // Graceful fallback to empty map (will use defaults)
      return {};
    }
  }

  /// Saves the navigation items visibility map
  Future<void> saveNavigationItemsVisibility(Map<String, bool> items) async {
    try {
      final value = jsonEncode(items);
      final success = await _prefs.setString(_navItemsKey, value);
      
      if (!success) {
        throw SettingsException('SharedPreferences returned false when saving navigation visibility');
      }
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'saveNavigationItemsVisibility',
        'Saved navigation items visibility: ${items.length} items',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'saveNavigationItemsVisibility',
        'Failed to save navigation items visibility: $e\nStack trace: $stackTrace',
      );
      throw SettingsException('Failed to save navigation items visibility: ${e.toString()}');
    }
  }

  /// Gets the navigation order list
  /// Returns empty list if not found or on error
  Future<List<String>> getNavigationOrder() async {
    try {
      final value = _prefs.getString(_navOrderKey);
      
      if (value == null) {
        CoreLoggingUtility.info(
          'SettingsRepository',
          'getNavigationOrder',
          'No saved navigation order found, using defaults',
        );
        return [];
      }

      final decoded = jsonDecode(value) as List<dynamic>;
      final result = decoded.map((item) => item as String).toList();
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'getNavigationOrder',
        'Retrieved navigation order: ${result.length} items',
      );
      
      return result;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'getNavigationOrder',
        'Failed to load navigation order: $e\nStack trace: $stackTrace',
      );
      // Graceful fallback to empty list (will use defaults)
      return [];
    }
  }

  /// Saves the navigation order list
  Future<void> saveNavigationOrder(List<String> order) async {
    try {
      final value = jsonEncode(order);
      final success = await _prefs.setString(_navOrderKey, value);
      
      if (!success) {
        throw SettingsException('SharedPreferences returned false when saving navigation order');
      }
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'saveNavigationOrder',
        'Saved navigation order: ${order.length} items',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'saveNavigationOrder',
        'Failed to save navigation order: $e\nStack trace: $stackTrace',
      );
      throw SettingsException('Failed to save navigation order: ${e.toString()}');
    }
  }

  /// Parses theme mode string to ThemeMode enum
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        CoreLoggingUtility.warning(
          'SettingsRepository',
          '_parseThemeMode',
          'Unknown theme mode: $value, defaulting to light',
        );
        return ThemeMode.light;
    }
  }
}
