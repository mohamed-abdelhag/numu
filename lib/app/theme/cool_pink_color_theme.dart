import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff844c72),
      surfaceTint: Color(0xff844c72),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffd8ee),
      onPrimaryContainer: Color(0xff69345a),
      secondary: Color(0xff705766),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfffadaeb),
      onSecondaryContainer: Color(0xff57404e),
      tertiary: Color(0xff81533f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdbcd),
      onTertiaryContainer: Color(0xff653c2a),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f9),
      onSurface: Color(0xff201a1d),
      onSurfaceVariant: Color(0xff4f444a),
      outline: Color(0xff81737a),
      outlineVariant: Color(0xffd3c2ca),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362e32),
      inversePrimary: Color(0xfff7b1de),
      primaryFixed: Color(0xffffd8ee),
      onPrimaryFixed: Color(0xff36072c),
      primaryFixedDim: Color(0xfff7b1de),
      onPrimaryFixedVariant: Color(0xff69345a),
      secondaryFixed: Color(0xfffadaeb),
      onSecondaryFixed: Color(0xff281622),
      secondaryFixedDim: Color(0xffddbecf),
      onSecondaryFixedVariant: Color(0xff57404e),
      tertiaryFixed: Color(0xffffdbcd),
      onTertiaryFixed: Color(0xff321304),
      tertiaryFixedDim: Color(0xfff4b9a0),
      onTertiaryFixedVariant: Color(0xff653c2a),
      surfaceDim: Color(0xffe4d7dc),
      surfaceBright: Color(0xfffff8f9),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffef0f5),
      surfaceContainer: Color(0xfff8eaf0),
      surfaceContainerHigh: Color(0xfff2e5ea),
      surfaceContainerHighest: Color(0xffeddfe4),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff562448),
      surfaceTint: Color(0xff844c72),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff955a81),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff45303d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff7f6675),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff522c1b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff91624d),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f9),
      onSurface: Color(0xff160f13),
      onSurfaceVariant: Color(0xff3e3339),
      outline: Color(0xff5b4f55),
      outlineVariant: Color(0xff776970),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362e32),
      inversePrimary: Color(0xfff7b1de),
      primaryFixed: Color(0xff955a81),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff794268),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff7f6675),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff664e5c),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff91624d),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff764a36),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd0c3c8),
      surfaceBright: Color(0xfffff8f9),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffef0f5),
      surfaceContainer: Color(0xfff2e5ea),
      surfaceContainerHigh: Color(0xffe7d9df),
      surfaceContainerHighest: Color(0xffdbced3),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4a1a3d),
      surfaceTint: Color(0xff844c72),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6c375c),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3a2633),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff594250),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff462312),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff683f2c),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f9),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff33292f),
      outlineVariant: Color(0xff52464c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362e32),
      inversePrimary: Color(0xfff7b1de),
      primaryFixed: Color(0xff6c375c),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff522044),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff594250),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff412c3a),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff683f2c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4e2918),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2b5bb),
      surfaceBright: Color(0xfffff8f9),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbedf3),
      surfaceContainer: Color(0xffeddfe4),
      surfaceContainerHigh: Color(0xffded1d6),
      surfaceContainerHighest: Color(0xffd0c3c8),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff7b1de),
      surfaceTint: Color(0xfff7b1de),
      onPrimary: Color(0xff4f1e42),
      primaryContainer: Color(0xff69345a),
      onPrimaryContainer: Color(0xffffd8ee),
      secondary: Color(0xffddbecf),
      onSecondary: Color(0xff3f2a37),
      secondaryContainer: Color(0xff57404e),
      onSecondaryContainer: Color(0xfffadaeb),
      tertiary: Color(0xfff4b9a0),
      onTertiary: Color(0xff4b2715),
      tertiaryContainer: Color(0xff653c2a),
      onTertiaryContainer: Color(0xffffdbcd),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff181215),
      onSurface: Color(0xffeddfe4),
      onSurfaceVariant: Color(0xffd3c2ca),
      outline: Color(0xff9b8d94),
      outlineVariant: Color(0xff4f444a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeddfe4),
      inversePrimary: Color(0xff844c72),
      primaryFixed: Color(0xffffd8ee),
      onPrimaryFixed: Color(0xff36072c),
      primaryFixedDim: Color(0xfff7b1de),
      onPrimaryFixedVariant: Color(0xff69345a),
      secondaryFixed: Color(0xfffadaeb),
      onSecondaryFixed: Color(0xff281622),
      secondaryFixedDim: Color(0xffddbecf),
      onSecondaryFixedVariant: Color(0xff57404e),
      tertiaryFixed: Color(0xffffdbcd),
      onTertiaryFixed: Color(0xff321304),
      tertiaryFixedDim: Color(0xfff4b9a0),
      onTertiaryFixedVariant: Color(0xff653c2a),
      surfaceDim: Color(0xff181215),
      surfaceBright: Color(0xff3f373b),
      surfaceContainerLowest: Color(0xff130c10),
      surfaceContainerLow: Color(0xff201a1d),
      surfaceContainer: Color(0xff251e22),
      surfaceContainerHigh: Color(0xff2f282c),
      surfaceContainerHighest: Color(0xff3b3337),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffcfeb),
      surfaceTint: Color(0xfff7b1de),
      onPrimary: Color(0xff421337),
      primaryContainer: Color(0xffbc7da6),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff4d3e5),
      onSecondary: Color(0xff33202c),
      secondaryContainer: Color(0xffa58999),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd3c1),
      onTertiary: Color(0xff3e1c0c),
      tertiaryContainer: Color(0xffb9856e),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff181215),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe9d8df),
      outline: Color(0xffbdaeb5),
      outlineVariant: Color(0xff9b8c93),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeddfe4),
      inversePrimary: Color(0xff6b355b),
      primaryFixed: Color(0xffffd8ee),
      onPrimaryFixed: Color(0xff280020),
      primaryFixedDim: Color(0xfff7b1de),
      onPrimaryFixedVariant: Color(0xff562448),
      secondaryFixed: Color(0xfffadaeb),
      onSecondaryFixed: Color(0xff1d0b17),
      secondaryFixedDim: Color(0xffddbecf),
      onSecondaryFixedVariant: Color(0xff45303d),
      tertiaryFixed: Color(0xffffdbcd),
      onTertiaryFixed: Color(0xff240800),
      tertiaryFixedDim: Color(0xfff4b9a0),
      onTertiaryFixedVariant: Color(0xff522c1b),
      surfaceDim: Color(0xff181215),
      surfaceBright: Color(0xff4b4246),
      surfaceContainerLowest: Color(0xff0b0609),
      surfaceContainerLow: Color(0xff231c1f),
      surfaceContainer: Color(0xff2d262a),
      surfaceContainerHigh: Color(0xff383035),
      surfaceContainerHighest: Color(0xff443b40),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffebf4),
      surfaceTint: Color(0xfff7b1de),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xfff3aeda),
      onPrimaryContainer: Color(0xff1e0017),
      secondary: Color(0xffffebf4),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffd9bacb),
      onSecondaryContainer: Color(0xff160611),
      tertiary: Color(0xffffece5),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff0b69c),
      onTertiaryContainer: Color(0xff1b0500),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff181215),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfffdebf3),
      outlineVariant: Color(0xffcfbec6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeddfe4),
      inversePrimary: Color(0xff6b355b),
      primaryFixed: Color(0xffffd8ee),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xfff7b1de),
      onPrimaryFixedVariant: Color(0xff280020),
      secondaryFixed: Color(0xfffadaeb),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffddbecf),
      onSecondaryFixedVariant: Color(0xff1d0b17),
      tertiaryFixed: Color(0xffffdbcd),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff4b9a0),
      onTertiaryFixedVariant: Color(0xff240800),
      surfaceDim: Color(0xff181215),
      surfaceBright: Color(0xff574e52),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff251e22),
      surfaceContainer: Color(0xff362e32),
      surfaceContainerHigh: Color(0xff41393d),
      surfaceContainerHighest: Color(0xff4d4449),
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
     scaffoldBackgroundColor: colorScheme.background,
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
