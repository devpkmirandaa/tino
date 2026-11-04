import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/data/nv21_crop.dart';

void main() {
  test('recorta Y e VU nas posições certas', () {
    final src = Uint8List.fromList([
      for (var i = 0; i < 16; i++) i, // Y 4x4
      for (var i = 0; i < 8; i++) 100 + i, // VU 4x2
    ]);
    final c = cropNv21(
      src,
      width: 4,
      height: 4,
      stride: 4,
      x: 2,
      y: 2,
      w: 2,
      h: 2,
    )!;
    expect(c.bytes, [10, 11, 14, 15, 106, 107]);
    expect((c.width, c.height), (2, 2));
  });

  test('recusa recorte fora do quadro', () {
    final src = Uint8List(24);
    expect(
      cropNv21(src, width: 4, height: 4, stride: 4, x: 2, y: 2, w: 4, h: 2),
      isNull,
    );
  });

  test('moldura em pé vira faixa de colunas no sensor girado 90°', () {
    final r = sensorRect(
      left: 0.1,
      top: 0.3,
      right: 0.9,
      bottom: 0.6,
      width: 1280,
      height: 720,
      rotation: 90,
    );
    expect(r, (x: 384, y: 72, w: 384, h: 576));
  });
}
