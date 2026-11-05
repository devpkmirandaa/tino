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

/// Nitidez: variância do Laplaciano no plano Y (os primeiros
/// [width]×[height] bytes), amostrando a cada [step] pixels. Borrado ≈ baixo.
double sharpness(Uint8List y, int width, int height, {int step = 2}) {
  var n = 0;
  var sum = 0.0;
  var squares = 0.0;
  for (var r = 1; r < height - 1; r += step) {
    final row = r * width;
    for (var c = 1; c < width - 1; c += step) {
      final i = row + c;
      final lap = 4 * y[i] - y[i - 1] - y[i + 1] - y[i - width] - y[i + width];
      sum += lap;
      squares += lap * lap;
      n++;
    }
  }
  if (n == 0) return 0;
  final mean = sum / n;
  return squares / n - mean * mean;
}

/// Miniatura [size]×[size] do plano Y (média de cada célula), para comparar
/// quadros rapidamente.
Uint8List thumbnail(Uint8List y, int width, int height, {int size = 16}) {
  final out = Uint8List(size * size);
  final cw = width ~/ size;
  final ch = height ~/ size;
  if (cw == 0 || ch == 0) return out;
  // Amostra 4×4 pontos por célula: barato e suficiente para média.
  final sx = (cw / 4).ceil();
  final sy = (ch / 4).ceil();
  for (var gy = 0; gy < size; gy++) {
    for (var gx = 0; gx < size; gx++) {
      var sum = 0;
      var n = 0;
      for (var r = gy * ch; r < (gy + 1) * ch; r += sy) {
        final row = r * width;
        for (var c = gx * cw; c < (gx + 1) * cw; c += sx) {
          sum += y[row + c];
          n++;
        }
      }
      out[gy * size + gx] = n == 0 ? 0 : sum ~/ n;
    }
  }
  return out;
}

/// Diferença média (0 a 255) entre duas miniaturas do mesmo tamanho.
double thumbnailDiff(Uint8List a, Uint8List b) {
  if (a.length != b.length || a.isEmpty) return 0;
  var sum = 0;
  for (var i = 0; i < a.length; i++) {
    sum += (a[i] - b[i]).abs();
  }
  return sum / a.length;
}
