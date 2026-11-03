import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tino_database.dart';
import '../application/shopping_controller.dart';
import '../domain/cart.dart';
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
      budget: switch (purchase.budgetCents) {
        final c? => Money(c),
        null => null,
      },
    );
  }

  Future<void> saveActive(ShoppingSession session) => _db.transaction(() async {
    final id =
        (await _active())?.id ??
        await _db
            .into(_db.purchases)
            .insert(PurchasesCompanion.insert(startedAt: DateTime.now()));
    await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(
      PurchasesCompanion(budgetCents: Value(session.budget?.cents)),
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

  static CartItem _toItem(PurchaseItem r) => r.kind == 1
      ? WeightItem(
          id: r.id,
          name: r.name,
          pricePerKg: Money(r.priceCents),
          grams: r.amount,
        )
      : UnitItem(
          id: r.id,
          name: r.name,
          price: Money(r.priceCents),
          quantity: r.amount,
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
      );
}
