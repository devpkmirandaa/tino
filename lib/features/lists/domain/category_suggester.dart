import 'shopping_list.dart';

/// Categoria sugerida pelo nome do produto, offline. O usuário pode trocar,
/// e a troca vira aprendizado ([learned]).
///
/// Ordem de decisão:
/// 1. o que o usuário já escolheu para este nome, ou para a primeira
///    palavra dele ([learned], chaves de [categoryKey] e [headKey]);
/// 2. expressões conhecidas ("leite condensado", "água sanitária");
/// 3. a primeira palavra do nome que for conhecida: em português o nome
///    começa pelo produto ("molho de tomate" é mercearia, "suco de laranja"
///    é bebida), com plural e erro de uma letra tolerados.
ItemCategory suggestCategory(
  String name, {
  Map<String, ItemCategory> learned = const {},
}) {
  final words = _words(name);
  if (words.isEmpty) return ItemCategory.outros;
  if (learned[words.join(' ')] case final c?) return c;
  if (learned[headKey(name)] case final c?) return c;

  final text = ' ${words.join(' ')} ';
  for (final (phrase, category) in _phrases) {
    if (text.contains(' $phrase ')) return category;
  }
  for (final w in words) {
    if (w.length < 2 || _stopWords.contains(w)) continue;
    if (_lookup(w) case final c?) return c;
  }
  return ItemCategory.outros;
}

/// Chave do nome inteiro para aprender a escolha do usuário.
String categoryKey(String name) => _words(name).join(' ');

/// Chave da primeira palavra significativa ("Molho de tomate" → "molho").
String headKey(String name) {
  for (final w in _words(name)) {
    if (w.length >= 2 && !_stopWords.contains(w) && !_isNumberish(w)) {
      return '#${_singular(w)}';
    }
  }
  return '';
}

ItemCategory? _lookup(String w) {
  final exact = _byWord[w] ?? _byWord[_singular(w)];
  if (exact != null) return exact;
  // Erro de uma letra só em palavras longas, e só se não houver empate.
  if (w.length < 5) return null;
  ItemCategory? found;
  for (final e in _byWord.entries) {
    if (e.key.length < 5 || (e.key.length - w.length).abs() > 1) continue;
    if (_withinOne(w, e.key)) {
      if (found != null && found != e.value) return null;
      found = e.value;
    }
  }
  return found;
}

/// Singular aproximado: "limões" → "limao", "pães" → "pao", "flores" →
/// "flor", "tomates" → "tomate".
String _singular(String w) {
  if (w.length > 4 && (w.endsWith('oes') || w.endsWith('aes'))) {
    return '${w.substring(0, w.length - 3)}ao';
  }
  if (w.length > 4 && w.endsWith('res')) return w.substring(0, w.length - 2);
  if (w.length > 3 && w.endsWith('s')) return w.substring(0, w.length - 1);
  return w;
}

bool _isNumberish(String w) => RegExp(r'^\d').hasMatch(w);

/// Distância de edição no máximo 1 (troca, falta ou sobra de uma letra).
bool _withinOne(String a, String b) {
  if (a == b) return true;
  if (a.length == b.length) {
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i] && ++diff > 1) return false;
    }
    return true;
  }
  final (s, l) = a.length < b.length ? (a, b) : (b, a);
  var i = 0, j = 0, skipped = false;
  while (i < s.length && j < l.length) {
    if (s[i] == l[j]) {
      i++;
      j++;
    } else if (skipped) {
      return false;
    } else {
      skipped = true;
      j++;
    }
  }
  return true;
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', 'í': 'i', //
  'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ü': 'u', 'ç': 'c',
};

List<String> _words(String text) => [
  for (final w
      in text
          .toLowerCase()
          .split('')
          .map((c) => _accents[c] ?? c)
          .join()
          .split(RegExp(r'[^a-z0-9]+')))
    if (w.isNotEmpty) w,
];

const _stopWords = {
  'de',
  'da',
  'do',
  'das',
  'dos',
  'com',
  'sem',
  'em',
  'e',
  'para',
  'pra',
  'tipo',
  'kg',
  'g',
  'ml',
  'l',
  'lt',
  'un',
  'und',
  'pct',
  'cx',
  'gr',
};

final _byWord = {
  for (final (category, words) in _vocabulary)
    for (final w in words.split(' '))
      if (w.isNotEmpty) w: category,
};

/// Expressões de mais de uma palavra, conferidas antes das palavras soltas.
const _phrases = <(String, ItemCategory)>[
  ('leite condensado', ItemCategory.mercearia),
  ('leite de coco', ItemCategory.mercearia),
  ('leite em po', ItemCategory.mercearia),
  ('creme de leite', ItemCategory.laticinios),
  ('doce de leite', ItemCategory.mercearia),
  ('agua sanitaria', ItemCategory.limpeza),
  ('agua de coco', ItemCategory.bebidas),
  ('papel higienico', ItemCategory.higiene),
  ('papel toalha', ItemCategory.limpeza),
  ('papel aluminio', ItemCategory.limpeza),
  ('saco de lixo', ItemCategory.limpeza),
  ('creme dental', ItemCategory.higiene),
  ('pasta de dente', ItemCategory.higiene),
  ('fio dental', ItemCategory.higiene),
  ('escova de dente', ItemCategory.higiene),
  ('peito de peru', ItemCategory.laticinios),
  ('pao de queijo', ItemCategory.congelados),
  ('batata palha', ItemCategory.mercearia),
  ('batata frita', ItemCategory.congelados),
  ('milho verde', ItemCategory.mercearia),
  ('extrato de tomate', ItemCategory.mercearia),
  ('molho de tomate', ItemCategory.mercearia),
  ('oleo de soja', ItemCategory.mercearia),
  ('carne moida', ItemCategory.carnes),
  ('frios', ItemCategory.laticinios),
  ('sorvete', ItemCategory.congelados),
];

/// Palavras por categoria (sem acento, singular; plural é tolerado).
const _vocabulary = <(ItemCategory, String)>[
  (
    ItemCategory.hortifruti,
    'banana maca laranja limao lima tangerina mexerica bergamota ponkan '
        'tomate batata cebola alho cenoura morango abacaxi mamao melancia '
        'melao alface pepino pimentao abobrinha abobora chuchu beterraba '
        'repolho brocolis couve couveflor mandioca aipim macaxeira '
        'mandioquinha inhame cara abacate manga uva pera kiwi goiaba '
        'maracuja coentro salsa salsinha cebolinha rucula agriao espinafre '
        'fruta verdura legume hortalica jilo quiabo berinjela vagem ervilha '
        'milho gengibre hortela manjericao alecrim pessego ameixa caqui '
        'figo coco acerola caju pitaya lichia framboesa mirtilo amora '
        'nectarina carambola graviola jabuticaba tamara cogumelo champignon '
        'shimeji shitake palmito rabanete nabo alcachofra aspargo acelga '
        'chicoria escarola almeirao batatadoce',
  ),
  (
    ItemCategory.padaria,
    'pao paes bisnaguinha bisnaga baguete bolo rosca sonho torrada broa '
        'croissant brioche ciabatta focaccia sovado frances integralpao '
        'panetone chocotone sanduiche esfiha empada coxinha pastel salgado '
        'biscoitinho cuca pudim torta',
  ),
  (
    ItemCategory.carnes,
    'carne frango galinha peito coxa sobrecoxa asa coracao moela figado '
        'picanha alcatra patinho acem costela file musculo maminha fraldinha '
        'contrafile cupim lagarto paleta coxao chuleta bisteca lombo pernil '
        'linguica salsicha bacon toucinho torresmo peixe tilapia salmao '
        'merluza bacalhau sardinha camarao lula polvo marisco mexilhao porco '
        'suino suina bovino bovina cordeiro carneiro peru chester pato '
        'hamburguer kafta almondega bife moida carnemoida acougue',
  ),
  (
    ItemCategory.laticinios,
    'leite queijo mussarela mucarela parmesao prato minas coalho '
        'ricota provolone gorgonzola cheddar cottage catupiry presunto '
        'apresuntado mortadela salame copa blanquet iogurte requeijao '
        'manteiga margarina nata coalhada kefir ovo ovos danone yakult '
        'petitsuisse bebidalactea',
  ),
  (
    ItemCategory.mercearia,
    'arroz feijao acucar cafe oleo azeite macarrao espaguete lasanha '
        'talharim penne parafuso farinha fuba sal molho extrato ketchup '
        'maionese mostarda vinagre tempero caldo biscoito bolacha chocolate '
        'achocolatado nescau toddy aveia granola cereal sucrilhos tapioca '
        'gelatina fermento condensado geleia mel pipoca amendoim castanha '
        'nozes lentilha grao graodebico quinoa chia linhaca polvilho amido '
        'maizena canela oregano cominho colorau pimenta louro curry paprica '
        'atum sardinhalata enlatado conserva azeitona palmitopote pepinilho '
        'champignonpote seleta milholata ervilhalata sopa miojo '
        'lamen macarraoinstantaneo bala chiclete pirulito wafer salgadinho '
        'doce goiabada pacoca rapadura cocada mistura bolopronto '
        'adocante cha capuccino nescafe pilao melitta camil tiojoao kicaldo '
        'knorr maggi hellmanns heinz predilecta sazon fandangos ruffles '
        'doritos cheetos passatempo trakinas negresco oreo bauducco lacta '
        'garoto nestle',
  ),
  (
    ItemCategory.bebidas,
    'refrigerante refri suco agua cerveja chope vinho espumante cachaca '
        'vodka whisky gin rum licor energetico isotonico gatorade nectar coca '
        'cocacola guarana fanta sprite pepsi tonica kombucha mate '
        'matte achocolatadopronto redbull monster skol brahma heineken '
        'antarctica budweiser amstel itaipava stella corona '
        'delvalle sukita schweppes h2oh',
  ),
  (
    ItemCategory.congelados,
    'congelado congelada sorvete picole acai lasanhacongelada pizza nuggets '
        'empanado steak polpa hamburguercongelado batatacongelada '
        'legumecongelado gelo',
  ),
  (
    ItemCategory.limpeza,
    'detergente sabao amaciante desinfetante sanitaria alvejante cloro '
        'esponja limpador multiuso lustramoveis lustra lixo vassoura rodo '
        'pano flanela inseticida repelente desengordurante tiramanchas '
        'removedor saponaceo cera palha aco bombril luva prendedor balde '
        'aromatizante odorizador naftalina ype omo ariel brilhante tixan '
        'surf comfort downy vanish pinho cif harpic lysoform '
        'qboa raid sbp baygon scotch brite aluminio filme sacola guardanapo '
        'copo descartavel vela fosforo isqueiro pilha lampada',
  ),
  (
    ItemCategory.higiene,
    'shampoo xampu condicionador sabonete dental escova desodorante '
        'absorvente fralda higienico cotonete algodao protetor hidratante '
        'barbeador lamina aparelho espuma gilete enxaguante antisseptico '
        'listerine colgate oralb sorriso closeup dove rexona nivea '
        'pampers huggies always intimus johnson lenco umedecido '
        'perfume colonia maquiagem batom esmalte acetona '
        'pomada curativo bandaid alcool gel seda pantene elseve tresemme',
  ),
  (
    ItemCategory.pet,
    'racao petisco areia sache pet whiskas pedigree golden premier '
        'friskies purina dogchow catchow ossinho tapete higienicopet',
  ),
];
