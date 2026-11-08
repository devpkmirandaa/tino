/// Seção do mercado. A ordem do enum é a ordem padrão de "por categoria".
enum ItemCategory {
  hortifruti('Hortifrúti'),
  padaria('Padaria'),
  carnes('Carnes e peixes'),
  laticinios('Laticínios e frios'),
  mercearia('Mercearia'),
  bebidas('Bebidas'),
  congelados('Congelados'),
  limpeza('Limpeza'),
  higiene('Higiene e beleza'),
  pet('Pet'),
  outros('Outros');

  const ItemCategory(this.label);
  final String label;

  static ItemCategory parse(String? name) =>
      values.where((c) => c.name == name).firstOrNull ?? outros;
}

/// Como a lista é exibida (Organizar lista, telas/13). A antiga "ordem de
/// adição" (`added` no banco) passa a ser lida como [category].
enum ListOrder {
  category('Por categoria', 'Agrupa como os corredores do mercado.'),
  manual('Ordem manual', 'Você arrasta cada item pra onde quiser.');

  const ListOrder(this.label, this.detail);
  final String label;
  final String detail;

  static ListOrder parse(String? name) =>
      values.where((o) => o.name == name).firstOrNull ?? category;
}

final class ListItem {
  const ListItem({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.createdAt,
    this.quantity = 1,
    this.unit = 'un',
    this.done = false,
  });

  final int id;
  final String name;
  final int quantity;
  final String unit;
  final ItemCategory category;
  final int position;
  final bool done;
  final DateTime createdAt;

  String get amount => '$quantity $unit';
}

final class ShoppingListInfo {
  const ShoppingListInfo({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.order = ListOrder.category,
    this.categoryOrder = const [],
    this.itemCount = 0,
    this.doneCount = 0,
    this.lastUsed,
  });

  final int id;
  final String name;
  final DateTime updatedAt;
  final ListOrder order;
  final List<ItemCategory> categoryOrder;
  final int itemCount;
  final int doneCount;

  /// Última compra concluída com esta lista.
  final DateTime? lastUsed;
}

/// Bloco da lista na tela: [category] nulo na ordem manual (lista única).
typedef ListSection = ({ItemCategory? category, List<ListItem> items});

/// Categorias na ordem escolhida, depois as restantes na ordem padrão.
List<ItemCategory> categorySequence(List<ItemCategory> chosen) => [
  ...chosen,
  for (final c in ItemCategory.values)
    if (!chosen.contains(c)) c,
];

/// Itens na tela (design/telas/08). Por categoria: seções na ordem do
/// mercado, itens na ordem de adição. Manual: uma seção só, na posição
/// arrastada. Arruma o que recebe; a Lista passa os que faltam e, à parte,
/// os do "No carrinho" ([splitDone]).
List<ListSection> arrangeList(
  List<ListItem> items,
  ListOrder order, {
  List<ItemCategory> categoryOrder = const [],
}) {
  int byAdded(ListItem a, ListItem b) {
    final c = a.createdAt.compareTo(b.createdAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  if (order == ListOrder.manual) {
    final sorted = [...items]
      ..sort((a, b) {
        final p = a.position.compareTo(b.position);
        return p != 0 ? p : byAdded(a, b);
      });
    return [if (sorted.isNotEmpty) (category: null, items: sorted)];
  }
  return [
    for (final c in categorySequence(categoryOrder))
      if (items.where((i) => i.category == c).toList() case final list
          when list.isNotEmpty)
        (category: c, items: list..sort(byAdded)),
  ];
}

/// Itens que faltam e os já no carrinho, cada grupo na ordem recebida.
({List<ListItem> pending, List<ListItem> done}) splitDone(
  Iterable<ListItem> items,
) => (
  pending: [
    for (final i in items)
      if (!i.done) i,
  ],
  done: [
    for (final i in items)
      if (i.done) i,
  ],
);

/// Linha de apoio do item (design/specs/lista-v2.md): só quando diz algo
/// além de "1 unidade".
String? itemDetail(ListItem item) => switch ((item.quantity, item.unit)) {
  (1, 'un') => null,
  (final q, 'un') => '$q unidades',
  _ => item.amount,
};

/// Categorias presentes na lista, na ordem em que aparecem (Organizar).
List<ItemCategory> presentCategories(
  List<ListItem> items,
  List<ItemCategory> categoryOrder,
) => [
  for (final c in categorySequence(categoryOrder))
    if (items.any((i) => i.category == c)) c,
];

/// Nova ordem completa a partir das categorias presentes reordenadas: as
/// ausentes seguem depois, na ordem que já tinham.
List<ItemCategory> mergeCategoryOrder(
  List<ItemCategory> reordered,
  List<ItemCategory> previous,
) => [
  ...reordered,
  for (final c in categorySequence(previous))
    if (!reordered.contains(c)) c,
];

/// Linha de apoio do cartão da lista (design/telas/07): "6 itens · em uso
/// no carrinho", "24 itens · usada há 12 dias", "8 itens" ou "Vazia".
String listSummary(
  ShoppingListInfo list, {
  required bool inUse,
  required DateTime now,
}) {
  final count = switch (list.itemCount) {
    0 => 'Vazia',
    1 => '1 item',
    final n => '$n itens',
  };
  final context = inUse ? 'em uso no carrinho' : _usedAgo(list.lastUsed, now);
  return context == null ? count : '$count · $context';
}

String? _usedAgo(DateTime? used, DateTime now) {
  if (used == null) return null;
  // Dias de calendário; arredonda para não errar em dia com horário de verão.
  final days =
      (DateTime(
                now.year,
                now.month,
                now.day,
              ).difference(DateTime(used.year, used.month, used.day)).inHours /
              24)
          .round();
  return switch (days) {
    <= 0 => 'usada hoje',
    1 => 'usada ontem',
    final n => 'usada há $n dias',
  };
}
