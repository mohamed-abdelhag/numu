import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff845416),
      surfaceTint: Color(0xff845416),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffddbb),
      onPrimaryContainer: Color(0xff673d00),
      secondary: Color(0xff725a41),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfffeddbd),
      onSecondaryContainer: Color(0xff58432c),
      tertiary: Color(0xff56633b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffdae9b6),
      onTertiaryContainer: Color(0xff3f4b26),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f4),
      onSurface: Color(0xff211a14),
      onSurfaceVariant: Color(0xff50453a),
      outline: Color(0xff827568),
      outlineVariant: Color(0xffd4c4b5),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff372f27),
      inversePrimary: Color(0xfffaba73),
      primaryFixed: Color(0xffffddbb),
      onPrimaryFixed: Color(0xff2b1700),
      primaryFixedDim: Color(0xfffaba73),
      onPrimaryFixedVariant: Color(0xff673d00),
      secondaryFixed: Color(0xfffeddbd),
      onSecondaryFixed: Color(0xff281805),
      secondaryFixedDim: Color(0xffe0c1a3),
      onSecondaryFixedVariant: Color(0xff58432c),
      tertiaryFixed: Color(0xffdae9b6),
      onTertiaryFixed: Color(0xff141f01),
      tertiaryFixedDim: Color(0xffbecc9c),
      onTertiaryFixedVariant: Color(0xff3f4b26),
      surfaceDim: Color(0xffe5d8cc),
      surfaceBright: Color(0xfffff8f4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff1e6),
      surfaceContainer: Color(0xfffaebe0),
      surfaceContainerHigh: Color(0xfff4e6da),
      surfaceContainerHighest: Color(0xffeee0d5),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff502e00),
      surfaceTint: Color(0xff845416),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff956224),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff46321d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff81684f),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff2e3a17),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff657249),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f4),
      onSurface: Color(0xff16100a),
      onSurfaceVariant: Color(0xff3f342a),
      outline: Color(0xff5c5045),
      outlineVariant: Color(0xff786b5e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff372f27),
      inversePrimary: Color(0xfffaba73),
      primaryFixed: Color(0xff956224),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff794a0b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff81684f),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff675139),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff657249),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4d5933),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd1c4b9),
      surfaceBright: Color(0xfffff8f4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff1e6),
      surfaceContainer: Color(0xfff4e6da),
      surfaceContainerHigh: Color(0xffe8dacf),
      surfaceContainerHighest: Color(0xffddcfc4),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff422500),
      surfaceTint: Color(0xff845416),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6b3f00),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3b2814),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5b452e),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff25300d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff414e28),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f4),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff342a20),
      outlineVariant: Color(0xff53473c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff372f27),
      inversePrimary: Color(0xfffaba73),
      primaryFixed: Color(0xff6b3f00),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff4b2b00),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5b452e),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff422f19),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff414e28),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff2b3713),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc3b6ac),
      surfaceBright: Color(0xfffff8f4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffdeee3),
      surfaceContainer: Color(0xffeee0d5),
      surfaceContainerHigh: Color(0xffe0d2c7),
      surfaceContainerHighest: Color(0xffd1c4b9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffaba73),
      surfaceTint: Color(0xfffaba73),
      onPrimary: Color(0xff482900),
      primaryContainer: Color(0xff673d00),
      onPrimaryContainer: Color(0xffffddbb),
      secondary: Color(0xffe0c1a3),
      onSecondary: Color(0xff402d17),
      secondaryContainer: Color(0xff58432c),
      onSecondaryContainer: Color(0xfffeddbd),
      tertiary: Color(0xffbecc9c),
      onTertiary: Color(0xff293411),
      tertiaryContainer: Color(0xff3f4b26),
      onTertiaryContainer: Color(0xffdae9b6),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff19120c),
      onSurface: Color(0xffeee0d5),
      onSurfaceVariant: Color(0xffd4c4b5),
      outline: Color(0xff9d8e81),
      outlineVariant: Color(0xff50453a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeee0d5),
      inversePrimary: Color(0xff845416),
      primaryFixed: Color(0xffffddbb),
      onPrimaryFixed: Color(0xff2b1700),
      primaryFixedDim: Color(0xfffaba73),
      onPrimaryFixedVariant: Color(0xff673d00),
      secondaryFixed: Color(0xfffeddbd),
      onSecondaryFixed: Color(0xff281805),
      secondaryFixedDim: Color(0xffe0c1a3),
      onSecondaryFixedVariant: Color(0xff58432c),
      tertiaryFixed: Color(0xffdae9b6),
      onTertiaryFixed: Color(0xff141f01),
      tertiaryFixedDim: Color(0xffbecc9c),
      onTertiaryFixedVariant: Color(0xff3f4b26),
      surfaceDim: Color(0xff19120c),
      surfaceBright: Color(0xff403830),
      surfaceContainerLowest: Color(0xff130d07),
      surfaceContainerLow: Color(0xff211a14),
      surfaceContainer: Color(0xff251e17),
      surfaceContainerHigh: Color(0xff302921),
      surfaceContainerHighest: Color(0xff3b332c),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffd5ab),
      surfaceTint: Color(0xfffaba73),
      onPrimary: Color(0xff392000),
      primaryContainer: Color(0xffbe8543),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff7d7b8),
      onSecondary: Color(0xff34220e),
      secondaryContainer: Color(0xffa78c70),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffd3e2b0),
      onTertiary: Color(0xff1e2907),
      tertiaryContainer: Color(0xff88966a),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff19120c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffebd9ca),
      outline: Color(0xffbfafa1),
      outlineVariant: Color(0xff9d8e80),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeee0d5),
      inversePrimary: Color(0xff693e00),
      primaryFixed: Color(0xffffddbb),
      onPrimaryFixed: Color(0xff1d0e00),
      primaryFixedDim: Color(0xfffaba73),
      onPrimaryFixedVariant: Color(0xff502e00),
      secondaryFixed: Color(0xfffeddbd),
      onSecondaryFixed: Color(0xff1c0e01),
      secondaryFixedDim: Color(0xffe0c1a3),
      onSecondaryFixedVariant: Color(0xff46321d),
      tertiaryFixed: Color(0xffdae9b6),
      onTertiaryFixed: Color(0xff0b1400),
      tertiaryFixedDim: Color(0xffbecc9c),
      onTertiaryFixedVariant: Color(0xff2e3a17),
      surfaceDim: Color(0xff19120c),
      surfaceBright: Color(0xff4c433b),
      surfaceContainerLowest: Color(0xff0c0603),
      surfaceContainerLow: Color(0xff231c15),
      surfaceContainer: Color(0xff2e271f),
      surfaceContainerHigh: Color(0xff39312a),
      surfaceContainerHighest: Color(0xff453c34),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffedde),
      surfaceTint: Color(0xfffaba73),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xfff6b66f),
      onPrimaryContainer: Color(0xff150800),
      secondary: Color(0xffffedde),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffdcbd9f),
      onSecondaryContainer: Color(0xff150800),
      tertiary: Color(0xffe7f6c3),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffbac998),
      onTertiaryContainer: Color(0xff070d00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff19120c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffffedde),
      outlineVariant: Color(0xffd0c0b1),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeee0d5),
      inversePrimary: Color(0xff693e00),
      primaryFixed: Color(0xffffddbb),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xfffaba73),
      onPrimaryFixedVariant: Color(0xff1d0e00),
      secondaryFixed: Color(0xfffeddbd),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffe0c1a3),
      onSecondaryFixedVariant: Color(0xff1c0e01),
      tertiaryFixed: Color(0xffdae9b6),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffbecc9c),
      onTertiaryFixedVariant: Color(0xff0b1400),
      surfaceDim: Color(0xff19120c),
      surfaceBright: Color(0xff584e46),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff251e17),
      surfaceContainer: Color(0xff372f27),
      surfaceContainerHigh: Color(0xff423a32),
      surfaceContainerHighest: Color(0xff4e453d),
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
