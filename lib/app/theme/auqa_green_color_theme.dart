import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff156b54),
      surfaceTint: Color(0xff156b54),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffa4f2d5),
      onPrimaryContainer: Color(0xff00513e),
      secondary: Color(0xff4c635a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffcee9dc),
      onSecondaryContainer: Color(0xff344c43),
      tertiary: Color(0xff406376),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc3e8fe),
      onTertiaryContainer: Color(0xff274b5d),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff171d1a),
      onSurfaceVariant: Color(0xff3f4944),
      outline: Color(0xff707974),
      outlineVariant: Color(0xffbfc9c3),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff88d6ba),
      primaryFixed: Color(0xffa4f2d5),
      onPrimaryFixed: Color(0xff002117),
      primaryFixedDim: Color(0xff88d6ba),
      onPrimaryFixedVariant: Color(0xff00513e),
      secondaryFixed: Color(0xffcee9dc),
      onSecondaryFixed: Color(0xff082018),
      secondaryFixedDim: Color(0xffb2ccc0),
      onSecondaryFixedVariant: Color(0xff344c43),
      tertiaryFixed: Color(0xffc3e8fe),
      onTertiaryFixed: Color(0xff001e2b),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff274b5d),
      surfaceDim: Color(0xffd5dbd7),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f0),
      surfaceContainer: Color(0xffe9efeb),
      surfaceContainerHigh: Color(0xffe4eae5),
      surfaceContainerHighest: Color(0xffdee4df),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003e2f),
      surfaceTint: Color(0xff156b54),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2a7a62),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff243b32),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5a7268),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff143a4c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff4f7285),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff0c1210),
      onSurfaceVariant: Color(0xff2f3834),
      outline: Color(0xff4b5550),
      outlineVariant: Color(0xff666f6a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff88d6ba),
      primaryFixed: Color(0xff2a7a62),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff00614b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5a7268),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff425a50),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff4f7285),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff36596c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c8c3),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f0),
      surfaceContainer: Color(0xffe4eae5),
      surfaceContainerHigh: Color(0xffd8deda),
      surfaceContainerHighest: Color(0xffcdd3cf),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003326),
      surfaceTint: Color(0xff156b54),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff005440),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff193028),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff374e45),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff053041),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff2a4d5f),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2a),
      outlineVariant: Color(0xff424b47),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff88d6ba),
      primaryFixed: Color(0xff005440),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003a2c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff374e45),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff20372f),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff2a4d5f),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff0f3748),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb4bab6),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffecf2ed),
      surfaceContainer: Color(0xffdee4df),
      surfaceContainerHigh: Color(0xffd0d6d1),
      surfaceContainerHighest: Color(0xffc2c8c3),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff88d6ba),
      surfaceTint: Color(0xff88d6ba),
      onPrimary: Color(0xff00382a),
      primaryContainer: Color(0xff00513e),
      onPrimaryContainer: Color(0xffa4f2d5),
      secondary: Color(0xffb2ccc0),
      onSecondary: Color(0xff1e352d),
      secondaryContainer: Color(0xff344c43),
      onSecondaryContainer: Color(0xffcee9dc),
      tertiary: Color(0xffa7cce1),
      onTertiary: Color(0xff0c3445),
      tertiaryContainer: Color(0xff274b5d),
      onTertiaryContainer: Color(0xffc3e8fe),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffdee4df),
      onSurfaceVariant: Color(0xffbfc9c3),
      outline: Color(0xff89938e),
      outlineVariant: Color(0xff3f4944),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff156b54),
      primaryFixed: Color(0xffa4f2d5),
      onPrimaryFixed: Color(0xff002117),
      primaryFixedDim: Color(0xff88d6ba),
      onPrimaryFixedVariant: Color(0xff00513e),
      secondaryFixed: Color(0xffcee9dc),
      onSecondaryFixed: Color(0xff082018),
      secondaryFixedDim: Color(0xffb2ccc0),
      onSecondaryFixedVariant: Color(0xff344c43),
      tertiaryFixed: Color(0xffc3e8fe),
      onTertiaryFixed: Color(0xff001e2b),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff274b5d),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff343b37),
      surfaceContainerLowest: Color(0xff090f0d),
      surfaceContainerLow: Color(0xff171d1a),
      surfaceContainer: Color(0xff1b211e),
      surfaceContainerHigh: Color(0xff252b28),
      surfaceContainerHighest: Color(0xff303633),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff9eeccf),
      surfaceTint: Color(0xff88d6ba),
      onPrimary: Color(0xff002c20),
      primaryContainer: Color(0xff529f85),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc8e2d6),
      onSecondary: Color(0xff132a22),
      secondaryContainer: Color(0xff7d968b),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbde1f8),
      onTertiary: Color(0xff002939),
      tertiaryContainer: Color(0xff7295aa),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd5dfd9),
      outline: Color(0xffaab4af),
      outlineVariant: Color(0xff89938d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff00523f),
      primaryFixed: Color(0xffa4f2d5),
      onPrimaryFixed: Color(0xff00150e),
      primaryFixedDim: Color(0xff88d6ba),
      onPrimaryFixedVariant: Color(0xff003e2f),
      secondaryFixed: Color(0xffcee9dc),
      onSecondaryFixed: Color(0xff00150e),
      secondaryFixedDim: Color(0xffb2ccc0),
      onSecondaryFixedVariant: Color(0xff243b32),
      tertiaryFixed: Color(0xffc3e8fe),
      onTertiaryFixed: Color(0xff00131d),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff143a4c),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff404643),
      surfaceContainerLowest: Color(0xff040806),
      surfaceContainerLow: Color(0xff191f1c),
      surfaceContainer: Color(0xff232926),
      surfaceContainerHigh: Color(0xff2e3431),
      surfaceContainerHighest: Color(0xff393f3c),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb6ffe3),
      surfaceTint: Color(0xff88d6ba),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff85d2b6),
      onPrimaryContainer: Color(0xff000e09),
      secondary: Color(0xffdbf6e9),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffaec8bd),
      onSecondaryContainer: Color(0xff000e09),
      tertiary: Color(0xffe0f3ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa4c8dd),
      onTertiaryContainer: Color(0xff000d15),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f2ec),
      outlineVariant: Color(0xffbbc5bf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff00523f),
      primaryFixed: Color(0xffa4f2d5),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff88d6ba),
      onPrimaryFixedVariant: Color(0xff00150e),
      secondaryFixed: Color(0xffcee9dc),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb2ccc0),
      onSecondaryFixedVariant: Color(0xff00150e),
      tertiaryFixed: Color(0xffc3e8fe),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff00131d),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff4b514e),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b211e),
      surfaceContainer: Color(0xff2c322f),
      surfaceContainerHigh: Color(0xff373d3a),
      surfaceContainerHighest: Color(0xff424845),
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
