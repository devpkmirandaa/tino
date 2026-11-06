import 'package:flutter/material.dart';

/// Paleta oficial (design/tokens/tokens.json). Fixa nos dois temas.
/// Em widgets, use os tokens semânticos de [TinoColorScheme].
abstract final class TinoColors {
  static const jade = Color(0xFF246B55); // jade-profundo
  static const lightJade = Color(0xFFABD8C5); // jade-claro
  static const glacialBlue = Color(0xFFC8E1ED); // azul-glacial
  static const offWhite = Color(0xFFF5F7F6); // off-white-frio
  static const ink = Color(0xFF16221F); // grafite-profundo
  static const softWhite = Color(0xFFEAF1EE); // branco-suave
}

/// Tokens semânticos do tema claro como constantes.
///
/// Legado: as telas atuais usam estas constantes. Ao migrar uma tela, troque
/// por `context.tino.<token>`, que respeita claro e escuro.
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

/// Tokens semânticos de cor por tema (design/tokens/tokens.json).
@immutable
class TinoColorScheme extends ThemeExtension<TinoColorScheme> {
  const TinoColorScheme({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceSoft,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.action,
    required this.onAction,
    required this.actionPressed,
    required this.info,
    required this.onInfo,
    required this.scrim,
    this.jadeTint,
    this.blueTint,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color surfaceSoft;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color action;
  final Color onAction;
  final Color actionPressed;
  final Color info;

  /// Texto sobre [info]: grafite-profundo nos dois temas (12:1).
  final Color onInfo;

  /// Camada atrás de folhas, modais e scanner. Opaca: a opacidade fica no
  /// componente (0,5 nas folhas).
  final Color scrim;

  /// Só no escuro: o manual não define valor para o claro.
  final Color? jadeTint;

  /// Só no escuro: o manual não define valor para o claro.
  final Color? blueTint;

  static const light = TinoColorScheme(
    brightness: Brightness.light,
    canvas: TinoTokens.canvas,
    surface: TinoTokens.surface,
    surfaceSoft: TinoTokens.surfaceSoft,
    border: TinoTokens.border,
    borderStrong: TinoTokens.borderStrong,
    textPrimary: TinoTokens.textPrimary,
    textSecondary: TinoTokens.textSecondary,
    action: TinoTokens.action,
    onAction: TinoTokens.onAction,
    actionPressed: TinoTokens.actionPressed,
    info: TinoTokens.info,
    onInfo: TinoColors.ink,
    scrim: TinoColors.ink,
  );

  static const dark = TinoColorScheme(
    brightness: Brightness.dark,
    canvas: Color(0xFF141A1A),
    surface: Color(0xFF202929),
    surfaceSoft: Color(0xFF293532),
    border: Color(0xFF35423F),
    borderStrong: Color(0xFF82938D),
    textPrimary: TinoColors.offWhite,
    textSecondary: Color(0xFFAFC1BB),
    action: TinoColors.lightJade,
    onAction: TinoColors.ink,
    actionPressed: Color(0xFF8DBCA8),
    info: TinoColors.glacialBlue,
    onInfo: TinoColors.ink,
    scrim: Color(0xFF060909),
    jadeTint: Color(0xFF29483D),
    blueTint: Color(0xFF283D46),
  );

  static TinoColorScheme of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  TinoColorScheme copyWith() => this;

  /// Troca de tema sem interpolar cores (as duas paletas são fixas).
  @override
  TinoColorScheme lerp(TinoColorScheme? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension TinoThemeContext on BuildContext {
  /// Tokens de cor do tema atual.
  TinoColorScheme get tino =>
      Theme.of(this).extension<TinoColorScheme>() ?? TinoColorScheme.light;
}
