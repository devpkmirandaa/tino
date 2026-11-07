import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/lists/application/list_shopping_link.dart';
import 'package:tino/features/lists/application/lists_providers.dart';
import 'package:tino/features/lists/data/lists_repository.dart';
import 'package:tino/features/lists/domain/list_matcher.dart';
import 'package:tino/features/lists/domain/shopping_list.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/money.dart';

import 'support/memory_database.dart';

void main() {
  group('produto do carrinho × item da lista', () {
    final t0 = DateTime(2026, 11, 5);
    ListItem item(
      int id,
      String name, {
      bool done = false,
      ItemCategory category = ItemCategory.outros,
    }) => ListItem(
      id: id,
      name: name,
      category: category,
      position: id,
      createdAt: t0.add(Duration(minutes: id)),
      done: done,
    );

    test('todas as palavras do item: confiante', () {
      final items = [
        item(1, 'Leite'),
        item(2, 'Leite condensado'),
        item(3, 'Coca 2L'),
        item(4, 'Tomates'),
      ];
      expect(bestMatch('Leite integral UHT', items)?.item.id, 1);
      expect(bestMatch('Leite Condensado Moça', items)?.item.id, 2);
      expect(bestMatch('Refrigerante Coca-Cola 2L', items)?.item.id, 3);
      expect(bestMatch('Tomate salada', items)!.confident, isTrue);
      expect(bestMatch('Iogurte natural', items), isNull);
    });

    test('casos reais: tapioca e escova de dentes', () {
      final tapioca = bestMatch('Goma de tapioca', [
        item(1, 'Tapioca', category: ItemCategory.mercearia),
      ])!;
      expect(tapioca.item.id, 1);
      expect(tapioca.confident, isTrue);
      final escova = bestMatch('Escova dental macia', [
        item(2, 'Escova de dentes', category: ItemCategory.higiene),
      ])!;
      expect(escova.confident, isTrue);
    });

    test('só a palavra principal: pergunta antes', () {
      final m = bestMatch('Escova de cabelo', [item(1, 'Escova de dentes')])!;
      expect(m.confident, isFalse);
      expect(
        bestMatch('Pasta de dente', [item(2, 'Escova de dentes')]),
        isNull,
      );
    });

    test('categorias diferentes não casam', () {
      expect(
        bestMatch('Sabonete de leite', [
          item(1, 'Leite', category: ItemCategory.laticinios),
        ]),
        isNull,
      );
    });

    test('família de palavra e sinônimos', () {
      expect(bestMatch('Creme dental', [item(1, 'Pasta de dente')]), isNotNull);
      expect(bestMatch('Refrigerante guaraná', [item(2, 'Refri')]), isNotNull);
      expect(bestMatch('Tomatinho cereja', [item(3, 'Tomate')]), isNotNull);
      expect(bestMatch('Franja de bolo', [item(4, 'Frango')]), isNull);
    });

    test('par aprendido decide: confirmado risca, desfeito não casa', () {
      final items = [item(1, 'Ração')];
      expect(
        bestMatch(
          'Whiskas sachê',
          items,
          learnedPairs: {pairKey('Whiskas sachê', 'Ração'): true},
        )!.confident,
        isTrue,
      );
      expect(
        bestMatch(
          'Ração Golden',
          items,
          learnedPairs: {pairKey('Ração Golden', 'Ração'): false},
        ),
        isNull,
      );
    });

    test('ignora itens já riscados e tolera uma letra', () {
      final items = [item(1, 'Detergente', done: true), item(2, 'Detergente')];
      expect(bestMatch('Detergete Ypê', items)?.item.id, 2);
    });
  });

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('com lista ligada: risca sozinho e avisa', () async {
    final container = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(container.dispose);
    container.listen(listShoppingLinkProvider, (_, _) {});
    final repo = container.read(listsRepositoryProvider);
    final listId = await repo.createList('Mês');
    await repo.addItem(
      listId,
      name: 'Tapioca',
      category: ItemCategory.mercearia,
    );
    await repo.addItem(listId, name: 'Café', category: ItemCategory.mercearia);

    final shopping = container.read(shoppingProvider.notifier);
    await container.read(shoppingProvider.future);
    final cartId = shopping.newId();
    shopping
      ..setList(listId)
      ..add(
        UnitItem(
          id: cartId,
          name: 'Goma de tapioca',
          price: Money(1014),
          quantity: 1,
        ),
      );
    await settle();

    final items = await repo.items(listId);
    final tapioca = items.firstWhere((i) => i.name == 'Tapioca');
    expect(tapioca.done, isTrue);
    expect(items.firstWhere((i) => i.name == 'Café').done, isFalse);
    final feedback = container.read(listFeedbackProvider);
    expect(feedback, isA<AutoChecked>());
    expect(feedback!.itemName, 'Tapioca');
    // Desfazer no scanner encontra o riscado pela linha do carrinho.
    final checks = container.read(autoChecksProvider.notifier);
    expect(checks.take(cartId), (listId: listId, itemId: tapioca.id));
    expect(checks.take(cartId), isNull);
  });

  test('item sem nome não risca nem pergunta', () async {
    final container = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(container.dispose);
    container.listen(listShoppingLinkProvider, (_, _) {});
    final repo = container.read(listsRepositoryProvider);
    final listId = await repo.createList('Mês');
    await repo.addItem(listId, name: 'Café', category: ItemCategory.mercearia);

    final shopping = container.read(shoppingProvider.notifier);
    await container.read(shoppingProvider.future);
    shopping
      ..setList(listId)
      ..add(UnitItem(id: shopping.newId(), name: '', price: Money(749)));
    await settle();

    expect((await repo.items(listId)).single.done, isFalse);
    expect(container.read(listFeedbackProvider), isNull);
  });

  test('sem lista ligada: não risca, pergunta e sugere a lista', () async {
    final container = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(container.dispose);
    container.listen(listShoppingLinkProvider, (_, _) {});
    final repo = container.read(listsRepositoryProvider);
    final listId = await repo.createList('Mês');
    await repo.addItem(
      listId,
      name: 'Tapioca',
      category: ItemCategory.mercearia,
    );

    final shopping = container.read(shoppingProvider.notifier);
    await container.read(shoppingProvider.future);
    shopping.add(
      UnitItem(
        id: shopping.newId(),
        name: 'Goma de tapioca',
        price: Money(1014),
        quantity: 1,
      ),
    );
    await settle();

    expect((await repo.items(listId)).single.done, isFalse);
    final feedback = container.read(listFeedbackProvider);
    expect(feedback, isA<SuggestCheck>());
    expect((feedback! as SuggestCheck).listName, 'Mês');
  });

  test('a lista ligada fica salva na compra ativa', () async {
    final first = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(first.dispose);
    await first.read(shoppingProvider.future);
    first.read(shoppingProvider.notifier).setList(7);
    await first.read(shoppingProvider.notifier).flush();
    expect(first.read(shoppingProvider).value!.listId, 7);

    first.invalidate(shoppingProvider);
    expect((await first.read(shoppingProvider.future)).listId, 7);

    await first.read(shoppingProvider.notifier).finish();
    expect(first.read(shoppingProvider).value!.listId, isNull);
  });

  test('aprende pares respondidos', () async {
    final container = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(container.dispose);
    final actions = container.read(listsActionsProvider);
    await actions.learnPair('Whiskas sachê', 'Ração', true);
    await actions.learnPair('Ração Golden', 'Ração', false);
    final pairs = await container.read(learnedPairsProvider.future);
    expect(pairs[pairKey('Whiskas sachê', 'Ração')], isTrue);
    expect(pairs[pairKey('Ração Golden', 'Ração')], isFalse);
  });
}
