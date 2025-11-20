import 'package:flutter/material.dart';
import 'blue_color_theme.dart' as blue;
import 'green_color_theme.dart' as green;
import 'fancy_green_color_theme.dart' as fancy_green;
import 'auqa_green_color_theme.dart' as aqua_green;
import 'brown_color_theme.dart' as brown;
import 'cool_pink_color_theme.dart' as cool_pink;

/// Information about a theme including its builder and metadata
class ThemeInfo {
  final String id;
  final String displayName;
  final ThemeData Function(TextTheme, Brightness) themeBuilder;
  final Color previewColor;

  const ThemeInfo({
    required this.id,
    required this.displayName,
    required this.themeBuilder,
    required this.previewColor,
  });
}

/// Central registry for all available Material themes
class ThemeRegistry {
  ThemeRegistry._();

  /// Map of all registered themes by their ID
  static final Map<String, ThemeInfo> _themes = {
    'blue': ThemeInfo(
      id: 'blue',
      displayName: 'Blue',
      themeBuilder: (textTheme, brightness) {
        final theme = blue.MaterialTheme(textTheme);
        return brightness == Brightness.light ? theme.light() : theme.dark();
      },
      previewColor: const Color(0xff575992),
    ),
    'green': ThemeInfo(
      id: 'green',
      displayName: 'Green',
      themeBuilder: (textTheme, brightness) {
        final theme = green.MaterialTheme(textTheme);
        return brightness == Brightness.light ? theme.light() : theme.dark();
      },
      previewColor: const Color(0xff36693e),
    ),
    'fancy_green': ThemeInfo(
      id: 'fancy_green',
      displayName: 'Fancy Green',
      themeBuilder: (textTheme, brightness) {
        final theme = fancy_green.MaterialTheme(textTheme);
        return brightness == Brightness.light ? theme.light() : theme.dark();
      },
      previewColor: const Color(0xff336940),
    ),
    'aqua_green': ThemeInfo(
      id: 'aqua_green',
      displayName: 'Aqua Green',
      themeBuilder: (textTheme, brightness) {
        final theme = aqua_green.MaterialTheme(textTheme);
        return brightness == Brightness.light ? theme.light() : theme.dark();
      },
      previewColor: const Color(0xff156b54),
    ),
    'brown': ThemeInfo(
      id: 'brown',
      displayName: 'Brown',
      themeBuilder: (textTheme, brightness) {
        final theme = brown.MaterialTheme(textTheme);
        return brightness == Brightness.light ? theme.light() : theme.dark();
      },
      previewColor: const Color(0xff845416),
    ),
    'cool_pink': ThemeInfo(
      id: 'cool_pink',
      displayName: 'Cool Pink',
      themeBuilder: (textTheme, brightness) {
        final theme = cool_pink.MaterialTheme(textTheme);
        return brightness == Brightness.light ? theme.light() : theme.dark();
      },
      previewColor: const Color(0xff844c72),
    ),
  };

  /// Gets a theme by its ID
  /// Returns default theme if the theme ID is not found (graceful fallback)
  static ThemeInfo getTheme(String id) {
    final theme = _themes[id];
    if (theme == null) {
      // Graceful fallback to default theme instead of throwing
      return _themes[defaultThemeId]!;
    }
    return theme;
  }
  
  /// Gets a theme by its ID with strict validation
  /// Throws ArgumentError if the theme ID is not found
  static ThemeInfo getThemeStrict(String id) {
    final theme = _themes[id];
    if (theme == null) {
      throw ArgumentError('Theme with id "$id" not found in registry');
    }
    return theme;
  }

  /// Gets all registered themes as a list
  static List<ThemeInfo> getAllThemes() {
    return _themes.values.toList();
  }

  /// Checks if a theme ID is valid and registered
  static bool isValidThemeId(String id) {
    return _themes.containsKey(id);
  }

  /// Gets the default theme ID
  static String get defaultThemeId => 'blue';
}
