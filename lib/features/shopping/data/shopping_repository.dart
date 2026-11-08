import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tino_database.dart';
import '../application/shopping_controller.dart';
import '../domain/cart.dart';
import '../domain/finished_purchase.dart';
import '../domain/money.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(databaseProvider)),
);

/// Guarda a compra ativa. Cada alteração regrava os itens numa transação.
class ShoppingRepository {
  ShoppingRepository(this._db);
  final TinoDatabase _db;

  Future<Purchase?> _active() =>
      (_db.select(_db.purchases)
            ..where((p) => p.finishedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

  Future<ShoppingSession> loadActive() async {
    final purchase = await _active();
    if (purchase == null) return const ShoppingSession();
    final rows =
        await (_db.select(_db.purchaseItems)
              ..where((i) => i.purchaseId.equals(purchase.id))
              ..orderBy([(i) => OrderingTerm(expression: i.position)]))
            .get();
    return ShoppingSession(
      cart: Cart([for (final r in rows) _toItem(r)]),
      budget: _budget(purchase.budgetCents),
      listId: purchase.listId,
    );
  }

  Future<void> saveActive(ShoppingSession session) => _db.transaction(() async {
    final id =
        (await _active())?.id ??
        await _db
            .into(_db.purchases)
            .insert(PurchasesCompanion.insert(startedAt: DateTime.now()));
    await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(
      PurchasesCompanion(
        budgetCents: Value(session.budget?.cents),
        listId: Value(session.listId),
      ),
    );
    await (_db.delete(
      _db.purchaseItems,
    )..where((i) => i.purchaseId.equals(id))).go();
    await _db.batch(
      (b) => b.insertAll(_db.purchaseItems, [
        for (final (i, item) in session.cart.items.indexed) _toRow(item, id, i),
      ]),
    );
  });

  /// Marca a compra ativa como finalizada agora, com o mercado, se houver,
  /// e o nome atual da lista usada. Devolve o id da compra (nulo se não
  /// havia compra ativa).
  Future<int?> finishActive({String? place}) => _db.transaction(() async {
    final active = await _active();
    if (active == null) return null;
    final listName = switch (active.listId) {
      null => null,
      final id => await _listName(id),
    };
    await (_db.update(
      _db.purchases,
    )..where((p) => p.id.equals(active.id))).write(
      PurchasesCompanion(
        finishedAt: Value(DateTime.now()),
        place: Value(place),
        listName: Value(listName),
      ),
    );
    return active.id;
  });

  Future<String?> _listName(int id) async => (await (_db.select(
    _db.shoppingLists,
  )..where((l) => l.id.equals(id))).getSingleOrNull())?.name;

  /// Compras finalizadas, da mais recente para a mais antiga.
  Future<List<FinishedPurchase>> history() async {
    final purchases =
        await (_db.select(_db.purchases)
              ..where((p) => p.finishedAt.isNotNull())
              ..orderBy([
                (p) => OrderingTerm.desc(p.finishedAt),
                (p) => OrderingTerm.desc(p.id),
              ]))
            .get();
    if (purchases.isEmpty) return const [];
    final rows =
        await (_db.select(_db.purchaseItems)
              ..where((i) => i.purchaseId.isIn(purchases.map((p) => p.id)))
              ..orderBy([(i) => OrderingTerm(expression: i.position)]))
            .get();
    final items = <int, List<CartItem>>{};
    for (final r in rows) {
      items.putIfAbsent(r.purchaseId, () => []).add(_toItem(r));
    }
    // Compras de antes da versão 8 não guardaram o nome: usa o atual, se a
    // lista ainda existir.
    final names = {
      for (final l in await _db.select(_db.shoppingLists).get()) l.id: l.name,
    };
    return [
      for (final p in purchases)
        FinishedPurchase(
          id: p.id,
          finishedAt: p.finishedAt!,
          cart: Cart(items[p.id] ?? const []),
          budget: _budget(p.budgetCents),
          place: p.place,
          listName: p.listName ?? names[p.listId],
        ),
    ];
  }

  static Money? _budget(int? cents) => cents == null ? null : Money(cents);

  static CartItem _toItem(PurchaseItem r) => r.kind == 1
      ? WeightItem(
          id: r.id,
          name: r.name,
          pricePerKg: Money(r.priceCents),
          grams: r.amount,
          tagText: r.tagText,
        )
      : UnitItem(
          id: r.id,
          name: r.name,
          price: Money(r.priceCents),
          quantity: r.amount,
          tagText: r.tagText,
        );

  static PurchaseItemsCompanion _toRow(CartItem item, int purchaseId, int i) =>
      PurchaseItemsCompanion.insert(
        id: item.id,
        purchaseId: purchaseId,
        position: i,
        name: item.name,
        kind: item is WeightItem ? 1 : 0,
        priceCents: switch (item) {
          UnitItem(:final price) => price.cents,
          WeightItem(:final pricePerKg) => pricePerKg.cents,
        },
        amount: switch (item) {
          UnitItem(:final quantity) => quantity,
          WeightItem(:final grams) => grams,
        },
        tagText: Value(item.tagText),
      );
}
