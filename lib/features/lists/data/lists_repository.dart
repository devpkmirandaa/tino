import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tino_database.dart';
import '../domain/category_suggester.dart';
import '../domain/frequent_items.dart';
import '../domain/list_matcher.dart';
import '../domain/shopping_list.dart';

final listsRepositoryProvider = Provider<ListsRepository>(
  (ref) => ListsRepository(ref.watch(databaseProvider)),
);

/// Listas de compras no aparelho. As telas recarregam pelos providers
/// (`lists_providers.dart`) depois de cada alteração.
class ListsRepository {
  ListsRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;
  final TinoDatabase _db;
  final DateTime Function() _now;

  /// Listas com contagem de itens, mais recente primeiro.
  Future<List<ShoppingListInfo>> lists() async {
    final total = _db.listItems.id.count();
    final done = _db.listItems.id.count(
      filter: _db.listItems.done.equals(true),
    );
    final query =
        _db.select(_db.shoppingLists).join([
            leftOuterJoin(
              _db.listItems,
              _db.listItems.listId.equalsExp(_db.shoppingLists.id),
              useColumns: false,
            ),
          ])
          ..addColumns([total, done])
          ..groupBy([_db.shoppingLists.id])
          ..orderBy([
            OrderingTerm.desc(_db.shoppingLists.updatedAt),
            OrderingTerm.desc(_db.shoppingLists.id),
          ]);
    final used = await lastUsed();
    return [
      for (final r in await query.get())
        _info(
          r.readTable(_db.shoppingLists),
          r.read(total) ?? 0,
          r.read(done) ?? 0,
          used,
        ),
    ];
  }

  /// Última compra concluída com cada lista (para "usada há N dias").
  Future<Map<int, DateTime>> lastUsed() async {
    final last = _db.purchases.finishedAt.max();
    final query = _db.selectOnly(_db.purchases)
      ..addColumns([_db.purchases.listId, last])
      ..where(
        _db.purchases.listId.isNotNull() & _db.purchases.finishedAt.isNotNull(),
      )
      ..groupBy([_db.purchases.listId]);
    return {
      for (final r in await query.get())
        if ((r.read(_db.purchases.listId), r.read(last)) case (
          final id?,
          final at?,
        ))
          id: at,
    };
  }

  /// Compras finalizadas para "Você costuma levar": produtos com o texto da
  /// etiqueta e os itens atuais da lista usada (a lista é desmarcada ao
  /// concluir, então vale o que ela tem hoje).
  Future<List<PastPurchase>> pastPurchases() async {
    final purchases = await (_db.select(
      _db.purchases,
    )..where((p) => p.finishedAt.isNotNull())).get();
    if (purchases.isEmpty) return const [];
    final products = <int, List<({String name, String? tagText})>>{};
    for (final r in await (_db.select(
      _db.purchaseItems,
    )..where((i) => i.purchaseId.isIn(purchases.map((p) => p.id)))).get()) {
      products.putIfAbsent(r.purchaseId, () => []).add((
        name: r.name,
        tagText: r.tagText,
      ));
    }
    final listIds = {for (final p in purchases) ?p.listId};
    final listItems = <int, List<String>>{};
    if (listIds.isNotEmpty) {
      for (final r in await (_db.select(
        _db.listItems,
      )..where((i) => i.listId.isIn(listIds))).get()) {
        listItems.putIfAbsent(r.listId, () => []).add(r.name);
      }
    }
    return [
      for (final p in purchases)
        (
          finishedAt: p.finishedAt!,
          products: products[p.id] ?? const [],
          listItems: listItems[p.listId] ?? const [],
        ),
    ];
  }

  /// Ordem das categorias de "Por categoria" (Organizar lista).
  Future<void> setCategoryOrder(int id, List<ItemCategory> order) => _touch(
    id,
    ShoppingListsCompanion(
      categoryOrder: Value(order.map((c) => c.name).join(',')),
    ),
  );

  /// Ordem manual: [ids] na ordem da tela viram as posições 0, 1, 2…
  Future<void> reorderItems(int listId, List<int> ids) =>
      _db.transaction(() async {
        for (final (position, id) in ids.indexed) {
          await (_db.update(_db.listItems)
                ..where((i) => i.id.equals(id) & i.listId.equals(listId)))
              .write(ListItemsCompanion(position: Value(position)));
        }
        await _touch(listId, const ShoppingListsCompanion());
      });

  Future<List<ListItem>> items(int listId) async => [
    for (final r in await (_db.select(
      _db.listItems,
    )..where((i) => i.listId.equals(listId))).get())
      _item(r),
  ];

  /// Escolhas de categoria aprendidas com o usuário.
  Future<Map<String, ItemCategory>> learnedCategories() async => {
    for (final r in await _db.select(_db.categoryHints).get())
      r.key: ItemCategory.parse(r.category),
  };

  /// Lembra a categoria escolhida para o nome inteiro e para a primeira
  /// palavra dele ("Molho de pimenta" ensina também "molho").
  Future<void> learnCategory(String name, ItemCategory category) =>
      _db.batch((b) {
        for (final key in [categoryKey(name), headKey(name)]) {
          if (key.isEmpty || key == '#') continue;
          b.insert(
            _db.categoryHints,
            CategoryHintsCompanion.insert(key: key, category: category.name),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

  /// Pares produto → item já respondidos (true = casa, false = não casa).
  Future<Map<String, bool>> learnedPairs() async => {
    for (final r in await _db.select(_db.listPairs).get()) r.key: r.matches,
  };

  Future<void> learnPair(String productName, String itemName, bool matches) =>
      _db
          .into(_db.listPairs)
          .insertOnConflictUpdate(
            ListPairsCompanion.insert(
              key: pairKey(productName, itemName),
              matches: matches,
            ),
          );

  Future<int> createList(String name) {
    final now = _now();
    return _db
        .into(_db.shoppingLists)
        .insert(
          ShoppingListsCompanion.insert(
            name: name.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> renameList(int id, String name) =>
      _touch(id, ShoppingListsCompanion(name: Value(name.trim())));

  Future<void> setOrder(int id, ListOrder order) =>
      _touch(id, ShoppingListsCompanion(sortMode: Value(order.name)));

  Future<void> deleteList(int id) =>
      (_db.delete(_db.shoppingLists)..where((l) => l.id.equals(id))).go();

  /// Novo item no fim da lista (por categoria, vai pro fim da sua seção).
  Future<int> addItem(
    int listId, {
    required String name,
    required ItemCategory category,
    int quantity = 1,
  }) => _db.transaction(() async {
    final last =
        await (_db.selectOnly(_db.listItems)
              ..addColumns([_db.listItems.position.max()])
              ..where(_db.listItems.listId.equals(listId)))
            .map((r) => r.read(_db.listItems.position.max()))
            .getSingle();
    final id = await _db
        .into(_db.listItems)
        .insert(
          ListItemsCompanion.insert(
            listId: listId,
            name: name.trim(),
            quantity: Value(quantity),
            category: category.name,
            position: (last ?? -1) + 1,
            createdAt: _now(),
          ),
        );
    await _touch(listId, const ShoppingListsCompanion());
    return id;
  });

  Future<void> updateItem(
    int listId,
    int id, {
    required String name,
    required ItemCategory category,
    required int quantity,
  }) => _changeItem(
    listId,
    id,
    ListItemsCompanion(
      name: Value(name.trim()),
      category: Value(category.name),
      quantity: Value(quantity),
    ),
  );

  Future<void> setDone(int listId, int id, bool done) =>
      _changeItem(listId, id, ListItemsCompanion(done: Value(done)));

  /// Desmarca todos os itens da lista (compra concluída: pronta para a
  /// próxima). Os não marcados ficam como estão.
  Future<void> uncheckAll(int listId) => _db.transaction(() async {
    await (_db.update(_db.listItems)
          ..where((i) => i.listId.equals(listId) & i.done.equals(true)))
        .write(const ListItemsCompanion(done: Value(false)));
    await _touch(listId, const ShoppingListsCompanion());
  });

  Future<void> deleteItem(int listId, int id) => _db.transaction(() async {
    await (_db.delete(_db.listItems)..where((i) => i.id.equals(id))).go();
    await _touch(listId, const ShoppingListsCompanion());
  });

  Future<void> _changeItem(int listId, int id, ListItemsCompanion change) =>
      _db.transaction(() async {
        await (_db.update(
          _db.listItems,
        )..where((i) => i.id.equals(id))).write(change);
        await _touch(listId, const ShoppingListsCompanion());
      });

  Future<void> _touch(int id, ShoppingListsCompanion change) =>
      (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
        change.copyWith(updatedAt: Value(_now())),
      );

  ShoppingListInfo _info(
    ShoppingListRow row,
    int total,
    int done,
    Map<int, DateTime> used,
  ) => ShoppingListInfo(
    lastUsed: used[row.id],
    id: row.id,
    name: row.name,
    updatedAt: row.updatedAt,
    order: ListOrder.parse(row.sortMode),
    categoryOrder: [
      for (final c in (row.categoryOrder ?? '').split(','))
        if (c.isNotEmpty) ItemCategory.parse(c),
    ],
    itemCount: total,
    doneCount: done,
  );

  ListItem _item(ListItemRow r) => ListItem(
    id: r.id,
    name: r.name,
    quantity: r.quantity,
    unit: r.unit,
    category: ItemCategory.parse(r.category),
    position: r.position,
    done: r.done,
    createdAt: r.createdAt,
  );
}
