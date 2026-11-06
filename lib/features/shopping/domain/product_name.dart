/// Nome de produto lido pelo OCR: corrige palavras quase iguais às de um
/// vocabulário de supermercado e formata como "Leite integral UHT".
///
/// A correção é conservadora: só troca quando a palavra lida está a uma
/// letra (ou duas, em palavras longas) de uma única palavra da lista; marca
/// ou palavra desconhecida fica como foi lida.
String tidyProductName(String raw) {
  final text = _lettersForDigits(raw.trim().replaceAll(RegExp(r'\s+'), ' '));
  if (text.isEmpty) return text;
  final shouting = text == text.toUpperCase();
  final words = text.split(' ').map(_correct).toList();
  if (!shouting) return words.join(' ');
  // TUDO MAIÚSCULO vira "Só a primeira", mantendo siglas e unidades.
  return [
    for (var i = 0; i < words.length; i++)
      _sentenceCase(words[i], first: i == 0),
  ].join(' ');
}

final _digitInWord = RegExp(r'(?<=[A-Za-zÀ-ÿ])[01](?=[A-Za-zÀ-ÿ])');

/// 0 e 1 entre letras são O e I mal lidos: "I0GURTE" → "IOGURTE".
String _lettersForDigits(String text) =>
    text.replaceAllMapped(_digitInWord, (m) {
      final next = text[m.end];
      final upper = next == next.toUpperCase();
      final letter = m[0] == '0' ? 'O' : 'I';
      return upper ? letter : letter.toLowerCase();
    });

/// Siglas e unidades que ficam sempre em maiúsculas.
const _acronyms = {'UHT', 'ML', 'KG', 'L', 'G', 'LT', 'MG', 'UN'};

String _sentenceCase(String word, {required bool first}) {
  final bare = word.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9]'), '').toUpperCase();
  // "1L", "500G", "5KG": número com unidade.
  if (_acronyms.contains(bare) || RegExp(r'\d').hasMatch(word)) {
    return word.toUpperCase();
  }
  final lower = word.toLowerCase();
  return first && lower.isNotEmpty
      ? lower[0].toUpperCase() + lower.substring(1)
      : lower;
}

final _wordCore = RegExp(r'^([^A-Za-zÀ-ÿ]*)([A-Za-zÀ-ÿ]+)([^A-Za-zÀ-ÿ]*)$');

String _correct(String token) {
  final m = _wordCore.firstMatch(token);
  if (m == null) return token;
  final word = m[2]!;
  final key = _plain(word);
  if (key.length < 4 || _acronyms.contains(word.toUpperCase())) return token;
  final fixed = _lookup(key);
  if (fixed == null || fixed == word.toLowerCase()) return token;
  return '${m[1]}${_matchCase(fixed, word)}${m[3]}';
}

/// Palavra do vocabulário igual (sem acento) ou muito parecida e única.
String? _lookup(String key) {
  if (_byPlain[key] case final exact?) return exact;
  // Palavras de 4 letras só com igualdade: "Dove" não vira "doce".
  if (key.length < 5) return null;
  final limit = key.length >= 8 ? 2 : 1;
  String? best;
  var bestDistance = limit + 1;
  var tie = false;
  for (final e in _byPlain.entries) {
    // Palavra curta da lista não captura palavra lida: "macia" não vira
    // "maçã".
    if (e.key.length < 5 || (e.key.length - key.length).abs() > limit) {
      continue;
    }
    final d = _distance(key, e.key, limit);
    if (d < bestDistance) {
      best = e.value;
      bestDistance = d;
      tie = false;
    } else if (d == bestDistance && e.value != best) {
      tie = true;
    }
  }
  return tie ? null : best;
}

String _matchCase(String fixed, String original) {
  if (original == original.toUpperCase()) return fixed.toUpperCase();
  if (original[0] == original[0].toUpperCase()) {
    return fixed[0].toUpperCase() + fixed.substring(1);
  }
  return fixed;
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', 'í': 'i', //
  'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ü': 'u', 'ç': 'c',
};

String _plain(String word) {
  final lower = word.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    out.write(_accents[ch] ?? ch);
  }
  return out.toString();
}

/// Distância de edição (com troca de letras vizinhas), parando acima de
/// [limit].
int _distance(String a, String b, int limit) {
  var prev2 = <int>[];
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final row = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = [
        prev[j] + 1,
        row[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          prev2[j - 2] + 1 < v) {
        v = prev2[j - 2] + 1;
      }
      row[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > limit) return limit + 1;
    prev2 = prev;
    prev = row;
  }
  return prev[b.length];
}

final _byPlain = {for (final w in _vocabulary) _plain(w): w};

/// Palavras comuns em etiquetas de supermercado, mais marcas frequentes
/// (que assim ficam protegidas de correção errada).
const _vocabulary = [
  // Mercearia
  'arroz', 'feijão', 'açúcar', 'café', 'leite', 'integral', 'desnatado',
  'semidesnatado', 'óleo', 'soja', 'azeite', 'oliva', 'extra', 'virgem',
  'macarrão', 'espaguete', 'parafuso', 'penne', 'farinha', 'trigo',
  'mandioca', 'milho', 'fubá', 'refinado', 'cristal', 'mascavo', 'demerara',
  'biscoito', 'bolacha', 'recheado', 'cream', 'cracker', 'chocolate',
  'achocolatado', 'molho', 'extrato', 'ketchup', 'maionese', 'mostarda',
  'vinagre', 'tempero', 'caldo', 'gelatina', 'pudim', 'condensado', 'creme',
  'atum', 'sardinha', 'ervilha', 'aveia', 'granola', 'cereal', 'tapioca',
  'polvilho', 'goiabada', 'geleia', 'fermento', 'bicarbonato', 'amido',
  'canela', 'orégano', 'colorau', 'cominho', 'pimenta', 'solúvel', 'torrado',
  'moído', 'filtro', 'cappuccino', 'parboilizado', 'carioca', 'preto',
  'branco', 'tipo', 'tradicional', 'original', 'light', 'diet', 'zero',
  'lactose', 'gordura', 'vegetal', 'pasteurizado', 'fatiado', 'ralado',
  'congelado', 'resfriado', 'cremoso',
  // Frios, laticínios e carnes
  'manteiga', 'margarina', 'queijo', 'mussarela', 'muçarela', 'prato',
  'presunto', 'mortadela', 'salame', 'iogurte', 'natural', 'requeijão',
  'frango', 'carne', 'bovina', 'suína', 'peito', 'coxa', 'sobrecoxa',
  'linguiça', 'salsicha', 'bacon', 'ovos', 'picanha', 'alcatra', 'patinho',
  'costela', 'filé', 'tilápia', 'hambúrguer', 'nuggets', 'empanado',
  'lasanha', 'pizza',
  // Hortifrúti
  'banana', 'maçã', 'laranja', 'limão', 'tomate', 'batata', 'cebola',
  'alho', 'cenoura', 'morango', 'abacaxi', 'mamão', 'melancia', 'melão',
  'alface', 'pepino', 'pimentão', 'abobrinha', 'chuchu', 'beterraba',
  'repolho', 'brócolis', 'couve', 'mandioquinha', 'abacate', 'manga',
  // Bebidas
  'refrigerante', 'suco', 'água', 'mineral', 'cerveja', 'vinho', 'tinto',
  'suave', 'energético', 'isotônico', 'néctar', 'garrafa', 'lata',
  // Limpeza e higiene
  'detergente', 'sabão', 'líquido', 'amaciante', 'desinfetante',
  'sanitária', 'papel', 'higiênico', 'toalha', 'guardanapo', 'esponja',
  'shampoo', 'condicionador', 'sabonete', 'dental', 'desodorante',
  'absorvente', 'fralda', 'limpador', 'multiuso',
  // Embalagem
  'pacote', 'caixa', 'unidade', 'unidades', 'sachê', 'refil', 'bandeja',
  // Adjetivos comuns: ficam protegidos de correção errada.
  'macia', 'macio', 'média', 'médio', 'dura', 'duro', 'suave', 'forte',
  'fino', 'fina', 'grosso', 'grossa', 'grande', 'pequeno', 'pequena',
  'branca', 'branco', 'preta', 'preto', 'escuro', 'claro', 'novo', 'nova',
  'mole', 'firme', 'leve', 'denso', 'cremoso', 'cremosa', 'crocante',
  'escova', 'dental', 'dente', 'dentes', 'bucal', 'oral', 'kit',
  // Marcas frequentes
  'nestlé', 'lacta', 'garoto', 'sadia', 'perdigão', 'seara', 'aurora',
  'piracanjuba', 'italac', 'parmalat', 'elegê', 'tirol', 'vigor', 'danone',
  'camil', 'pilão', 'melitta', 'bauducco', 'nescau', 'toddy', 'liza',
  'qualy', 'knorr', 'maggi', 'heinz', 'predilecta', 'wickbold', 'pullman',
  'brahma', 'heineken', 'skol', 'antarctica', 'guaraná', 'pepsi', 'coca',
  'dove', 'colgate', 'omo', 'ypê', 'veja', 'downy', 'confort',
];
