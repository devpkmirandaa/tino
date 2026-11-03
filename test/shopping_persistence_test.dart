import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/database/tino_database.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/money.dart';

void main() {
  late TinoDatabase db;
  setUp(() => db = TinoDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('compra ativa sobrevive a reabrir o app', () async {
    final first = container();
    await first.read(shoppingProvider.future);
    final ctrl = first.read(shoppingProvider.notifier)
      ..add(UnitItem(id: 'a', name: 'Arroz', price: Money(2490), quantity: 2))
      ..add(
        WeightItem(
          id: 'b',
          name: 'Tomate',
          pricePerKg: Money(899),
          grams: 1250,
        ),
      )
      ..setBudget(Money(10000));
    ctrl.replace(
      UnitItem(id: 'a', name: 'Arroz', price: Money(2290), quantity: 2),
    );
    ctrl.remove('nada');
    await ctrl.flush();

    final reopened = await container().read(shoppingProvider.future);
    expect(reopened.budget, Money(10000));
    expect(reopened.cart.items.map((i) => i.id), ['a', 'b']);
    expect(reopened.cart.total, Money(4580 + 1124));
    final tomato = reopened.cart.items[1] as WeightItem;
    expect(tomato.grams, 1250);
    expect(tomato.pricePerKg, Money(899));
  });

  test('remover itens e orçamento também é gravado', () async {
    final first = container();
    await first.read(shoppingProvider.future);
    final ctrl = first.read(shoppingProvider.notifier)
      ..add(UnitItem(id: 'a', name: 'Pão', price: Money(100)))
      ..setBudget(Money(5000));
    ctrl
      ..remove('a')
      ..setBudget(null);
    await ctrl.flush();

    final reopened = await container().read(shoppingProvider.future);
    expect(reopened.cart.items, isEmpty);
    expect(reopened.budget, isNull);
    expect(await db.select(db.purchases).get(), hasLength(1));
  });

  test("finalizar move a compra para o histórico e abre uma nova", () async {
    final c = container();
    await c.read(shoppingProvider.future);
    final ctrl = c.read(shoppingProvider.notifier)
      ..add(UnitItem(id: "a", name: "Café", price: Money(1890)))
      ..setBudget(Money(5000));
    await ctrl.finish();
    expect(c.read(shoppingProvider).requireValue.cart.items, isEmpty);

    ctrl.add(UnitItem(id: "b", name: "Leite", price: Money(549)));
    await ctrl.flush();
    await ctrl.finish();

    final history = await c.read(historyProvider.future);
    expect(history.map((p) => p.cart.items.single.name), ["Leite", "Café"]);
    expect(history.last.budget, Money(5000));
    expect(history.last.cart.total, Money(1890));

    final reopened = await container().read(shoppingProvider.future);
    expect(reopened.cart.items, isEmpty);
    expect(reopened.budget, isNull);
  });
}
