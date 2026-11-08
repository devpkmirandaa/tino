import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/database/tino_database.dart';
import 'package:tino/features/lists/data/lists_repository.dart';
import 'package:tino/features/lists/domain/frequent_items.dart';
import 'package:tino/features/lists/domain/shopping_list.dart';

void main() {
  group('nome digitado ou corrigido pela pessoa', () {
    test('sem texto de etiqueta: digitado', () {
      expect(typedByPerson('Arroz', null), isTrue);
    });

    test('nome que veio da leitura não conta, cru ou arrumado', () {
      expect(
        typedByPerson('Leite integral UHT', 'LEITE INTEGRAL UHT'),
        isFalse,
      );
      expect(
        typedByPerson('LEITE INTEGRAL UHT', 'LEITE INTEGRAL UHT'),
        isFalse,
      );
      expect(typedByPerson('Iogurte', 'I0GURTE'), isFalse);
    });

    test('nome trocado pela pessoa conta', () {
      expect(typedByPerson('Leite', 'LEITE INTEGRAL UHT'), isTrue);
      expect(typedByPerson('Café', 'CAFE PILAO 500G'), isTrue);
    });
  });

  group('você costuma levar', () {
    final t0 = DateTime(2026, 11, 1, 18);
    PastPurchase purchase(
      int day, {
      List<String> list = const [],
      List<({String name, String? tagText})> products = const [],
    }) => (
      finishedAt: t0.add(Duration(days: day)),
      products: products,
      listItems: list,
    );
    ListItem item(String name, {bool done = false}) => ListItem(
      id: name.hashCode,
      name: name,
      category: ItemCategory.outros,
      position: 0,
      createdAt: t0,
      done: done,
    );

    test('só entra quem aparece em 2 compras ou mais', () {
      final r = frequentItems([
        purchase(0, list: ['Ovos', 'Banana']),
        purchase(1, list: ['Ovos']),
      ], const []);
      expect(r, ['Ovos']);
    });

    test('sem histórico, nenhum chip', () {
      expect(frequentItems(const [], const []), isEmpty);
    });

    test('nome repetido na mesma compra conta uma vez', () {
      final r = frequentItems([
        purchase(0, list: ['Ovos'], products: [(name: 'ovos', tagText: null)]),
      ], const []);
      expect(r, isEmpty);
    });

    test('produto com nome da leitura não conta; corrigido conta', () {
      final r = frequentItems([
        purchase(0, products: [(name: 'Café Pilão', tagText: 'CAFE PILAO')]),
        purchase(1, products: [(name: 'Café Pilão', tagText: 'CAFE PILAO')]),
        purchase(2, products: [(name: 'Açúcar', tagText: 'ACUCAR UNIAO 1KG')]),
        purchase(3, products: [(name: 'Açúcar', tagText: null)]),
      ], const []);
      expect(r, ['Açúcar']);
    });

    test('lista e produtos somam; mais frequente primeiro, depois recente', () {
      final r = frequentItems([
        purchase(0, list: ['Pão francês', 'Banana']),
        purchase(1, list: ['Pão francês', 'Banana']),
        purchase(2, products: [(name: 'Pão francês', tagText: null)]),
        purchase(3, list: ['Ovos']),
        purchase(4, list: ['Ovos']),
      ], const []);
      expect(r, ['Pão francês', 'Ovos', 'Banana']);
    });

    test('mostra a grafia mais recente', () {
      final r = frequentItems([
        purchase(0, list: ['ovos']),
        purchase(1, list: ['Ovos']),
      ], const []);
      expect(r, ['Ovos']);
    });

    test('o que já está na lista, marcado ou não, sai dos chips', () {
      final past = [
        purchase(0, list: ['Arroz', 'Ovos', 'Banana']),
        purchase(1, list: ['Arroz', 'Ovos', 'Banana']),
      ];
      final r = frequentItems(past, [
        item('Arroz integral'),
        item('ovo', done: true),
      ]);
      expect(r, ['Banana']);
    });

    test('filtra pelo que está sendo digitado, sem acento e caixa', () {
      final past = [
        purchase(0, list: ['Arroz', 'Arroz integral', 'Açúcar', 'Pão francês']),
        purchase(1, list: ['Arroz', 'Arroz integral', 'Açúcar', 'Pão francês']),
      ];
      expect(frequentItems(past, const [], query: 'ARR'), [
        'Arroz',
        'Arroz integral',
      ]);
      expect(frequentItems(past, const [], query: 'acu'), ['Açúcar']);
      expect(frequentItems(past, const [], query: 'pao fr'), ['Pão francês']);
      expect(frequentItems(past, const [], query: 'xyz'), isEmpty);
      expect(frequentItems(past, const [], query: '  ').length, 4);
    });

    test('no máximo 8', () {
      final names = [for (var i = 0; i < 10; i++) 'Item$i'];
      final r = frequentItems([
        purchase(0, list: names),
        purchase(1, list: names),
      ], const []);
      expect(r.length, 8);
    });
  });

  group('banco', () {
    late TinoDatabase db;
    late ListsRepository repo;
    setUp(() {
      db = TinoDatabase(NativeDatabase.memory());
      repo = ListsRepository(db);
    });
    tearDown(() => db.close());

    test('compras finalizadas com produtos e itens da lista usada', () async {
      final list = await repo.createList('Mês');
      await repo.addItem(list, name: 'Ovos', category: ItemCategory.outros);
      final when = DateTime(2026, 11, 1, 18);
      final done = await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              startedAt: when,
              finishedAt: Value(when),
              listId: Value(list),
            ),
          );
      // Compra ativa não entra.
      final active = await db
          .into(db.purchases)
          .insert(PurchasesCompanion.insert(startedAt: when));
      for (final (id, purchase) in [('a', done), ('b', active)]) {
        await db
            .into(db.purchaseItems)
            .insert(
              PurchaseItemsCompanion.insert(
                id: id,
                purchaseId: purchase,
                position: 0,
                name: 'Leite',
                kind: 0,
                priceCents: 500,
                amount: 1,
                tagText: const Value('LEITE UHT'),
              ),
            );
      }
      final past = await repo.pastPurchases();
      expect(past.single.finishedAt, when);
      expect(past.single.listItems, ['Ovos']);
      expect(past.single.products.single, (
        name: 'Leite',
        tagText: 'LEITE UHT',
      ));
    });
  });
}
