import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff336940),
      surfaceTint: Color(0xff336940),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffb5f1bc),
      onPrimaryContainer: Color(0xff19512a),
      secondary: Color(0xff506351),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffd3e8d2),
      onSecondaryContainer: Color(0xff394b3b),
      tertiary: Color(0xff39656d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffbdeaf4),
      onTertiaryContainer: Color(0xff204d55),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff6fbf2),
      onSurface: Color(0xff181d18),
      onSurfaceVariant: Color(0xff414941),
      outline: Color(0xff727970),
      outlineVariant: Color(0xffc1c9be),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d322c),
      inversePrimary: Color(0xff9ad4a1),
      primaryFixed: Color(0xffb5f1bc),
      onPrimaryFixed: Color(0xff00210a),
      primaryFixedDim: Color(0xff9ad4a1),
      onPrimaryFixedVariant: Color(0xff19512a),
      secondaryFixed: Color(0xffd3e8d2),
      onSecondaryFixed: Color(0xff0e1f12),
      secondaryFixedDim: Color(0xffb7ccb6),
      onSecondaryFixedVariant: Color(0xff394b3b),
      tertiaryFixed: Color(0xffbdeaf4),
      onTertiaryFixed: Color(0xff001f25),
      tertiaryFixedDim: Color(0xffa1ced8),
      onTertiaryFixedVariant: Color(0xff204d55),
      surfaceDim: Color(0xffd7dbd3),
      surfaceBright: Color(0xfff6fbf2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f5ed),
      surfaceContainer: Color(0xffebefe7),
      surfaceContainerHigh: Color(0xffe5eae1),
      surfaceContainerHighest: Color(0xffdfe4dc),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff023f1b),
      surfaceTint: Color(0xff336940),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff42794d),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff293a2b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5f7260),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff093c44),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff48747c),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff6fbf2),
      onSurface: Color(0xff0e120e),
      onSurfaceVariant: Color(0xff313831),
      outline: Color(0xff4d544c),
      outlineVariant: Color(0xff676f66),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d322c),
      inversePrimary: Color(0xff9ad4a1),
      primaryFixed: Color(0xff42794d),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff295f37),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5f7260),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff475948),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff48747c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff2f5b63),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc3c8c0),
      surfaceBright: Color(0xfff6fbf2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f5ed),
      surfaceContainer: Color(0xffe5eae1),
      surfaceContainerHigh: Color(0xffdaded6),
      surfaceContainerHighest: Color(0xffced3cb),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003414),
      surfaceTint: Color(0xff336940),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff1c532c),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1f3021),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff3b4e3d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003139),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff224f58),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff6fbf2),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff272e27),
      outlineVariant: Color(0xff444b43),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d322c),
      inversePrimary: Color(0xff9ad4a1),
      primaryFixed: Color(0xff1c532c),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003c18),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff3b4e3d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff253727),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff224f58),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff033840),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb5bab3),
      surfaceBright: Color(0xfff6fbf2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeef2ea),
      surfaceContainer: Color(0xffdfe4dc),
      surfaceContainerHigh: Color(0xffd1d6ce),
      surfaceContainerHighest: Color(0xffc3c8c0),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff9ad4a1),
      surfaceTint: Color(0xff9ad4a1),
      onPrimary: Color(0xff003917),
      primaryContainer: Color(0xff19512a),
      onPrimaryContainer: Color(0xffb5f1bc),
      secondary: Color(0xffb7ccb6),
      onSecondary: Color(0xff233425),
      secondaryContainer: Color(0xff394b3b),
      onSecondaryContainer: Color(0xffd3e8d2),
      tertiary: Color(0xffa1ced8),
      onTertiary: Color(0xff00363e),
      tertiaryContainer: Color(0xff204d55),
      onTertiaryContainer: Color(0xffbdeaf4),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff101510),
      onSurface: Color(0xffdfe4dc),
      onSurfaceVariant: Color(0xffc1c9be),
      outline: Color(0xff8b9389),
      outlineVariant: Color(0xff414941),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dc),
      inversePrimary: Color(0xff336940),
      primaryFixed: Color(0xffb5f1bc),
      onPrimaryFixed: Color(0xff00210a),
      primaryFixedDim: Color(0xff9ad4a1),
      onPrimaryFixedVariant: Color(0xff19512a),
      secondaryFixed: Color(0xffd3e8d2),
      onSecondaryFixed: Color(0xff0e1f12),
      secondaryFixedDim: Color(0xffb7ccb6),
      onSecondaryFixedVariant: Color(0xff394b3b),
      tertiaryFixed: Color(0xffbdeaf4),
      onTertiaryFixed: Color(0xff001f25),
      tertiaryFixedDim: Color(0xffa1ced8),
      onTertiaryFixedVariant: Color(0xff204d55),
      surfaceDim: Color(0xff101510),
      surfaceBright: Color(0xff363a35),
      surfaceContainerLowest: Color(0xff0b0f0b),
      surfaceContainerLow: Color(0xff181d18),
      surfaceContainer: Color(0xff1c211c),
      surfaceContainerHigh: Color(0xff262b26),
      surfaceContainerHighest: Color(0xff313631),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffafebb6),
      surfaceTint: Color(0xff9ad4a1),
      onPrimary: Color(0xff002d10),
      primaryContainer: Color(0xff659d6f),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffcde2cc),
      onSecondary: Color(0xff18291b),
      secondaryContainer: Color(0xff829682),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffb7e4ee),
      onTertiary: Color(0xff002a31),
      tertiaryContainer: Color(0xff6c98a1),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff101510),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd7dfd4),
      outline: Color(0xffacb4aa),
      outlineVariant: Color(0xff8b9289),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dc),
      inversePrimary: Color(0xff1b522b),
      primaryFixed: Color(0xffb5f1bc),
      onPrimaryFixed: Color(0xff001505),
      primaryFixedDim: Color(0xff9ad4a1),
      onPrimaryFixedVariant: Color(0xff023f1b),
      secondaryFixed: Color(0xffd3e8d2),
      onSecondaryFixed: Color(0xff051408),
      secondaryFixedDim: Color(0xffb7ccb6),
      onSecondaryFixedVariant: Color(0xff293a2b),
      tertiaryFixed: Color(0xffbdeaf4),
      onTertiaryFixed: Color(0xff001418),
      tertiaryFixedDim: Color(0xffa1ced8),
      onTertiaryFixedVariant: Color(0xff093c44),
      surfaceDim: Color(0xff101510),
      surfaceBright: Color(0xff414640),
      surfaceContainerLowest: Color(0xff050805),
      surfaceContainerLow: Color(0xff1a1f1a),
      surfaceContainer: Color(0xff242924),
      surfaceContainerHigh: Color(0xff2f342e),
      surfaceContainerHighest: Color(0xff3a3f39),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc2ffc9),
      surfaceTint: Color(0xff9ad4a1),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff96d09e),
      onPrimaryContainer: Color(0xff000f03),
      secondary: Color(0xffe1f6df),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb3c8b3),
      onSecondaryContainer: Color(0xff010e04),
      tertiary: Color(0xffd1f7ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff9ecad4),
      onTertiaryContainer: Color(0xff000d11),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff101510),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffebf2e7),
      outlineVariant: Color(0xffbdc5ba),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dc),
      inversePrimary: Color(0xff1b522b),
      primaryFixed: Color(0xffb5f1bc),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff9ad4a1),
      onPrimaryFixedVariant: Color(0xff001505),
      secondaryFixed: Color(0xffd3e8d2),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb7ccb6),
      onSecondaryFixedVariant: Color(0xff051408),
      tertiaryFixed: Color(0xffbdeaf4),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa1ced8),
      onTertiaryFixedVariant: Color(0xff001418),
      surfaceDim: Color(0xff101510),
      surfaceBright: Color(0xff4c514b),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1c211c),
      surfaceContainer: Color(0xff2d322c),
      surfaceContainerHigh: Color(0xff383d37),
      surfaceContainerHighest: Color(0xff434842),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
