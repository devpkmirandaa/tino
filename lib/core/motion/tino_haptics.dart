import 'package:flutter/services.dart';

/// Hápticos do Tino (design/motion/motion.md, tabela de háptico).
abstract final class TinoHaptics {
  /// Intervalo entre os dois pulsos do aviso.
  static const warningGap = Duration(milliseconds: 120);

  /// Aviso (passou do orçamento): dois impactos médios separados por 120 ms,
  /// pra ter ritmo próprio e não se confundir com o sucesso.
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(warningGap);
    await HapticFeedback.mediumImpact();
  }
}
