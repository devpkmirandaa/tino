import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/motion/tino_springs.dart';

/// Tabela de design/motion/motion.md: response (s) e amortecimento.
const _expected = {
  'toque': (response: 0.20, ratio: 0.90),
  'selecao': (response: 0.25, ratio: 0.85),
  'cartao': (response: 0.35, ratio: 0.82),
  'confirmacao': (response: 0.38, ratio: 0.70),
  'navegacao': (response: 0.42, ratio: 0.92),
  'folha': (response: 0.45, ratio: 0.88),
};

void main() {
  test('São exatamente as seis molas do motion.md', () {
    expect(TinoSprings.all.keys, unorderedEquals(_expected.keys));
  });

  for (final MapEntry(key: name, value: spec) in _expected.entries) {
    test('Mola $name: rigidez, atrito e amortecimento pela fórmula', () {
      final spring = TinoSprings.all[name]!;
      final stiffness = math.pow(2 * math.pi / spec.response, 2);
      final damping = 4 * math.pi * spec.ratio / spec.response;
      final ratio =
          spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));

      expect(spring.mass, 1);
      // A tabela arredonda rigidez para inteiro e atrito para 0,1.
      expect(spring.stiffness, closeTo(stiffness, 0.5));
      expect(spring.damping, closeTo(damping, 0.06));
      expect(ratio, closeTo(spec.ratio, 0.005));
    });
  }
}
