import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/core_logging_utility.dart';
import '../../app/theme/theme_registry.dart';

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
  static const String _colorSchemeKey = 'color_scheme';
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

      final parsedMode = _parseThemeMode(value);
      
      // If we got an unknown value and defaulted, clear the corrupted data
      if (parsedMode == ThemeMode.light && value != 'light' && value != 'system') {
        CoreLoggingUtility.warning(
          'SettingsRepository',
          'getThemeMode',
          'Detected invalid theme mode value: $value, clearing corrupted data',
        );
        await _clearCorruptedData(_themeKey);
      }
      
      return parsedMode;
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

  // Color scheme operations

  /// Gets the saved color scheme, defaults to 'blue' if not found or on error
  Future<String> getColorScheme() async {
    try {
      final value = _prefs.getString(_colorSchemeKey);
      CoreLoggingUtility.info(
        'SettingsRepository',
        'getColorScheme',
        'Retrieved color scheme: $value',
      );

      if (value == null) {
        CoreLoggingUtility.info(
          'SettingsRepository',
          'getColorScheme',
          'No saved color scheme found, using default (blue)',
        );
        return ThemeRegistry.defaultThemeId;
      }
      
      // Validate the theme ID
      if (!ThemeRegistry.isValidThemeId(value)) {
        CoreLoggingUtility.warning(
          'SettingsRepository',
          'getColorScheme',
          'Invalid color scheme detected: $value, clearing corrupted data and using default',
        );
        await _clearCorruptedData(_colorSchemeKey);
        return ThemeRegistry.defaultThemeId;
      }

      return value;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'getColorScheme',
        'Failed to load color scheme: $e\nStack trace: $stackTrace',
      );
      // Graceful fallback to default
      return ThemeRegistry.defaultThemeId;
    }
  }

  /// Saves the color scheme preference
  /// Validates the color scheme ID before saving
  Future<void> saveColorScheme(String colorSchemeId) async {
    try {
      // Validate the color scheme ID
      if (!ThemeRegistry.isValidThemeId(colorSchemeId)) {
        throw SettingsException('Invalid color scheme ID: $colorSchemeId');
      }

      final success = await _prefs.setString(_colorSchemeKey, colorSchemeId);
      
      if (!success) {
        throw SettingsException('SharedPreferences returned false when saving color scheme');
      }
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'saveColorScheme',
        'Saved color scheme: $colorSchemeId',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'saveColorScheme',
        'Failed to save color scheme: $e\nStack trace: $stackTrace',
      );
      throw SettingsException('Failed to save color scheme preference: ${e.toString()}');
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
    } on FormatException catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'getNavigationItemsVisibility',
        'Corrupted navigation visibility data detected: $e\nStack trace: $stackTrace',
      );
      // Clear corrupted data
      await _clearCorruptedData(_navItemsKey);
      return {};
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
    } on FormatException catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'getNavigationOrder',
        'Corrupted navigation order data detected: $e\nStack trace: $stackTrace',
      );
      // Clear corrupted data
      await _clearCorruptedData(_navOrderKey);
      return [];
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
  
  /// Clears corrupted data from storage
  /// This is called when data cannot be parsed correctly
  Future<void> _clearCorruptedData(String key) async {
    try {
      CoreLoggingUtility.warning(
        'SettingsRepository',
        '_clearCorruptedData',
        'Clearing corrupted data for key: $key',
      );
      
      await _prefs.remove(key);
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        '_clearCorruptedData',
        'Successfully cleared corrupted data for key: $key',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        '_clearCorruptedData',
        'Failed to clear corrupted data for key $key: $e\nStack trace: $stackTrace',
      );
      // Don't rethrow - this is a cleanup operation
    }
  }
  
  /// Validates storage health and returns diagnostic information
  /// Returns a map with validation results for each setting
  Future<Map<String, bool>> validateStorageHealth() async {
    final results = <String, bool>{};
    
    try {
      // Check theme mode
      try {
        final themeMode = await getThemeMode();
        results['theme_mode'] = true;
        CoreLoggingUtility.info(
          'SettingsRepository',
          'validateStorageHealth',
          'Theme mode validation passed: ${themeMode.name}',
        );
      } catch (e) {
        results['theme_mode'] = false;
        CoreLoggingUtility.error(
          'SettingsRepository',
          'validateStorageHealth',
          'Theme mode validation failed: $e',
        );
      }
      
      // Check color scheme
      try {
        final colorScheme = await getColorScheme();
        results['color_scheme'] = ThemeRegistry.isValidThemeId(colorScheme);
        CoreLoggingUtility.info(
          'SettingsRepository',
          'validateStorageHealth',
          'Color scheme validation: ${results['color_scheme']} (value: $colorScheme)',
        );
      } catch (e) {
        results['color_scheme'] = false;
        CoreLoggingUtility.error(
          'SettingsRepository',
          'validateStorageHealth',
          'Color scheme validation failed: $e',
        );
      }
      
      // Check navigation items
      try {
        final navItems = await getNavigationItemsVisibility();
        results['navigation_items'] = true;
        CoreLoggingUtility.info(
          'SettingsRepository',
          'validateStorageHealth',
          'Navigation items validation passed: ${navItems.length} items',
        );
      } catch (e) {
        results['navigation_items'] = false;
        CoreLoggingUtility.error(
          'SettingsRepository',
          'validateStorageHealth',
          'Navigation items validation failed: $e',
        );
      }
      
      // Check navigation order
      try {
        final navOrder = await getNavigationOrder();
        results['navigation_order'] = true;
        CoreLoggingUtility.info(
          'SettingsRepository',
          'validateStorageHealth',
          'Navigation order validation passed: ${navOrder.length} items',
        );
      } catch (e) {
        results['navigation_order'] = false;
        CoreLoggingUtility.error(
          'SettingsRepository',
          'validateStorageHealth',
          'Navigation order validation failed: $e',
        );
      }
      
      final allHealthy = results.values.every((v) => v);
      CoreLoggingUtility.info(
        'SettingsRepository',
        'validateStorageHealth',
        'Storage health check complete. All healthy: $allHealthy',
      );
      
      return results;
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'validateStorageHealth',
        'Storage health validation failed: $e\nStack trace: $stackTrace',
      );
      return results;
    }
  }
  
  /// Clears all settings data (useful for recovery from corrupted state)
  Future<void> clearAllSettings() async {
    try {
      CoreLoggingUtility.warning(
        'SettingsRepository',
        'clearAllSettings',
        'Clearing all settings data',
      );
      
      await Future.wait([
        _prefs.remove(_themeKey),
        _prefs.remove(_colorSchemeKey),
        _prefs.remove(_navItemsKey),
        _prefs.remove(_navOrderKey),
      ]);
      
      CoreLoggingUtility.info(
        'SettingsRepository',
        'clearAllSettings',
        'Successfully cleared all settings data',
      );
    } catch (e, stackTrace) {
      CoreLoggingUtility.error(
        'SettingsRepository',
        'clearAllSettings',
        'Failed to clear all settings: $e\nStack trace: $stackTrace',
      );
      throw SettingsException('Failed to clear settings: ${e.toString()}');
    }
  }
}
