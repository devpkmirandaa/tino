import 'package:flutter/material.dart';

/// Paleta oficial (docs/marca). Em widgets, prefira [TinoTokens].
abstract final class TinoColors {
  static const jade = Color(0xFF246B55);
  static const lightJade = Color(0xFFABD8C5);
  static const glacialBlue = Color(0xFFC8E1ED);
  static const offWhite = Color(0xFFF5F7F6);
  static const ink = Color(0xFF16221F);
  static const softWhite = Color(0xFFEAF1EE);
}

/// Tokens semânticos do tema claro (docs/marca/tokens.json).
/// O tema escuro ainda não está implementado.
abstract final class TinoTokens {
  static const canvas = TinoColors.offWhite;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = TinoColors.softWhite;
  static const border = Color(0xFFD6E1DB);
  static const borderStrong = Color(0xFF7D9189);
  static const textPrimary = TinoColors.ink;
  static const textSecondary = Color(0xFF52655E);
  static const action = TinoColors.jade;
  static const onAction = Color(0xFFFFFFFF);
  static const actionPressed = Color(0xFF1C5946);
  static const info = TinoColors.glacialBlue;
}

/// Escala de 4 pt.
abstract final class TinoSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;
}

abstract final class TinoRadius {
  static const chip = 8.0;
  static const control = 12.0;
  static const cardCompact = 16.0;
  static const card = 20.0;
  static const panel = 24.0;
}

extension TinoMoney on TextStyle {
  /// Preço: peso 700 e numerais tabulares.
  TextStyle get money => copyWith(
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

TextStyle _style(double size, double height, FontWeight weight, Color color) =>
    TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: color,
    );

ThemeData buildTinoLightTheme() {
  const scheme = ColorScheme.light(
    primary: TinoTokens.action,
    onPrimary: TinoTokens.onAction,
    primaryContainer: TinoColors.lightJade,
    onPrimaryContainer: TinoTokens.textPrimary,
    secondary: TinoTokens.action,
    onSecondary: TinoTokens.onAction,
    secondaryContainer: TinoTokens.surfaceSoft,
    onSecondaryContainer: TinoTokens.textPrimary,
    surface: TinoTokens.surface,
    onSurface: TinoTokens.textPrimary,
    onSurfaceVariant: TinoTokens.textSecondary,
    outline: TinoTokens.borderStrong,
    outlineVariant: TinoTokens.border,
    surfaceContainerLow: TinoTokens.surfaceSoft,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: TinoTokens.canvas,
  );
  const primary = TinoTokens.textPrimary;
  const secondary = TinoTokens.textSecondary;
  final label = _style(14, 20, FontWeight.w600, primary);
  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(TinoRadius.control),
  );
  const buttonSize = Size(48, 48);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(TinoRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: _style(32, 40, FontWeight.w700, primary).money,
      headlineLarge: _style(24, 32, FontWeight.w700, primary),
      titleLarge: _style(20, 28, FontWeight.w700, primary),
      titleMedium: _style(18, 26, FontWeight.w600, primary),
      bodyLarge: _style(16, 24, FontWeight.w400, primary),
      bodyMedium: _style(14, 20, FontWeight.w500, secondary),
      labelLarge: label,
      bodySmall: _style(12, 16, FontWeight.w500, secondary),
    ),
    iconTheme: const IconThemeData(size: 24, color: TinoTokens.action),
    dividerTheme: const DividerThemeData(
      color: TinoTokens.border,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: TinoTokens.action,
            foregroundColor: TinoTokens.onAction,
            minimumSize: buttonSize,
            padding: buttonPadding,
            shape: control,
            textStyle: label,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed)
                  ? TinoTokens.actionPressed
                  : TinoTokens.action,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TinoTokens.action,
        minimumSize: buttonSize,
        padding: buttonPadding,
        side: const BorderSide(color: TinoTokens.action),
        shape: control,
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TinoTokens.action,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: control,
        textStyle: label,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: buttonSize,
        backgroundColor: TinoTokens.surface,
        foregroundColor: TinoTokens.textSecondary,
        selectedBackgroundColor: TinoTokens.surfaceSoft,
        selectedForegroundColor: TinoTokens.action,
        side: const BorderSide(color: TinoTokens.borderStrong),
        shape: control,
        textStyle: label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TinoTokens.surface,
      constraints: const BoxConstraints(minHeight: 52),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: _style(14, 20, FontWeight.w500, secondary),
      border: inputBorder(TinoTokens.borderStrong),
      enabledBorder: inputBorder(TinoTokens.borderStrong),
      focusedBorder: inputBorder(TinoTokens.action, 2),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TinoTokens.action,
      linearTrackColor: TinoTokens.surfaceSoft,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TinoTokens.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: TinoTokens.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TinoRadius.panel),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TinoTokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TinoRadius.panel),
      ),
      titleTextStyle: _style(20, 28, FontWeight.w700, primary),
      contentTextStyle: _style(16, 24, FontWeight.w400, primary),
    ),
  );
}
