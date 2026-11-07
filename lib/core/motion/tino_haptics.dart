import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Padrão de vibração: [timings] alterna pausa e pulso (ms), começando por
/// pausa; [amplitudes] de 0 a 255 na mesma posição.
typedef TinoVibration = ({List<int> timings, List<int> amplitudes});

/// Hápticos do Tino (design/motion/motion.md, tabela de háptico). Vibração
/// direta pelo `Vibrator` do Android (canal `tino/vibration` no
/// `MainActivity`), com uso de mídia: não depende da "vibração ao tocar" e
/// vibra também no modo silencioso. As chaves de Ajustes decidem antes de
/// chamar. Fora do Android, ou se o canal falhar, cai no `HapticFeedback`.
abstract final class TinoHaptics {
  static const _channel = MethodChannel('tino/vibration');

  /// Intervalo entre os dois pulsos do aviso.
  static const warningGap = Duration(milliseconds: 120);

  /// Leve: um pulso curto e fraco.
  static const lightPattern = (timings: [0, 20], amplitudes: [0, 80]);

  /// Sucesso: um pulso só, mais longo e forte.
  static const successPattern = (timings: [0, 40], amplitudes: [0, 200]);

  /// Aviso: dois pulsos médios separados por [warningGap].
  static const warningPattern = (
    timings: [0, 30, 120, 30],
    amplitudes: [0, 150, 0, 150],
  );

  /// Leve: desfazer no scanner.
  static Future<void> light() =>
      _vibrate(lightPattern, HapticFeedback.lightImpact);

  /// Sucesso: item no carrinho, concluir compra. Um pulso só, pra não se
  /// confundir com os dois do aviso.
  static Future<void> success() =>
      _vibrate(successPattern, HapticFeedback.heavyImpact);

  /// Aviso (perto do limite, passou do orçamento): dois pulsos médios
  /// separados por 120 ms, ritmo próprio.
  static Future<void> warning() => _vibrate(warningPattern, () async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(warningGap);
    await HapticFeedback.mediumImpact();
  });

  static Future<void> _vibrate(
    TinoVibration pattern,
    Future<void> Function() fallback,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final done = await _channel.invokeMethod<bool>('vibrate', {
          'timings': pattern.timings,
          'amplitudes': pattern.amplitudes,
        });
        if (done ?? false) return;
      } on Exception {
        // Sem canal (testes) ou sem vibrador: tenta o háptico do sistema.
      }
    }
    await fallback();
  }
}
