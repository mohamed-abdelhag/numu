import 'package:flutter/material.dart';

/// Model representing the complete theme configuration
/// including color scheme and theme mode preferences
class ThemeConfigModel {
  final String colorSchemeId;
  final ThemeMode themeMode;

  const ThemeConfigModel({
    required this.colorSchemeId,
    required this.themeMode,
  });

  /// Serializes the theme configuration to JSON
  Map<String, dynamic> toJson() => {
        'colorSchemeId': colorSchemeId,
        'themeMode': themeMode.name,
      };

  /// Deserializes the theme configuration from JSON
  factory ThemeConfigModel.fromJson(Map<String, dynamic> json) {
    return ThemeConfigModel(
      colorSchemeId: json['colorSchemeId'] as String,
      themeMode: _parseThemeMode(json['themeMode'] as String),
    );
  }

  /// Creates a copy of this theme configuration with optional field updates
  ThemeConfigModel copyWith({
    String? colorSchemeId,
    ThemeMode? themeMode,
  }) {
    return ThemeConfigModel(
      colorSchemeId: colorSchemeId ?? this.colorSchemeId,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// Parses a string value to ThemeMode enum
  /// Defaults to light mode if the value is invalid
  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfigModel &&
          runtimeType == other.runtimeType &&
          colorSchemeId == other.colorSchemeId &&
          themeMode == other.themeMode;

  @override
  int get hashCode => colorSchemeId.hashCode ^ themeMode.hashCode;

  @override
  String toString() =>
      'ThemeConfigModel(colorSchemeId: $colorSchemeId, themeMode: ${themeMode.name})';
}
