import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// As seis molas do Tino (design/motion/motion.md, v2). Use só estas.
///
/// Massa 1 em todas. `stiffness` = (2π / response)² e
/// `damping` = 4π · amortecimento / response. Todas têm amortecimento abaixo
/// de 1, então passam um pouco do ponto antes de acomodar, de propósito.
/// Quique visível só em [confirmacao].
///
/// Use com `SpringSimulation` + `AnimationController.animateWith`, partindo
/// do valor e da velocidade atuais, pra manter tudo interrompível.
/// Mola só em posição e escala; cor e opacidade usam [TinoCurves.easeOut].
abstract final class TinoSprings {
  /// Pressionar e soltar. response 0,22 · amortecimento 0,75.
  /// Afunda e volta com um repique curto.
  static const toque = SpringDescription(
    mass: 1,
    stiffness: 816,
    damping: 42.8,
  );

  /// Segmentado, aba, switch. response 0,30 · amortecimento 0,75.
  /// Desliza e assenta com leve passada.
  static const selecao = SpringDescription(
    mass: 1,
    stiffness: 439,
    damping: 31.4,
  );

  /// Entrar/sair item, barra, cantos do visor. response 0,40 ·
  /// amortecimento 0,72. Chega com uma pequena sobra.
  static const cartao = SpringDescription(
    mass: 1,
    stiffness: 247,
    damping: 22.6,
  );

  /// Item adicionado, check, total. response 0,45 · amortecimento 0,58.
  /// Quique visível, uma vez.
  static const confirmacao = SpringDescription(
    mass: 1,
    stiffness: 195,
    damping: 16.2,
  );

  /// Empurrar tela, abrir scanner. response 0,45 · amortecimento 0,85.
  /// Longa e macia, quase sem sobra.
  static const navegacao = SpringDescription(
    mass: 1,
    stiffness: 195,
    damping: 23.7,
  );

  /// Folhas e modais. response 0,50 · amortecimento 0,80.
  /// Sobe com peso e assenta.
  static const folha = SpringDescription(
    mass: 1,
    stiffness: 158,
    damping: 20.1,
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

/// Curva simples, para cor, opacidade e contagem (150–300 ms).
abstract final class TinoCurves {
  /// cubic-bezier(0.2, 0, 0, 1).
  static const easeOut = Cubic(0.2, 0, 0, 1);
}

abstract final class TinoMotion {
  /// Defasagem entre elementos de um mesmo grupo.
  static const stagger = Duration(milliseconds: 60);

  /// Troca por opacidade usada no lugar de deslocamento e escala quando o
  /// sistema pede movimento reduzido.
  static const reducedFade = Duration(milliseconds: 150);

  /// Simulação de uma das [TinoSprings], de [from] até [to], partindo da
  /// [velocity] atual. Encosta exatamente em [to] ao terminar.
  static SpringSimulation spring(
    SpringDescription spring,
    double from,
    double to, [
    double velocity = 0,
  ]) => SpringSimulation(spring, from, to, velocity, snapToEnd: true);

  /// Verdadeiro quando o sistema pede movimento reduzido.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
