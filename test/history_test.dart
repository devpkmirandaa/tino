import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/database/tino_database.dart';
import 'package:tino/features/history/domain/history_summary.dart';
import 'package:tino/features/lists/data/lists_repository.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/data/shopping_repository.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/finished_purchase.dart';
import 'package:tino/features/shopping/domain/money.dart';

import 'support/memory_database.dart';

FinishedPurchase purchase(
  int id,
  DateTime at, {
  List<int> prices = const [1000],
  Money? budget,
  String? listName,
}) => FinishedPurchase(
  id: id,
  finishedAt: at,
  cart: Cart([
    for (final (i, cents) in prices.indexed)
      UnitItem(id: '$id-$i', name: 'Item $i', price: Money(cents)),
  ]),
  budget: budget,
  listName: listName,
);

void main() {
  final now = DateTime(2026, 11, 8, 15);

  group('mês atual × anterior', () {
    test('soma valor e conta compras de cada mês', () {
      final r = monthComparison([
        purchase(1, DateTime(2026, 11, 2), prices: [1000, 550]),
        purchase(2, DateTime(2026, 10, 28), prices: [18740]),
        purchase(3, DateTime(2026, 10, 21), prices: [6490]),
        purchase(4, DateTime(2025, 10, 21), prices: [999]),
      ], now);
      expect(r.current.month, 11);
      expect(r.current.total, const Money(1550));
      expect(r.current.count, 1);
      expect(r.previous.month, 10);
      expect(r.previous.total, const Money(25230));
      expect(r.previous.count, 2);
    });

    test('janeiro compara com dezembro do ano anterior', () {
      final r = monthComparison([
        purchase(1, DateTime(2026, 12, 30)),
      ], DateTime(2027, 1, 5));
      expect((r.previous.year, r.previous.month), (2026, 12));
      expect(r.previous.count, 1);
      expect(r.current.count, 0);
      expect(r.current.total, Money.zero);
    });

    test('contagem de compras', () {
      expect(purchaseCount(0), 'Nenhuma compra');
      expect(purchaseCount(1), '1 compra');
      expect(purchaseCount(2), '2 compras');
    });
  });

  group('lista do Histórico', () {
    test('agrupa por mês, mais recente primeiro; outro ano leva o ano', () {
      final groups = groupByMonth([
        purchase(1, DateTime(2026, 10, 21)),
        purchase(2, DateTime(2026, 11, 8, 10)),
        purchase(3, DateTime(2025, 10, 3)),
        purchase(4, DateTime(2026, 10, 28)),
      ], now);
      expect(
        [for (final g in groups) g.label],
        ['Novembro', 'Outubro', 'Outubro de 2025'],
      );
      expect([for (final p in groups[1].purchases) p.id], [4, 1]);
    });

    test('Hoje, Ontem ou dia do mês, por dia de calendário', () {
      expect(purchaseDay(DateTime(2026, 11, 8, 0, 5), now), 'Hoje');
      expect(purchaseDay(DateTime(2026, 11, 7, 23, 59), now), 'Ontem');
      expect(purchaseDay(DateTime(2026, 10, 28), now), '28 de outubro');
      expect(purchaseDay(DateTime(2025, 3, 1), now), '1 de março de 2025');
      // Virada de mês: 1º de dezembro, ontem é 30 de novembro.
      expect(
        purchaseDay(DateTime(2026, 11, 30, 20), DateTime(2026, 12, 1, 8)),
        'Ontem',
      );
    });

    test('apoio: lista, senão orçamento, senão só os itens', () {
      final at = DateTime(2026, 11, 2);
      expect(
        purchaseLine(
          purchase(
            1,
            at,
            prices: [1, 2],
            listName: 'Compra do mês',
            budget: const Money(1),
          ),
        ),
        '2 itens · Compra do mês',
      );
      expect(
        purchaseLine(purchase(2, at, budget: const Money(5000))),
        '1 item · dentro do orçamento',
      );
      expect(
        purchaseLine(purchase(3, at, budget: const Money(1000))),
        '1 item · dentro do orçamento',
      );
      expect(
        purchaseLine(purchase(4, at, budget: const Money(999))),
        '1 item · passou do orçamento',
      );
      expect(
        purchaseLine(purchase(5, at, prices: List.filled(9, 1))),
        '9 itens',
      );
    });
  });

  group('Resumo da compra', () {
    test('título e subtítulo', () {
      final p = purchase(
        1,
        DateTime(2026, 11, 3, 18),
        prices: List.filled(18, 100),
        listName: 'Lista do mês',
      );
      expect(dayMonth(p.finishedAt, now), '3 de novembro');
      expect(summarySubtitle(p), 'Terça · 18 itens · Lista do mês');
      expect(
        summarySubtitle(purchase(2, DateTime(2026, 11, 8))),
        'Domingo · 1 item',
      );
      expect(dayMonth(DateTime(2025, 12, 24), now), '24 de dezembro de 2025');
    });
  });

  group('nome da lista guardado ao concluir', () {
    test('renomear ou apagar a lista depois não muda o Histórico', () async {
      final c = ProviderContainer(overrides: [memoryDatabase]);
      addTearDown(c.dispose);
      final lists = c.read(listsRepositoryProvider);
      final listId = await lists.createList('Compra do mês');
      await c.read(shoppingProvider.future);
      final shopping = c.read(shoppingProvider.notifier)
        ..setList(listId)
        ..add(UnitItem(id: 'a', name: 'Arroz', price: const Money(2490)));
      await shopping.finish();

      final repo = c.read(shoppingRepositoryProvider);
      final id = (await repo.history()).single.id;
      // A compra nova fica marcada para o M3c do Histórico.
      expect(c.read(freshPurchaseProvider), id);

      await lists.renameList(listId, 'Outro nome');
      expect((await repo.history()).single.listName, 'Compra do mês');
      await lists.deleteList(listId);
      expect((await repo.history()).single.listName, 'Compra do mês');
    });

    test('compra antiga sem nome guardado usa o nome atual', () async {
      final c = ProviderContainer(overrides: [memoryDatabase]);
      addTearDown(c.dispose);
      final db = c.read(databaseProvider);
      final listId = await c
          .read(listsRepositoryProvider)
          .createList('Churrasco');
      final when = DateTime(2026, 10, 1, 12);
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              startedAt: when,
              finishedAt: Value(when),
              listId: Value(listId),
            ),
          );
      final repo = c.read(shoppingRepositoryProvider);
      expect((await repo.history()).single.listName, 'Churrasco');
    });

    test('sem compra ativa, concluir não devolve compra', () async {
      final c = ProviderContainer(overrides: [memoryDatabase]);
      addTearDown(c.dispose);
      expect(await c.read(shoppingRepositoryProvider).finishActive(), isNull);
    });
  });
}
