import 'decimal_input.dart';
import 'money.dart';

/// Linha reconhecida pelo OCR, com caixa na imagem em pé.
typedef OcrLine = ({
  String text,
  double left,
  double top,
  double width,
  double height,
});

/// Sugestão extraída de uma etiqueta; sempre confirmada pelo usuário.
final class TagReading {
  const TagReading({
    this.name,
    this.price,
    this.perKg = false,
    this.bulkPrice,
    this.bulkMin,
    this.strength = 1,
  });

  final String? name;
  final Money? price;
  final bool perKg;

  /// Preço de atacado e quantidade mínima, quando a etiqueta informa.
  final Money? bulkPrice;
  final int? bulkMin;

  /// Peso do voto deste quadro (1 a 2): preço grande e com "R$" vale mais.
  final double strength;

  /// Preço unitário para [quantity] unidades (atacado, se atingir o mínimo).
  Money? priceFor(int quantity) =>
      bulkPrice != null && bulkMin != null && quantity >= bulkMin!
      ? bulkPrice
      : price;

  /// Combina com outra leitura do mesmo preço, sem perder o que já foi visto.
  TagReading merge(TagReading? other) => other == null
      ? this
      : TagReading(
          name: name ?? other.name,
          price: price,
          perKg: perKg || other.perKg,
          bulkPrice: bulkPrice ?? other.bulkPrice,
          bulkMin: bulkMin ?? other.bulkMin,
        );
}

/// "R$" como o OCR costuma ler: "R$", "RS", "R5", "R $".
const _currency = r'R\s?[\$S5]';
final _currencyAlone = RegExp('^$_currency\$');
final _price = RegExp(
  '(?:$_currency\\s*)?(\\d{1,3}(?:\\.\\d{3})+|\\d{1,5})\\s*,\\s*(\\d{2})(?!\\d)',
);
final _integer = RegExp('^(?:$_currency\\s*)?(\\d{1,4})\$');
final _cents = RegExp(r'''^[,.'’]?\s*(\d{2})$''');
final _hasCurrency = RegExp(_currency);
final _oldPrice = RegExp(r'^\s*de\b', caseSensitive: false);

/// "/kg", "por kg", "por quilo" ou "kg" sozinho; "1 kg" (embalagem) não.
final _perKg = RegExp(
  r'/\s*kg\b|\bpor\s+(?:kg|quilo)\b|^\s*kg\s*$|(?<![\d\s])\s*kg\b',
  caseSensitive: false,
);
final _bulk = RegExp(r'atacado|a partir de', caseSensitive: false);
final _minQty = RegExp(r'a partir de\s*(\d{1,3})', caseSensitive: false);
final _letters = RegExp(r'[A-Za-zÀ-ÿ]');

/// Palavras de faixa promocional ou de seção, que não são nome de produto.
final _banner = RegExp(
  r'^(?:oferta|ofertas|promo|promoção|economize|hortifruti|hortifrúti|'
  r'açougue|padaria|atacado|varejo|leve|pague|imperdível|preço|preços|por|'
  r'de|un|unidade|unidades|cada|kg|exclusiv\w*)\b',
  caseSensitive: false,
);

typedef _Candidate = ({Money price, OcrLine line, bool currency, bool bulk});

/// Lê nome, preço, preço/kg e atacado de uma etiqueta brasileira.
///
/// - Preço: o de maior destaque (altura), com vírgula decimal; aceita
///   centavos pequenos ao lado ("6" + ",49"); ignora "DE R$ x" (preço
///   antigo). Preço de atacado ("a partir de N") fica à parte.
/// - Nome: maior linha de texto acima do preço que não seja faixa/seção.
TagReading readTag(List<OcrLine> lines) {
  final candidates = <_Candidate>[];
  void add(int? cents, OcrLine line, bool currency) {
    if (cents == null || cents == 0) return;
    candidates.add((
      price: Money(cents),
      line: line,
      currency: currency,
      bulk: _nearBulk(line, lines),
    ));
  }

  for (final line in lines) {
    if (_oldPrice.hasMatch(line.text)) continue;
    for (final m in _price.allMatches(line.text)) {
      add(
        parseScaled('${m[1]},${m[2]}', 2),
        line,
        _hasCurrency.hasMatch(m[0]!),
      );
    }
    final whole = _integer.firstMatch(line.text.trim());
    if (whole == null) continue;
    for (final other in lines) {
      final cents = _cents.firstMatch(other.text.trim());
      if (cents == null || !_isCentsBeside(line, other)) continue;
      add(
        parseScaled('${whole[1]},${cents[1]}', 2),
        line,
        _hasCurrency.hasMatch(line.text) || _hasCurrencyBefore(line, lines),
      );
    }
  }
  if (candidates.isEmpty) return const TagReading();

  _Candidate? pick(Iterable<_Candidate> list) {
    _Candidate? best;
    for (final c in list) {
      final b = best;
      if (b == null ||
          c.line.height > b.line.height * 1.05 ||
          (c.line.height >= b.line.height * 0.95 &&
              c.currency &&
              !b.currency)) {
        best = c;
      }
    }
    return best;
  }

  var retail = pick(candidates.where((c) => !c.bulk)) ?? pick(candidates)!;
  var bulk = pick(candidates.where((c) => c.bulk && c.price != retail.price));
  // Etiqueta dupla sem rótulo lido: dois preços grandes lado a lado. O
  // atacado é sempre o mais barato.
  if (bulk == null) {
    final twin = _twinOf(retail, candidates);
    if (twin != null) {
      final cheaper = twin.price.cents < retail.price.cents;
      bulk = cheaper ? twin : retail;
      retail = cheaper ? retail : twin;
    }
  } else if (bulk.price.cents > retail.price.cents) {
    (retail, bulk) = (bulk, retail);
  }
  final bulkMin = switch (bulk) {
    null => null,
    final b => _minQuantity(b.line, lines),
  };

  return TagReading(
    name: _name(lines, retail.line),
    price: retail.price,
    perKg: lines.any((l) => _perKg.hasMatch(l.text)),
    bulkPrice: bulk?.price,
    bulkMin: bulkMin,
    strength: _strength(retail, lines),
  );
}

/// Outro preço de tamanho parecido, na mesma altura e ao lado.
_Candidate? _twinOf(_Candidate main, List<_Candidate> all) {
  final h = main.line.height;
  for (final c in all) {
    final l = c.line;
    final beside =
        l.left >= main.line.left + main.line.width ||
        l.left + l.width <= main.line.left;
    if (c.price != main.price &&
        beside &&
        l.height >= h * 0.8 &&
        l.height <= h * 1.25 &&
        (l.top - main.line.top).abs() < h * 0.6) {
      return c;
    }
  }
  return null;
}

/// 1 a 2: soma 0,5 por ter "R$" e 0,5 por se destacar das demais linhas.
double _strength(_Candidate c, List<OcrLine> lines) {
  final heights = [for (final l in lines) l.height]..sort();
  final median = heights[heights.length ~/ 2];
  return 1 + (c.currency ? 0.5 : 0) + (c.line.height >= median * 1.6 ? 0.5 : 0);
}

bool _isCentsBeside(OcrLine whole, OcrLine cents) {
  final gap = cents.left - (whole.left + whole.width);
  return cents.height < whole.height &&
      gap >= -whole.height * 0.2 &&
      gap < whole.height * 0.8 &&
      cents.top >= whole.top - whole.height * 0.3 &&
      cents.top < whole.top + whole.height * 0.6;
}

bool _hasCurrencyBefore(OcrLine price, List<OcrLine> lines) => lines.any(
  (l) =>
      _currencyAlone.hasMatch(l.text.trim()) &&
      l.left < price.left &&
      (l.top + l.height / 2 - (price.top + price.height / 2)).abs() <
          price.height,
);

bool _sameColumn(OcrLine a, OcrLine b) =>
    a.left < b.left + b.width && b.left < a.left + a.width;

/// Indicação de atacado na mesma coluna, logo acima ou abaixo do preço.
bool _nearBulk(OcrLine price, List<OcrLine> lines) => lines.any(
  (l) =>
      _bulk.hasMatch(l.text) &&
      _sameColumn(l, price) &&
      (l.top - price.top).abs() < price.height * 2.5,
);

int? _minQuantity(OcrLine price, List<OcrLine> lines) {
  for (final l in lines) {
    final m = _minQty.firstMatch(l.text);
    if (m != null && _sameColumn(l, price)) return int.parse(m[1]!);
  }
  return null;
}

String? _name(List<OcrLine> lines, OcrLine price) {
  OcrLine? best;
  for (final l in lines) {
    final text = l.text.trim();
    if (l.top >= price.top ||
        _price.hasMatch(text) ||
        _banner.hasMatch(text) ||
        !_isWords(text)) {
      continue;
    }
    if (best == null || l.height > best.height * 1.05) best = l;
  }
  return best == null ? null : _tidy(best.text);
}

bool _isWords(String text) {
  final letters = _letters.allMatches(text).length;
  return letters >= 3 && letters >= text.replaceAll(' ', '').length / 2;
}

/// Espaços normalizados; TUDO MAIÚSCULO vira "Só a primeira".
String _tidy(String text) {
  final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t != t.toUpperCase()) return t;
  final lower = t.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Consenso ponderado entre os últimos quadros, com memória da etiqueta.
///
/// - Cada quadro vota com peso [TagReading.strength]; o preço aparece quando
///   soma [threshold] (ex.: duas leituras fortes ou três fracas).
/// - Ausência não é evidência: um quadro que não leu o atacado, o nome ou o
///   "kg" não apaga o que já foi confirmado para o mesmo preço.
/// - Um valor confirmado só é trocado se outro vencer com folga.
/// - A sugestão some só após [maxMisses] quadros seguidos sem preço.
class ReadingConsensus {
  ReadingConsensus({
    this.window = 12,
    this.threshold = 2.5,
    this.margin = 2,
    this.maxMisses = 8,
  });

  final int window;
  final double threshold;
  final double margin;
  final int maxMisses;
  final _frames = <TagReading>[];
  Money? _accepted;
  var _misses = 0;

  /// Leitura decidida, se houver.
  TagReading? stable;

  /// A leitura atual foi usada: recomeça e ignora o mesmo preço até a
  /// etiqueta sair de vista por alguns quadros ou surgir outro preço.
  void accept() {
    _accepted = stable?.price;
    stable = null;
    _frames.clear();
  }

  /// Registra um quadro; retorna `true` se [stable] mudou.
  bool add(TagReading reading) {
    final price = reading.price;
    if (price == null) {
      _misses++;
      if (_misses >= 4) _accepted = null;
      if (_misses < maxMisses) return false;
      _frames.clear();
      final changed = stable != null;
      stable = null;
      return changed;
    }
    _misses = 0;
    if (price != _accepted) _accepted = null;
    _frames.add(reading);
    if (_frames.length > window) _frames.removeAt(0);

    final next = _decide();
    if (_same(next, stable)) return false;
    stable = next;
    return true;
  }

  /// Peso de cada quadro: força da leitura com decaimento pela idade, para a
  /// troca de etiqueta ser rápida e leituras soltas não mudarem nada.
  static const decay = 0.75;

  TagReading? _decide() {
    final frames = <(TagReading, double)>[];
    var w = 1.0;
    for (final f in _frames.reversed) {
      if (f.price != _accepted) frames.add((f, f.strength * w));
      w *= decay;
    }
    final old = stable;
    final price = _winner(frames, (f) => f.price, old?.price, threshold);
    if (price == null) return null;
    final mine = [
      for (final e in frames)
        if (e.$1.price == price) e,
    ];
    final keep = old != null && old.price == price;
    final bulk =
        _winner(mine, (f) => f.bulkPrice, keep ? old.bulkPrice : null, 2) ??
        (keep ? old.bulkPrice : null);
    final kg = mine.where((e) => e.$1.perKg).fold(0.0, (s, e) => s + e.$2);
    return TagReading(
      price: price,
      name: _heaviest(mine, (f) => f.name) ?? (keep ? old.name : null),
      perKg: kg >= 2 || (keep && old.perKg),
      bulkPrice: bulk,
      bulkMin: bulk == null
          ? null
          : _heaviest([
                  for (final e in mine)
                    if (e.$1.bulkPrice == bulk) e,
                ], (f) => f.bulkMin) ??
                (keep ? old.bulkMin : null),
      strength: 2,
    );
  }

  static Map<T, double> _weights<T>(
    List<(TagReading, double)> frames,
    T? Function(TagReading) field,
  ) {
    final weights = <T, double>{};
    for (final (f, w) in frames) {
      final v = field(f);
      if (v != null) weights[v] = (weights[v] ?? 0) + w;
    }
    return weights;
  }

  /// Valor com mais peso, se somar [need]; o [current] fica enquanto tiver
  /// peso e não perder por mais de [margin].
  T? _winner<T>(
    List<(TagReading, double)> frames,
    T? Function(TagReading) field,
    T? current,
    double need,
  ) {
    final weights = _weights(frames, field);
    if (weights.isEmpty) return null;
    final best = weights.entries.reduce((a, b) => b.value > a.value ? b : a);
    final mine = current == null ? 0.0 : weights[current] ?? 0.0;
    if (current != null && mine > 0 && best.value <= mine + margin) {
      return current;
    }
    return best.value >= need ? best.key : null;
  }

  static T? _heaviest<T>(
    List<(TagReading, double)> frames,
    T? Function(TagReading) field,
  ) {
    final weights = _weights(frames, field);
    if (weights.isEmpty) return null;
    return weights.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  static bool _same(TagReading? a, TagReading? b) =>
      a?.price == b?.price &&
      a?.name == b?.name &&
      a?.perKg == b?.perKg &&
      a?.bulkPrice == b?.bulkPrice &&
      a?.bulkMin == b?.bulkMin;
}
