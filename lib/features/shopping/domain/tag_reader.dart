import 'decimal_input.dart';
import 'money.dart';

/// Linha reconhecida pelo OCR, com posição vertical e altura na imagem.
typedef OcrLine = ({String text, double top, double height});

/// Sugestão extraída de uma etiqueta; sempre confirmada pelo usuário.
final class TagReading {
  const TagReading({this.name, this.price, this.perKg = false});

  final String? name;
  final Money? price;
  final bool perKg;
}

final _price = RegExp(
  r'(?:R\$\s*)?(\d{1,3}(?:\.\d{3})+|\d{1,5})\s*,\s*(\d{2})(?!\d)',
);
final _perKg = RegExp(r'\b(?:kg|quilo)\b', caseSensitive: false);
final _letters = RegExp(r'[A-Za-zÀ-ÿ]');

/// Escolhe o preço de maior destaque (maior altura; com "R$" desempata) e o
/// nome na primeira linha de texto acima dele. Só aceita vírgula decimal,
/// formato das etiquetas brasileiras, para não confundir com códigos.
TagReading readTag(List<OcrLine> lines) {
  ({Money price, OcrLine line, bool currency})? best;
  for (final line in lines) {
    for (final m in _price.allMatches(line.text)) {
      final cents = parseScaled('${m[1]},${m[2]}', 2);
      if (cents == null || cents == 0) continue;
      final currency = m[0]!.contains(r'R$');
      final better =
          best == null ||
          line.height > best.line.height * 1.05 ||
          (line.height >= best.line.height * 0.95 &&
              currency &&
              !best.currency);
      if (better) best = (price: Money(cents), line: line, currency: currency);
    }
  }
  if (best == null) return const TagReading();

  String? name;
  final above = [
    for (final l in lines)
      if (l.top < best.line.top && !_price.hasMatch(l.text) && _isName(l.text))
        l,
  ]..sort((a, b) => a.top.compareTo(b.top));
  if (above.isNotEmpty) name = _clean(above.first.text);

  return TagReading(
    name: name,
    price: best.price,
    perKg: _perKg.hasMatch(best.line.text),
  );
}

bool _isName(String text) {
  final letters = _letters.allMatches(text).length;
  return letters >= 3 && letters >= text.replaceAll(' ', '').length / 2;
}

String _clean(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Só confirma uma leitura quando o mesmo preço aparece em [needed] quadros
/// seguidos, para não sugerir valores lidos de passagem.
class ReadingStabilizer {
  ReadingStabilizer({this.needed = 2});

  final int needed;
  TagReading? _last;
  var _hits = 0;

  /// Leitura confirmada mais recente, se houver.
  TagReading? stable;

  /// Registra um quadro; retorna `true` se [stable] mudou.
  bool add(TagReading reading) {
    final price = reading.price;
    if (price == null) return false;
    final same = price == _last?.price && reading.perKg == _last?.perKg;
    _hits = same ? _hits + 1 : 1;
    _last = TagReading(
      name: reading.name ?? (same ? _last?.name : null),
      price: price,
      perKg: reading.perKg,
    );
    final next = _last!;
    if (_hits < needed) return false;
    final old = stable;
    if (old != null &&
        old.price == next.price &&
        old.perKg == next.perKg &&
        old.name == next.name) {
      return false;
    }
    stable = next;
    return true;
  }
}
