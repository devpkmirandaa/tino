import 'package:flutter/material.dart';

import 'tino_colors.dart';
import 'tino_typography.dart';

export 'tino_colors.dart';
export 'tino_typography.dart';

// Fonte da verdade de todos os valores: design/tokens/tokens.json.
// test/theme_tokens_test.dart confere este arquivo contra o JSON.

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
  static const pill = 999.0;
}

abstract final class TinoSize {
  static const touchTarget = 48.0;
  static const inputHeight = 52.0;
  static const icon = 24.0;
  static const iconCompact = 20.0;
  static const iconStroke = 2.0;
  static const borderWidth = 1.0;
}

/// Tema claro. Mantido para os pontos de entrada atuais do app.
ThemeData buildTinoLightTheme() => buildTinoTheme(Brightness.light);

/// Tema completo a partir dos tokens de [TinoColorScheme].
///
/// O escuro já existe, mas o app segue em `ThemeMode.light` até as telas
/// trocarem [TinoTokens] por `context.tino`.
ThemeData buildTinoTheme(Brightness brightness) {
  final c = TinoColorScheme.of(brightness);
  // Erro fica no padrão do Material: o manual ainda não define token de erro.
  final defaults = brightness == Brightness.dark
      ? const ColorScheme.dark()
      : const ColorScheme.light();
  final scheme = defaults.copyWith(
    primary: c.action,
    onPrimary: c.onAction,
    primaryContainer: c.jadeTint ?? TinoColors.lightJade,
    onPrimaryContainer: c.textPrimary,
    secondary: c.action,
    onSecondary: c.onAction,
    secondaryContainer: c.surfaceSoft,
    onSecondaryContainer: c.textPrimary,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.borderStrong,
    outlineVariant: c.border,
    surfaceContainerLow: c.surfaceSoft,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: tinoFontFamily,
    scaffoldBackgroundColor: c.canvas,
    extensions: [c],
  );
  final primary = c.textPrimary;
  final secondary = c.textSecondary;
  final label = TinoType.label.withColor(primary);
  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(TinoRadius.control),
  );
  const buttonSize = Size(TinoSize.touchTarget, TinoSize.touchTarget);
  const buttonPadding = EdgeInsets.symmetric(
    horizontal: TinoSpace.s16,
    vertical: TinoSpace.s12,
  );
  OutlineInputBorder inputBorder(
    Color color, [
    double width = TinoSize.borderWidth,
  ]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(TinoRadius.control),
    borderSide: BorderSide(color: color, width: width),
  );

  return base.copyWith(
    textTheme: _withWeightAxis(
      base.textTheme.copyWith(
        displaySmall: TinoType.display.withColor(primary).money,
        headlineLarge: TinoType.tela.withColor(primary),
        titleLarge: TinoType.secao.withColor(primary),
        titleMedium: TinoType.subtitulo.withColor(primary),
        bodyLarge: TinoType.corpo.withColor(primary),
        bodyMedium: TinoType.secundario.withColor(secondary),
        labelLarge: label,
        bodySmall: TinoType.caption.withColor(secondary),
      ),
    ),
    // Lucide Outline: o traço (2 px) vem da fonte; ativo muda só a cor.
    iconTheme: IconThemeData(size: TinoSize.icon, color: c.action),
    dividerTheme: DividerThemeData(
      color: c.border,
      thickness: TinoSize.borderWidth,
      space: TinoSize.borderWidth,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: c.action,
            foregroundColor: c.onAction,
            minimumSize: buttonSize,
            padding: buttonPadding,
            shape: control,
            textStyle: label,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) =>
                  s.contains(WidgetState.pressed) ? c.actionPressed : c.action,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.action,
        minimumSize: buttonSize,
        padding: buttonPadding,
        side: BorderSide(color: c.action),
        shape: control,
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.action,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: control,
        textStyle: label,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: buttonSize,
        backgroundColor: c.surface,
        foregroundColor: c.textSecondary,
        selectedBackgroundColor: c.surfaceSoft,
        selectedForegroundColor: c.action,
        side: BorderSide(color: c.borderStrong),
        shape: control,
        textStyle: label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      constraints: const BoxConstraints(minHeight: TinoSize.inputHeight),
      // 14 vertical centraliza o texto de 24 px na altura de 52.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TinoSpace.s16,
        vertical: 14,
      ),
      labelStyle: TinoType.secundario.withColor(secondary),
      border: inputBorder(c.borderStrong),
      enabledBorder: inputBorder(c.borderStrong),
      focusedBorder: inputBorder(c.action, 2),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.action,
      linearTrackColor: c.surfaceSoft,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: c.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TinoRadius.panel),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TinoRadius.panel),
      ),
      titleTextStyle: TinoType.secao.withColor(primary),
      contentTextStyle: TinoType.corpo.withColor(primary),
    ),
  );
}

/// Estilos do Material que o Tino não redefine também levam o eixo `wght`.
TextTheme _withWeightAxis(TextTheme theme) {
  // O peso dos estilos do Material vem da geometria M3, aplicada só no
  // Theme.of; mesclar aqui é o mesmo que o Flutter faz depois.
  final t = Typography.material2021().englishLike.merge(theme);
  TextStyle? axis(TextStyle? s) => s?.withWeightAxis;
  return t.copyWith(
    displayLarge: axis(t.displayLarge),
    displayMedium: axis(t.displayMedium),
    displaySmall: axis(t.displaySmall),
    headlineLarge: axis(t.headlineLarge),
    headlineMedium: axis(t.headlineMedium),
    headlineSmall: axis(t.headlineSmall),
    titleLarge: axis(t.titleLarge),
    titleMedium: axis(t.titleMedium),
    titleSmall: axis(t.titleSmall),
    bodyLarge: axis(t.bodyLarge),
    bodyMedium: axis(t.bodyMedium),
    bodySmall: axis(t.bodySmall),
    labelLarge: axis(t.labelLarge),
    labelMedium: axis(t.labelMedium),
    labelSmall: axis(t.labelSmall),
  );
}
