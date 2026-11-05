import 'decimal_input.dart';
import 'money.dart';
import 'product_name.dart';

/// Linha reconhecida pelo OCR, com caixa na imagem em pé.
typedef OcrLine = ({
  String text,
  double left,
  double top,
  double width,
  double height,

  /// Topo e base de cada caractere, em ordem (vazia se o OCR não informar).
  List<({double top, double bottom})> glyphs,
});

/// Retângulo na imagem lida pelo OCR.
typedef Box = ({double left, double top, double width, double height});

Box _box(OcrLine l) =>
    (left: l.left, top: l.top, width: l.width, height: l.height);

/// Sugestão extraída de uma etiqueta; sempre confirmada pelo usuário.
final class TagReading {
  const TagReading({
    this.name,
    this.price,
    this.perKg = false,
    this.bulkPrice,
    this.bulkMin,
    this.strength = 1,
    this.weak = false,
    this.checked = false,
    this.glued = false,
    this.where,
    this.priceBox,
    this.bulkBox,
    this.partial = false,
    this.bulkHint = false,
  });

  final String? name;
  final Money? price;
  final bool perKg;

  /// Preço de atacado e quantidade mínima, quando a etiqueta informa.
  final Money? bulkPrice;
  final int? bulkMin;

  /// Peso do voto deste quadro (1 a 2): preço grande e com "R$" vale mais.
  final double strength;

  /// Preço lido com a vírgula torta ou sumida ("10:77", "RS 915"): ajuda a
  /// confirmar, mas não trava sozinho.
  final bool weak;

  /// Dígito verificador: preço por kg/litro × embalagem fecha com o preço.
  final bool checked;

  /// Número sem vírgula sozinho na linha do preço ("3511"): se repetir
  /// igual em 3 quadros, vira leitura firme.
  final bool glued;

  /// Centro e altura da linha do preço, na imagem da moldura.
  final ({double x, double y, double h})? where;

  /// Caixas da linha do preço e da do atacado, para recortar só essas
  /// regiões nos próximos quadros.
  final Box? priceBox;
  final Box? bulkBox;

  /// Lido só na região do preço: nome, "kg" e mínimo podem ter ficado de
  /// fora, e a ausência deles não é evidência.
  final bool partial;

  /// Etiqueta com cara de atacado ("ATACADO" escrito ou duas colunas de
  /// preço): um preço sozinho pode ser só uma das colunas.
  final bool bulkHint;

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

/// Sujeira que o OCR põe antes do preço grande (".3511", ".35.11").
const _junk = "[.,'’]?";
final _separatorMisread = RegExp(
  '^$_junk(?:$_currency\\s*)?(\\d{1,4})\\s*[:.]\\s*(\\d{2})\$',
);

/// "35 11": o ML Kit separou número e centavos em elementos diferentes, o
/// que já é sinal de centavos; leitura firme.
final _separatorSpace = RegExp('^(?:$_currency\\s*)?(\\d{1,3})\\s+(\\d{2})\$');

/// Número de 3 a 5 dígitos sozinho na linha ("3511", ".3511", "RS 915").
final _gluedDigits = RegExp('^$_junk(?:$_currency\\s*)?(\\d{3,5})\$');

/// Valor e unidade do preço de referência: "por kg R$ 4,98", "R$ 4,98/L".
final _referenceValue = RegExp(
  r'(?:por|do|da)\s+(kg|quilo|litro|l|100\s*g|100\s*ml)\b.*?(\d{1,4}[,.:]\d{2})'
  r'|(\d{1,4}[,.]\d{2})\s*/\s*(kg|litro|l|100\s*g|100\s*ml)\b',
  caseSensitive: false,
);

/// Tamanho da embalagem: "5KG", "1L", "500 g", "900ml".
final _packSize = RegExp(
  r'(?<![\d.,])(\d{1,4}(?:[.,]\d{1,3})?)\s*(kg|g|ml|lt|l)\b',
  caseSensitive: false,
);
final _oldPrice = RegExp(r'^\s*de\b', caseSensitive: false);

/// Preço de referência por unidade de medida ("Preço por kg R$ 4,98"),
/// comum em etiquetas unitárias: não é o preço do produto.
final _reference = RegExp(
  r'pre[çc]o\s+(?:por|do|da)\b|/\s*(?:l|litro|100\s*g|100\s*ml)\b',
  caseSensitive: false,
);

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
  r'^(?:oferta|ofertas|promo|promoção|economize|economia|hortifruti|hortifrúti|'
  r'açougue|padaria|atacado|varejo|leve|pague|imperdível|preço|preços|por|'
  r'de|un|unidade|unidades|cada|kg|exclusiv\w*)\b',
  caseSensitive: false,
);

typedef _Candidate = ({
  Money price,
  OcrLine line,
  bool currency,
  bool bulk,
  bool weak,
  bool glued,
});
typedef _Reference = ({int cents, int base});

/// Lê nome, preço, preço/kg e atacado de uma etiqueta brasileira.
///
/// - Preço: o de maior destaque (altura), com vírgula decimal; aceita
///   centavos pequenos ao lado ("6" + ",49"); ignora "DE R$ x" (preço
///   antigo). Preço de atacado ("a partir de N") fica à parte.
/// - Nome: maior linha de texto acima do preço que não seja faixa/seção.
///
/// [region]: as linhas vêm só do recorte em volta do preço já visto; o
/// número grande ali é o preço mesmo sem outras linhas para comparar.
TagReading readTag(List<OcrLine> lines, {bool region = false}) {
  final candidates = <_Candidate>[];
  void add(
    int? cents,
    OcrLine line,
    bool currency, {
    bool weak = false,
    bool glued = false,
  }) {
    if (cents == null || cents == 0) return;
    candidates.add((
      price: Money(cents),
      line: line,
      currency: currency,
      bulk: _nearBulk(line, lines),
      weak: weak,
      glued: glued,
    ));
  }

  final heights = [for (final l in lines) l.height]..sort();
  final median = heights.isEmpty ? 0.0 : heights[heights.length ~/ 2];

  for (final line in lines) {
    if (_reference.hasMatch(line.text) || _oldPrice.hasMatch(line.text)) {
      continue;
    }
    for (final m in _price.allMatches(line.text)) {
      add(
        parseScaled('${m[1]},${m[2]}', 2),
        line,
        _hasCurrency.hasMatch(m[0]!),
      );
    }
    // O OCR costuma trocar a vírgula por ":" ou "." ("10:77", "9.15") ou
    // perdê-la ("RS 915"). Só vale se a linha for apenas o preço.
    final alone = line.text.trim();
    if (_separatorMisread.firstMatch(alone) case final m?) {
      add(
        parseScaled('${m[1]},${m[2]}', 2),
        line,
        _hasCurrency.hasMatch(alone),
        weak: true,
      );
    } else if (_separatorSpace.firstMatch(alone) case final m?) {
      add(
        parseScaled('${m[1]},${m[2]}', 2),
        line,
        _hasCurrency.hasMatch(alone),
      );
    }
    final before = candidates.length;
    final whole = _integer.firstMatch(alone);
    if (whole != null) {
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
    // Vírgula sumida, número sozinho na linha do preço ("3511"): os dois
    // últimos dígitos são centavos. Firme se o desenho provar centavos
    // sobrescritos; senão voto fraco, que trava ao se repetir igual.
    final glued = _gluedDigits.firstMatch(alone);
    if (glued == null || candidates.length != before) continue;
    final digits = glued[1]!;
    final currency =
        _hasCurrency.hasMatch(alone) || _hasCurrencyBefore(line, lines);
    if (_superscriptCents(line, digits.length)) {
      add(_split(digits), line, true);
    } else if (currency || region || line.height >= median * 1.6) {
      add(_split(digits), line, currency, weak: true, glued: true);
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
              (c.currency && !b.currency || !c.weak && b.weak))) {
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
    // "kg" no próprio preço, ou em linha sem preço ("/ KG", "PREÇO POR
    // QUILO"). Linha com outro preço e "kg" é referência, não conta.
    perKg:
        _perKg.hasMatch(retail.line.text) ||
        lines.any(
          (l) =>
              _perKg.hasMatch(l.text) &&
              !_price.hasMatch(l.text) &&
              !_integer.hasMatch(l.text.trim()),
        ),
    bulkPrice: bulk?.price,
    bulkMin: bulkMin,
    strength: retail.weak ? 1 : _strength(retail, lines),
    weak: retail.weak,
    glued: retail.glued,
    priceBox: _box(retail.line),
    bulkBox: bulk == null ? null : _box(bulk.line),
    partial: region,
    where: (
      x: retail.line.left + retail.line.width / 2,
      y: retail.line.top + retail.line.height / 2,
      h: retail.line.height,
    ),
    // "ATACADO"/"a partir de" escrito, ou outro preço grande em outra coluna.
    bulkHint:
        lines.any((l) => _bulk.hasMatch(l.text)) ||
        candidates.any(
          (c) =>
              c.price != retail.price &&
              !_sameColumn(c.line, retail.line) &&
              c.line.height >= retail.line.height * 0.6,
        ),
    // Referência pode vir em linha própria ("Preço por kg R$ 4,98") ou em
    // linha pequena com "/kg"; a linha do próprio preço não conta.
    checked: _checks(retail.price, [
      for (final l in lines)
        if (l != retail.line) ?_referenceOf(l.text),
    ], lines),
  );
}

_Reference? _referenceOf(String text) {
  final m = _referenceValue.firstMatch(text);
  if (m == null) return null;
  final unit = (m[1] ?? m[4])!.toLowerCase().replaceAll(' ', '');
  final cents = parseScaled((m[2] ?? m[3])!.replaceAll(':', ','), 2);
  if (cents == null || cents == 0) return null;
  return (cents: cents, base: unit.startsWith('100') ? 100 : 1000);
}

/// Preço por kg/litro × tamanho da embalagem fecha com o preço lido, com a
/// folga do arredondamento do preço de referência.
bool _checks(Money price, List<_Reference> refs, List<OcrLine> lines) {
  if (refs.isEmpty) return false;
  for (final l in lines) {
    if (_reference.hasMatch(l.text)) continue;
    for (final m in _packSize.allMatches(l.text)) {
      final unit = m[2]!.toLowerCase();
      final size = parseScaled(m[1]!, 3);
      if (size == null || size == 0) continue;
      // Em g ou ml.
      final amount = unit == 'kg' || unit == 'l' || unit == 'lt'
          ? size
          : size ~/ 1000;
      for (final r in refs) {
        final expected = (r.cents * amount / r.base).round();
        final slack = (amount / r.base / 2).ceil() + 1;
        if ((expected - price.cents).abs() <= slack) return true;
      }
    }
  }
  return false;
}

/// Região para os próximos quadros: caixa do preço (e a do atacado, se
/// houver) com ~30% de margem, mais folga lateral de ~1 altura para "R$" e
/// centavos pequenos ao lado, limitada a [width]×[height]. Nula quando não
/// dá para confiar num recorte: sem preço, ou etiqueta com cara de atacado
/// em que o segundo preço ainda não apareceu.
Box? priceRegion(TagReading r, double width, double height) {
  final p = r.priceBox;
  if (r.price == null || p == null) return null;
  if (r.bulkHint && r.bulkBox == null) return null;
  var left = double.infinity, top = double.infinity;
  var right = -double.infinity, bottom = -double.infinity;
  for (final b in [p, ?r.bulkBox]) {
    final dx = b.width * 0.3 + b.height * 1.2;
    final dy = b.height * 0.5;
    if (b.left - dx < left) left = b.left - dx;
    if (b.top - dy < top) top = b.top - dy;
    if (b.left + b.width + dx > right) right = b.left + b.width + dx;
    if (b.top + b.height + dy > bottom) bottom = b.top + b.height + dy;
  }
  left = left.clamp(0, width);
  top = top.clamp(0, height);
  right = right.clamp(0, width);
  bottom = bottom.clamp(0, height);
  if (right - left < 8 || bottom - top < 8) return null;
  return (left: left, top: top, width: right - left, height: bottom - top);
}

/// "3511" → 35,11.
int? _split(String digits) => parseScaled(
  '${digits.substring(0, digits.length - 2)},'
  '${digits.substring(digits.length - 2)}',
  2,
);

/// Centavos sobrescritos: os dois últimos dígitos com no máximo 75% da
/// altura dos demais, ou alinhados pelo topo com a base bem mais alta.
bool _superscriptCents(OcrLine line, int digits) {
  final g = line.glyphs;
  if (g.length < digits) return false;
  final mine = g.sublist(g.length - digits);
  final whole = mine.sublist(0, digits - 2);
  final cents = mine.sublist(digits - 2);
  double minOf(Iterable<double> v) => v.reduce((a, b) => a < b ? a : b);
  double maxOf(Iterable<double> v) => v.reduce((a, b) => a > b ? a : b);
  final wholeHeight = minOf(whole.map((c) => c.bottom - c.top));
  if (wholeHeight <= 0) return false;
  final shorter =
      maxOf(cents.map((c) => c.bottom - c.top)) <= wholeHeight * 0.75;
  final wholeBottom = minOf(whole.map((c) => c.bottom));
  final wholeTop = maxOf(whole.map((c) => c.top));
  final raised =
      maxOf(cents.map((c) => c.bottom)) <= wholeBottom - wholeHeight * 0.2 &&
      minOf(cents.map((c) => c.top)) >= wholeTop - wholeHeight * 0.2;
  return shorter || raised;
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
  return best == null ? null : tidyProductName(best.text);
}

bool _isWords(String text) {
  final letters = _letters.allMatches(text).length;
  return letters >= 3 && letters >= text.replaceAll(' ', '').length / 2;
}

/// Como o preço travou: votação (3 de 5), atalho (2 fortes seguidas),
/// repetição (mesmo número sem vírgula em 3 quadros) ou dígito verificador
/// (preço por kg/litro × embalagem).
enum LockRule { votes, shortcut, repeated, checkDigit }

/// Votação entre os últimos quadros, com memória da etiqueta.
///
/// - Trava quando [votes] dos últimos [window] quadros concordam (3 de 5),
///   ou quando os dois últimos são leituras fortes e iguais.
/// - Troca de preço só se o novo travar e o atual tiver no máximo 1 voto,
///   para varejo/atacado não alternarem.
/// - Ausência não é evidência: quadro sem atacado, nome ou "kg" não apaga o
///   que já foi confirmado para o mesmo preço (2 votos confirmam).
/// - A sugestão some só após [maxMisses] quadros seguidos sem preço.
class ReadingConsensus {
  ReadingConsensus({this.window = 5, this.votes = 3, this.maxMisses = 8});

  final int window;
  final int votes;
  final int maxMisses;
  final _frames = <TagReading>[];
  Money? _accepted;
  var _misses = 0;

  /// Leitura travada, se houver.
  TagReading? stable;

  /// A leitura atual foi usada: recomeça e ignora o mesmo preço até a
  /// etiqueta sair de vista por alguns quadros ou surgir outro preço.
  void accept() {
    _accepted = stable?.price;
    stable = null;
    _frames.clear();
    _armed = 0;
    _hintWait = 0;
  }

  /// Quadros com preço em que uma troca detectada ainda pode se confirmar.
  static const _armedFrames = 6;

  /// Quadros que uma etiqueta com cara de atacado espera pelo segundo preço.
  static const hintFrames = 4;

  var _armed = 0;
  Money? _beforeCut;
  Money? _newPrice;
  var _newCount = 0;
  var _hintWait = 0;

  /// A última chamada de [add] confirmou troca de etiqueta: mudança brusca
  /// seguida de 2 quadros com preço novo. A janela recomeçou.
  var switched = false;

  /// A última chamada de [add] viu mudança brusca (imagem ou preço pulando).
  var cutSeen = false;

  /// Registra um quadro; retorna `true` se [stable] mudou. [cut] indica
  /// mudança brusca na imagem (diferença grande entre quadros).
  bool add(TagReading reading, {bool cut = false}) {
    switched = false;
    cutSeen = false;
    final price = reading.price;
    if (price == null) {
      _misses++;
      if (_misses >= 4) _accepted = null;
      if (_misses >= maxMisses) {
        _frames.clear();
        _armed = 0;
        _hintWait = 0;
        final changed = stable != null;
        stable = null;
        return changed;
      }
    } else {
      _misses = 0;
      if (price != _accepted) _accepted = null;
    }
    // Quadro sem preço não ocupa a janela: só os com preço votam.
    if (price == null) {
      if (cut) _arm();
      return false;
    }
    if (cut || _jumped(reading)) _arm();
    if (_armed > 0) _watchSwitch(price);
    _frames.add(reading);
    if (_frames.length > window) _frames.removeAt(0);
    if (switched) {
      // Fica só com os quadros da etiqueta nova.
      _frames.removeWhere((f) => f.price != price);
      stable = null;
      rule = null;
      _hintWait = 0;
    }

    final next = _decide();
    if (_same(next, stable)) return false;
    stable = next;
    return true;
  }

  void _arm() {
    cutSeen = true;
    _armed = _armedFrames;
    _beforeCut = stable?.price ?? (_frames.isEmpty ? null : _frames.last.price);
    _newPrice = null;
    _newCount = 0;
  }

  /// O preço pulou de lugar na moldura (mais de 1,5 altura da linha).
  bool _jumped(TagReading r) {
    final a = r.where;
    final b = _frames.isEmpty ? null : _frames.last.where;
    if (a == null || b == null || r.price == _frames.last.price) return false;
    final h = a.h > b.h ? a.h : b.h;
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy > (1.5 * h) * (1.5 * h);
  }

  void _watchSwitch(Money price) {
    _armed--;
    final before = _beforeCut;
    // O atacado da própria etiqueta não é etiqueta nova.
    if (before == null || price == before || price == stable?.bulkPrice) {
      _newPrice = null;
      _newCount = 0;
      return;
    }
    _newCount = price == _newPrice ? _newCount + 1 : 1;
    _newPrice = price;
    if (_newCount >= 2) {
      switched = true;
      _armed = 0;
    }
  }

  int _count(Money price) => _frames.where((f) => f.price == price).length;

  /// Primeira leitura com preço, antes de travar: mostrada como provisória.
  TagReading? get provisional {
    if (stable != null || _frames.isEmpty) return null;
    final last = _frames.last;
    return last.price == null || last.price == _accepted ? null : last;
  }

  /// Regra que travou o preço atual.
  LockRule? rule;

  (Money, LockRule)? _locked() {
    final last = _frames.last;
    if (last.checked && last.price != null && last.price != _accepted) {
      return (last.price!, LockRule.checkDigit);
    }
    final counts = <Money, int>{};
    final firm = <Money>{};
    final glued = <Money, int>{};
    for (final f in _frames) {
      final p = f.price;
      if (p == null || p == _accepted) continue;
      counts[p] = (counts[p] ?? 0) + 1;
      if (!f.weak) firm.add(p);
      if (f.glued) glued[p] = (glued[p] ?? 0) + 1;
    }
    for (final e in counts.entries) {
      if (e.value < votes) continue;
      // Votos fracos ajudam, mas é preciso ao menos uma leitura firme...
      if (firm.contains(e.key)) return (e.key, LockRule.votes);
      // ...ou o mesmo número sem vírgula repetido em 3 quadros.
      if ((glued[e.key] ?? 0) >= votes) return (e.key, LockRule.repeated);
    }
    if (_frames.length >= 2) {
      final a = _frames[_frames.length - 2];
      if (a.price != null &&
          a.price == last.price &&
          a.price != _accepted &&
          !a.weak &&
          !last.weak &&
          a.strength >= 1.5 &&
          last.strength >= 1.5) {
        return (a.price!, LockRule.shortcut);
      }
    }
    return null;
  }

  TagReading? _decide() {
    final old = stable;
    final lock = _locked();
    final Money price;
    if (old != null && (lock == null || _count(old.price!) > 1)) {
      price = old.price!;
    } else if (lock != null) {
      price = lock.$1;
      // Etiqueta com cara de atacado e um preço só: pode ser só uma das
      // colunas. Espera alguns quadros pelo segundo preço antes de aceitar.
      final single = _frames.where((f) => f.price == price);
      if (old?.price != price &&
          single.every((f) => f.bulkHint && f.bulkPrice == null) &&
          _hintWait < hintFrames) {
        _hintWait++;
        return old;
      }
      _hintWait = 0;
      if (old?.price != price) rule = lock.$2;
    } else {
      rule = null;
      return null;
    }
    final mine = [
      for (final f in _frames)
        if (f.price == price) f,
    ];
    final keep = old != null && old.price == price;
    final bulk =
        _confirmed(mine, (f) => f.bulkPrice) ?? (keep ? old.bulkPrice : null);
    return TagReading(
      price: price,
      // Nome confirmado por 2 quadros vence; senão mantém o já mostrado ou
      // usa o mais votado como provisório.
      name:
          _confirmed(mine, (f) => f.name) ??
          (keep ? old.name : null) ??
          _mostCommon(mine, (f) => f.name),
      // "kg" visto em 2 quadros; se só 1 quadro inteiro foi lido (os outros
      // eram recortes sem a linha do kg), 1 basta.
      perKg:
          mine.where((f) => f.perKg).length >=
              (mine.where((f) => !f.partial).length >= 2 ? 2 : 1) ||
          (keep && old.perKg),
      bulkPrice: bulk,
      bulkMin: bulk == null
          ? null
          : _mostCommon([
                  for (final f in mine)
                    if (f.bulkPrice == bulk) f,
                ], (f) => f.bulkMin) ??
                (keep ? old.bulkMin : null),
      strength: 2,
    );
  }

  /// Valor visto em pelo menos 2 quadros (o mais frequente).
  static T? _confirmed<T>(List<TagReading> frames, T? Function(TagReading) f) {
    final counts = _counts(frames, f);
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return best.value >= 2 ? best.key : null;
  }

  static T? _mostCommon<T>(List<TagReading> frames, T? Function(TagReading) f) {
    final counts = _counts(frames, f);
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  static Map<T, int> _counts<T>(
    List<TagReading> frames,
    T? Function(TagReading) f,
  ) {
    final counts = <T, int>{};
    for (final r in frames) {
      final v = f(r);
      if (v != null) counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts;
  }

  static bool _same(TagReading? a, TagReading? b) =>
      a?.price == b?.price &&
      a?.name == b?.name &&
      a?.perKg == b?.perKg &&
      a?.bulkPrice == b?.bulkPrice &&
      a?.bulkMin == b?.bulkMin;
}
