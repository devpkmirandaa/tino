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

/// Como a lista é exibida. [manual] fica reservado para o arrastar (L1.5).
enum ListOrder {
  category('Por categoria'),
  added('Ordem de adição'),
  manual('Manual');

  const ListOrder(this.label);
  final String label;

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
  });

  final int id;
  final String name;
  final DateTime updatedAt;
  final ListOrder order;
  final List<ItemCategory> categoryOrder;
  final int itemCount;
  final int doneCount;
}

/// Bloco da lista na tela: [category] nulo quando a ordem não agrupa.
typedef ListSection = ({ItemCategory? category, List<ListItem> items});

/// Pendentes em seções conforme [order]; marcados à parte, no fim.
({List<ListSection> pending, List<ListItem> done}) arrangeList(
  List<ListItem> items,
  ListOrder order, {
  List<ItemCategory> categoryOrder = const [],
}) {
  int byAdded(ListItem a, ListItem b) {
    final c = a.createdAt.compareTo(b.createdAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  final pending = items.where((i) => !i.done).toList();
  final done = items.where((i) => i.done).toList()..sort(byAdded);
  if (order == ListOrder.added) {
    pending.sort(byAdded);
    return (
      pending: [if (pending.isNotEmpty) (category: null, items: pending)],
      done: done,
    );
  }
  // Por categoria (ou manual): categorias na ordem escolhida, depois as
  // restantes na ordem padrão.
  final sequence = [
    ...categoryOrder,
    for (final c in ItemCategory.values)
      if (!categoryOrder.contains(c)) c,
  ];
  return (
    pending: [
      for (final c in sequence)
        if (pending.where((i) => i.category == c).toList() case final list
            when list.isNotEmpty)
          (
            category: c,
            items: list
              ..sort(
                order == ListOrder.manual
                    ? (a, b) => a.position.compareTo(b.position)
                    : byAdded,
              ),
          ),
    ],
    done: done,
  );
}
