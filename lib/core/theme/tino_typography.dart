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
    fontVariations: tinoWeightAxis(fontWeight),
    color: color,
  );
}

/// A Plus Jakarta Sans é variável: o eixo `wght` precisa acompanhar
/// `fontWeight`, senão o Android pode desenhar todos os pesos iguais.
List<FontVariation> tinoWeightAxis(FontWeight weight) => [
  FontVariation.weight(weight.value.toDouble()),
];

extension TinoWeight on TextStyle {
  /// Troca o peso mantendo o eixo `wght` em sincronia. Use no lugar de
  /// `copyWith(fontWeight: ...)`.
  TextStyle weight(FontWeight weight) =>
      copyWith(fontWeight: weight, fontVariations: tinoWeightAxis(weight));

  /// Aplica o eixo `wght` do peso que o estilo já tem.
  TextStyle get withWeightAxis {
    final w = fontWeight;
    return w == null ? this : weight(w);
  }
}

extension TinoMoney on TextStyle {
  /// Preço: peso 700 e numerais tabulares.
  TextStyle get money =>
      weight(FontWeight.w700)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
