import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/lists/data/lists_repository.dart';
import 'package:tino/features/lists/domain/shopping_list.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/data/shopping_repository.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/finished_purchase.dart';
import 'package:tino/features/shopping/domain/money.dart';

import 'support/memory_database.dart';

void main() {
  test('mercado: sem espaços nas pontas; vazio vira nulo', () {
    expect(cleanPlace('  Atacadão   Centro '), 'Atacadão Centro');
    expect(cleanPlace('   '), isNull);
    expect(cleanPlace(null), isNull);
  });

  test('selo diz quanto sobrou ou passou do orçamento', () {
    const budget = Money(15000);
    expect(budgetSeal(const Money(2550), null), isNull);
    expect(budgetSeal(const Money(12550), budget), (
      text: 'Sobraram R\$ 24,50 do orçamento',
      over: false,
    ));
    expect(budgetSeal(const Money(15840), budget), (
      text: 'Passou R\$ 8,40 do orçamento',
      over: true,
    ));
  });

  test('concluir guarda o mercado e desmarca a lista usada', () async {
    final c = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(c.dispose);
    final lists = c.read(listsRepositoryProvider);
    final listId = await lists.createList('Mês');
    final arroz = await lists.addItem(
      listId,
      name: 'Arroz',
      category: ItemCategory.mercearia,
    );
    await lists.addItem(listId, name: 'Café', category: ItemCategory.mercearia);
    await lists.setDone(listId, arroz, true);

    await c.read(shoppingProvider.future);
    final shopping = c.read(shoppingProvider.notifier)
      ..setList(listId)
      ..add(UnitItem(id: 'a', name: 'Arroz', price: const Money(2490)));
    await shopping.finish(place: ' Mercado do Zé ');

    final history = await c.read(shoppingRepositoryProvider).history();
    expect(history.single.place, 'Mercado do Zé');
    expect(history.single.cart.total, const Money(2490));
    // Pronta para a próxima compra: nada marcado, os itens continuam.
    final items = await lists.items(listId);
    expect(items.map((i) => i.name), containsAll(['Arroz', 'Café']));
    expect(items.where((i) => i.done), isEmpty);
    expect(c.read(shoppingProvider).value!.cart.items, isEmpty);
    expect(c.read(shoppingProvider).value!.listId, isNull);
  });

  test('concluir sem mercado grava nulo', () async {
    final c = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(c.dispose);
    await c.read(shoppingProvider.future);
    final shopping = c.read(shoppingProvider.notifier)
      ..add(UnitItem(id: 'a', name: 'Pão', price: const Money(100)));
    await shopping.finish(place: '  ');
    final history = await c.read(shoppingRepositoryProvider).history();
    expect(history.single.place, isNull);
  });
}
