import 'package:flutter/painting.dart';

/// Família registrada no pubspec (Plus Jakarta Sans variável).
const tinoFontFamily = 'PlusJakartaSans';

/// Escala tipográfica do manual (design/tokens/tokens.json). Sem cor: o tema
/// aplica `text-primary` ou `text-secondary`.
abstract final class TinoType {
  static const display = TinoTypeStyle(32, 40, FontWeight.w700);
  static const tela = TinoTypeStyle(24, 32, FontWeight.w700);
  static const secao = TinoTypeStyle(20, 28, FontWeight.w700);
  static const subtitulo = TinoTypeStyle(18, 26, FontWeight.w600);
  static const corpo = TinoTypeStyle(16, 24, FontWeight.w400);
  static const secundario = TinoTypeStyle(14, 20, FontWeight.w500);
  static const label = TinoTypeStyle(14, 20, FontWeight.w600);
  static const caption = TinoTypeStyle(12, 16, FontWeight.w500);

  /// Corpo em peso 600: rótulo do botão primário e nome na linha de item
  /// (design/specs/telas.md). Fora da escala de 8 estilos; aprovado como
  /// variação do corpo.
  static const corpoForte = TinoTypeStyle(16, 24, FontWeight.w600);

  static const all = {
    'display': display,
    'tela': tela,
    'secao': secao,
    'subtitulo': subtitulo,
    'corpo': corpo,
    'secundario': secundario,
    'label': label,
    'caption': caption,
  };
}

class TinoTypeStyle {
  const TinoTypeStyle(this.fontSize, this.lineHeight, this.fontWeight);

  final double fontSize;
  final double lineHeight;
  final FontWeight fontWeight;

  TextStyle withColor(Color color) => TextStyle(
    fontFamily: tinoFontFamily,
    fontSize: fontSize,
    height: lineHeight / fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

extension TinoMoney on TextStyle {
  /// Preço: peso 700 e numerais tabulares.
  TextStyle get money => copyWith(
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
