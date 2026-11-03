/// Converte texto digitado ("12,90", "1.234,56", "0,347") em inteiro na
/// escala [scale] (2 = centavos, 3 = gramas). Sem ponto flutuante.
/// Com vírgula, pontos são milhares; só com ponto, ele é decimal se tiver
/// até [scale] dígitos depois. Retorna nulo se inválido ou com casas demais.
int? parseScaled(String input, int scale) {
  var s = input.replaceAll(RegExp(r'R\$|\s'), '');
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceFirst(',', '.');
  } else if (s.contains('.')) {
    final dec = s.length - s.lastIndexOf('.') - 1;
    if ('.'.allMatches(s).length > 1 || dec > scale) s = s.replaceAll('.', '');
  }
  final m = RegExp(r'^(\d{1,9})(?:\.(\d*))?$').firstMatch(s);
  if (m == null) return null;
  final frac = m[2] ?? '';
  if (frac.length > scale) return null;
  return int.parse(m[1]! + frac.padRight(scale, '0'));
}

/// Gramas em quilos no formato brasileiro: 347 → "0,347 kg".
String formatKg(int grams) =>
    '${grams ~/ 1000},${(grams % 1000).toString().padLeft(3, '0')} kg';
