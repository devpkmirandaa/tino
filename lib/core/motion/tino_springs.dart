import 'package:flutter/widgets.dart';

/// As seis molas do Tino (design/motion/motion.md). Use só estas.
///
/// Massa 1 em todas. `stiffness` = (2π / response)² e
/// `damping` = 4π · amortecimento / response. Todas têm amortecimento abaixo
/// de 1, então passam um pouco do ponto antes de acomodar, de propósito.
///
/// Mola só em posição e escala; cor e opacidade usam [TinoCurves.easeOut].
abstract final class TinoSprings {
  /// Pressionar e soltar. response 0,20 · amortecimento 0,90 · ~200 ms.
  static const toque = SpringDescription(
    mass: 1,
    stiffness: 987,
    damping: 56.5,
  );

  /// Segmentado, aba, switch. response 0,25 · amortecimento 0,85 · ~250 ms.
  static const selecao = SpringDescription(
    mass: 1,
    stiffness: 632,
    damping: 42.7,
  );

  /// Entrar/sair item, barra, cantos do visor. response 0,35 ·
  /// amortecimento 0,82 · ~350 ms.
  static const cartao = SpringDescription(
    mass: 1,
    stiffness: 322,
    damping: 29.4,
  );

  /// Item adicionado, check. response 0,38 · amortecimento 0,70 · ~380 ms,
  /// com leve acomodação.
  static const confirmacao = SpringDescription(
    mass: 1,
    stiffness: 273,
    damping: 23.1,
  );

  /// Empurrar tela, abrir scanner. response 0,42 · amortecimento 0,92 ·
  /// ~420 ms.
  static const navegacao = SpringDescription(
    mass: 1,
    stiffness: 224,
    damping: 27.5,
  );

  /// Folhas e modais. response 0,45 · amortecimento 0,88 · ~450 ms.
  static const folha = SpringDescription(
    mass: 1,
    stiffness: 195,
    damping: 24.6,
  );

  static const all = {
    'toque': toque,
    'selecao': selecao,
    'cartao': cartao,
    'confirmacao': confirmacao,
    'navegacao': navegacao,
    'folha': folha,
  };
}

/// Curvas simples, para cor e opacidade (150–250 ms).
abstract final class TinoCurves {
  /// cubic-bezier(0.2, 0, 0, 1).
  static const easeOut = Cubic(0.2, 0, 0, 1);
}

abstract final class TinoMotion {
  /// Troca por opacidade usada no lugar de deslocamento e escala quando o
  /// sistema pede movimento reduzido.
  static const reducedFade = Duration(milliseconds: 150);

  /// Verdadeiro quando o sistema pede movimento reduzido.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
