import 'dart:typed_data';

/// Retângulo em pixels do sensor que corresponde a uma área da imagem em pé,
/// dada em frações ([left], [top], [right], [bottom]). [rotation] é a rotação
/// (graus, sentido horário) que deixa o quadro do sensor em pé.
({int x, int y, int w, int h}) sensorRect({
  required double left,
  required double top,
  required double right,
  required double bottom,
  required int width,
  required int height,
  required int rotation,
}) {
  final (x0, x1, y0, y1) = switch (rotation) {
    90 => (
      top * width,
      bottom * width,
      (1 - right) * height,
      (1 - left) * height,
    ),
    270 => (
      (1 - bottom) * width,
      (1 - top) * width,
      left * height,
      right * height,
    ),
    180 => (
      (1 - right) * width,
      (1 - left) * width,
      (1 - bottom) * height,
      (1 - top) * height,
    ),
    _ => (left * width, right * width, top * height, bottom * height),
  };
  return (
    x: x0.round(),
    y: y0.round(),
    w: (x1 - x0).round(),
    h: (y1 - y0).round(),
  );
}

/// Recorta um quadro NV21 (plano Y seguido de VU intercalado, com [stride]
/// bytes por linha). Coordenadas são ajustadas para pares. Retorna nulo se o
/// recorte não couber no quadro.
({Uint8List bytes, int width, int height})? cropNv21(
  Uint8List src, {
  required int width,
  required int height,
  required int stride,
  required int x,
  required int y,
  required int w,
  required int h,
}) {
  x &= ~1;
  y &= ~1;
  w &= ~1;
  h &= ~1;
  final uvStart = stride * height;
  if (w <= 0 ||
      h <= 0 ||
      x < 0 ||
      y < 0 ||
      x + w > width ||
      y + h > height ||
      src.length < uvStart + stride * (height ~/ 2 - 1) + width) {
    return null;
  }
  final out = Uint8List(w * h + w * (h ~/ 2));
  var o = 0;
  for (var r = 0; r < h; r++) {
    final s = (y + r) * stride + x;
    out.setRange(o, o + w, src, s);
    o += w;
  }
  for (var r = 0; r < h ~/ 2; r++) {
    final s = uvStart + (y ~/ 2 + r) * stride + x;
    out.setRange(o, o + w, src, s);
    o += w;
  }
  return (bytes: out, width: w, height: h);
}
