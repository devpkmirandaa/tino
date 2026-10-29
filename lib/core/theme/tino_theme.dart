import 'package:flutter/material.dart';

abstract final class TinoColors {
  static const jade = Color(0xFF246B55);
  static const lightJade = Color(0xFFABD8C5);
  static const glacialBlue = Color(0xFFC8E1ED);
  static const offWhite = Color(0xFFF5F7F6);
  static const ink = Color(0xFF16221F);
  static const softWhite = Color(0xFFEAF1EE);
}

ThemeData buildTinoLightTheme() {
  const scheme = ColorScheme.light(
    primary: TinoColors.jade,
    onPrimary: TinoColors.offWhite,
    primaryContainer: TinoColors.lightJade,
    onPrimaryContainer: TinoColors.ink,
    secondary: TinoColors.jade,
    onSecondary: TinoColors.offWhite,
    secondaryContainer: TinoColors.glacialBlue,
    onSecondaryContainer: TinoColors.ink,
    surface: TinoColors.offWhite,
    onSurface: TinoColors.ink,
    onSurfaceVariant: TinoColors.jade,
    outline: TinoColors.jade,
    outlineVariant: TinoColors.lightJade,
    surfaceContainerLow: TinoColors.softWhite,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: TinoColors.offWhite,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -1,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
    ),
    iconTheme: const IconThemeData(size: 24, color: TinoColors.jade),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TinoColors.jade,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: const BorderSide(color: TinoColors.jade),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
  );
}
