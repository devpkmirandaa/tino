import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tino/core/database/tino_database.dart';
import 'package:tino/core/theme/tino_theme.dart';
import 'package:tino/features/lists/data/lists_repository.dart';
import 'package:tino/features/lists/domain/category_suggester.dart';
import 'package:tino/features/lists/domain/shopping_list.dart';
import 'package:tino/features/lists/presentation/list_detail_page.dart';
import 'package:tino/features/lists/presentation/lists_page.dart';

import 'support/memory_database.dart';

void main() {
  group('categoria sugerida pelo nome', () {
    test('palavras e plurais', () {
      expect(suggestCategory('Tomates'), ItemCategory.hortifruti);
      expect(suggestCategory('Banana prata'), ItemCategory.hortifruti);
      expect(suggestCategory('Peito de frango'), ItemCategory.carnes);
      expect(suggestCategory('Leite integral'), ItemCategory.laticinios);
      expect(suggestCategory('Pães de forma'), ItemCategory.padaria);
      expect(suggestCategory('Arroz 5kg'), ItemCategory.mercearia);
      expect(suggestCategory('Detergente Ypê'), ItemCategory.limpeza);
      expect(suggestCategory('Papel higiênico'), ItemCategory.higiene);
      expect(suggestCategory('Refrigerante 2L'), ItemCategory.bebidas);
      expect(suggestCategory('Ração gato'), ItemCategory.pet);
    });

    test('expressões vencem palavras soltas', () {
      expect(suggestCategory('Leite condensado'), ItemCategory.mercearia);
      expect(suggestCategory('Água sanitária'), ItemCategory.limpeza);
      expect(suggestCategory('Água mineral'), ItemCategory.bebidas);
      expect(suggestCategory('Peito de peru'), ItemCategory.laticinios);
    });

    test('a primeira palavra conhecida decide', () {
      expect(suggestCategory('Molho de tomate'), ItemCategory.mercearia);
      expect(suggestCategory('Suco de laranja'), ItemCategory.bebidas);
      expect(suggestCategory('Bolo de cenoura'), ItemCategory.padaria);
      expect(suggestCategory('Iogurte de morango'), ItemCategory.laticinios);
      expect(suggestCategory('Sabão em pó'), ItemCategory.limpeza);
      // Marca desconhecida na frente é pulada.
      expect(suggestCategory('Sadia frango inteiro'), ItemCategory.carnes);
    });

    test('vocabulário maior, marcas e erro de uma letra', () {
      expect(suggestCategory('Limões'), ItemCategory.hortifruti);
      expect(suggestCategory('Berinjela'), ItemCategory.hortifruti);
      expect(suggestCategory('Fraldinha'), ItemCategory.carnes);
      expect(suggestCategory('Requeijão cremoso'), ItemCategory.laticinios);
      expect(suggestCategory('Nescau 400g'), ItemCategory.mercearia);
      expect(suggestCategory('Omo líquido'), ItemCategory.limpeza);
      expect(suggestCategory('Heineken lata'), ItemCategory.bebidas);
      expect(suggestCategory('Whiskas sachê'), ItemCategory.pet);
      expect(suggestCategory('Detergete'), ItemCategory.limpeza);
      expect(suggestCategory('Bananna'), ItemCategory.hortifruti);
    });

    test('aprende com a escolha do usuário', () {
      final learned = {
        categoryKey('Pão de alho'): ItemCategory.carnes,
        headKey('Carvão vegetal'): ItemCategory.outros,
      };
      expect(categoryKey('  Pão de ALHO '), 'pao de alho');
      expect(headKey('Carvão vegetal 5kg'), '#carvao');
      expect(
        suggestCategory('pão de alho', learned: learned),
        ItemCategory.carnes,
      );
      expect(
        suggestCategory('Pão de forma', learned: learned),
        ItemCategory.padaria,
      );
      expect(
        suggestCategory('Carvão grande', learned: learned),
        ItemCategory.outros,
      );
    });

    test('sem confusão por começo de palavra; desconhecido é Outros', () {
      expect(suggestCategory('Macarrão'), ItemCategory.mercearia);
      expect(suggestCategory('Carvão vegetal'), ItemCategory.outros);
      expect(suggestCategory(''), ItemCategory.outros);
    });
  });

  group('arranjo da lista', () {
    final t0 = DateTime(2026, 11, 5, 10);
    ListItem item(
      int id,
      String name,
      ItemCategory c, {
      bool done = false,
      int position = 0,
    }) => ListItem(
      id: id,
      name: name,
      category: c,
      position: position,
      createdAt: t0.add(Duration(minutes: id)),
      done: done,
    );

    final items = [
      item(1, 'Detergente', ItemCategory.limpeza),
      item(2, 'Tomate', ItemCategory.hortifruti),
      item(3, 'Leite', ItemCategory.laticinios, done: true),
      item(4, 'Banana', ItemCategory.hortifruti),
    ];

    test('por categoria: seções na ordem do mercado, marcados no lugar', () {
      final r = arrangeList(items, ListOrder.category);
      expect(
        [for (final s in r) s.category],
        [
          ItemCategory.hortifruti,
          ItemCategory.laticinios,
          ItemCategory.limpeza,
        ],
      );
      expect([for (final i in r.first.items) i.name], ['Tomate', 'Banana']);
      // Marcado continua na sua categoria, não vai pro fim.
      expect(r[1].items.single.name, 'Leite');
      expect(r[1].items.single.done, isTrue);
    });

    test('ordem das categorias escolhida vem antes das outras', () {
      final r = arrangeList(
        items,
        ListOrder.category,
        categoryOrder: [ItemCategory.limpeza],
      );
      expect(r.first.category, ItemCategory.limpeza);
      expect(r[1].category, ItemCategory.hortifruti);
    });

    test('manual: uma lista só, na posição arrastada, marcados no lugar', () {
      final r = arrangeList([
        item(1, 'Tomate', ItemCategory.hortifruti, position: 2),
        item(2, 'Banana', ItemCategory.hortifruti, position: 0),
        item(3, 'Detergente', ItemCategory.limpeza, position: 1, done: true),
      ], ListOrder.manual);
      expect(r.single.category, isNull);
      expect(
        [for (final i in r.single.items) i.name],
        ['Banana', 'Detergente', 'Tomate'],
      );
    });

    test('separa o que falta do que já está no carrinho', () {
      final (:pending, :done) = splitDone(items);
      expect(
        [for (final i in pending) i.name],
        ['Detergente', 'Tomate', 'Banana'],
      );
      expect(done.single.name, 'Leite');
      // A Lista só arruma os que faltam: nenhum marcado nas seções.
      final r = arrangeList(pending, ListOrder.category);
      expect(r.expand((s) => s.items).any((i) => i.done), isFalse);
    });

    test('apoio da linha só quando diz algo além de 1 unidade', () {
      ListItem withAmount(int q, String unit) => ListItem(
        id: 1,
        name: 'Arroz',
        category: ItemCategory.mercearia,
        position: 0,
        createdAt: t0,
        quantity: q,
        unit: unit,
      );
      expect(itemDetail(withAmount(1, 'un')), isNull);
      expect(itemDetail(withAmount(3, 'un')), '3 unidades');
      expect(itemDetail(withAmount(2, 'kg')), '2 kg');
    });

    test('"ordem de adição" antiga é lida como por categoria', () {
      expect(ListOrder.parse('added'), ListOrder.category);
      expect(ListOrder.parse('manual'), ListOrder.manual);
      expect(ListOrder.parse(null), ListOrder.category);
    });

    test('Organizar: categorias presentes e nova ordem completa', () {
      expect(presentCategories(items, [ItemCategory.limpeza]), [
        ItemCategory.limpeza,
        ItemCategory.hortifruti,
        ItemCategory.laticinios,
      ]);
      final merged = mergeCategoryOrder(
        [ItemCategory.laticinios, ItemCategory.hortifruti],
        [ItemCategory.limpeza],
      );
      expect(merged.take(3), [
        ItemCategory.laticinios,
        ItemCategory.hortifruti,
        ItemCategory.limpeza,
      ]);
      expect(merged.toSet(), ItemCategory.values.toSet());
    });
  });

  group('cartão da lista', () {
    final now = DateTime(2026, 11, 8, 15);
    ShoppingListInfo info(int count, {DateTime? used}) => ShoppingListInfo(
      id: 1,
      name: 'Mês',
      updatedAt: now,
      itemCount: count,
      lastUsed: used,
    );

    test('quantidade com contexto de uso', () {
      expect(
        listSummary(info(6), inUse: true, now: now),
        '6 itens · em uso no carrinho',
      );
      expect(listSummary(info(8), inUse: false, now: now), '8 itens');
      expect(listSummary(info(1), inUse: false, now: now), '1 item');
      expect(listSummary(info(0), inUse: false, now: now), 'Vazia');
    });

    test('usada hoje, ontem ou há N dias, por dia de calendário', () {
      String used(DateTime at) =>
          listSummary(info(24, used: at), inUse: false, now: now);
      expect(used(DateTime(2026, 11, 8, 9)), '24 itens · usada hoje');
      expect(used(DateTime(2026, 11, 7, 23)), '24 itens · usada ontem');
      expect(used(DateTime(2026, 10, 27, 18)), '24 itens · usada há 12 dias');
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

    test('cria lista, adiciona, marca, edita e apaga itens', () async {
      final id = await repo.createList('  Mês  ');
      final a = await repo.addItem(
        id,
        name: 'Tomate',
        category: ItemCategory.hortifruti,
        quantity: 3,
      );
      final b = await repo.addItem(
        id,
        name: 'Banana',
        category: ItemCategory.hortifruti,
      );
      await repo.setDone(id, a, true);
      await repo.updateItem(
        id,
        b,
        name: 'Banana prata',
        category: ItemCategory.hortifruti,
        quantity: 6,
      );

      final info = (await repo.lists()).single;
      expect(info.name, 'Mês');
      expect(info.itemCount, 2);
      expect(info.doneCount, 1);
      final items = await repo.items(id);
      expect(items.map((i) => i.position), [0, 1]);
      expect(items.first.quantity, 3);
      expect(items.first.unit, 'un');
      expect(items.last.name, 'Banana prata');
      expect(items.last.amount, '6 un');

      await repo.deleteItem(id, a);
      expect((await repo.items(id)).single.name, 'Banana prata');
      await repo.setOrder(id, ListOrder.manual);
      expect((await repo.lists()).single.order, ListOrder.manual);
      await repo.deleteList(id);
      expect(await repo.lists(), isEmpty);
      expect(await repo.items(id), isEmpty);
    });

    test('grava a ordem das categorias e a ordem manual dos itens', () async {
      final id = await repo.createList('Mês');
      final a = await repo.addItem(
        id,
        name: 'Tomate',
        category: ItemCategory.hortifruti,
      );
      final b = await repo.addItem(
        id,
        name: 'Detergente',
        category: ItemCategory.limpeza,
      );
      final c = await repo.addItem(
        id,
        name: 'Banana',
        category: ItemCategory.hortifruti,
      );
      // Posição nova vai pro fim da lista inteira, não da categoria.
      expect((await repo.items(id)).map((i) => i.position), [0, 1, 2]);

      await repo.setCategoryOrder(id, [
        ItemCategory.limpeza,
        ItemCategory.hortifruti,
      ]);
      await repo.reorderItems(id, [c, a, b]);
      final info = (await repo.lists()).single;
      expect(info.categoryOrder, [
        ItemCategory.limpeza,
        ItemCategory.hortifruti,
      ]);
      final manual = arrangeList(await repo.items(id), ListOrder.manual);
      expect([for (final i in manual.single.items) i.id], [c, a, b]);
    });

    test('última compra concluída com a lista', () async {
      final id = await repo.createList('Mês');
      expect((await repo.lists()).single.lastUsed, isNull);
      final when = DateTime(2026, 11, 1, 18);
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              startedAt: when,
              finishedAt: Value(when),
              listId: Value(id),
            ),
          );
      expect((await repo.lists()).single.lastUsed, when);
    });

    test('guarda a categoria aprendida pelo nome e pela 1ª palavra', () async {
      await repo.learnCategory('Pão de alho', ItemCategory.carnes);
      final learned = await repo.learnedCategories();
      expect(learned['pao de alho'], ItemCategory.carnes);
      expect(learned['#pao'], ItemCategory.carnes);
      await repo.learnCategory('Pão de alho', ItemCategory.padaria);
      expect(
        (await repo.learnedCategories())['pao de alho'],
        ItemCategory.padaria,
      );
    });

    test('lista alterada por último vem primeiro', () async {
      // O banco guarda datas em segundos: relógio que anda 1 min por uso.
      var t = DateTime(2026, 11, 5);
      final clocked = ListsRepository(
        db,
        clock: () => t = t.add(const Duration(minutes: 1)),
      );
      final a = await clocked.createList('A');
      await clocked.createList('B');
      await clocked.renameList(a, 'A2');
      expect([for (final l in await clocked.lists()) l.name], ['A2', 'B']);
    });
  });

  testWidgets('cria lista, adiciona itens com categoria e marca', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/listas',
      routes: [
        GoRoute(
          path: '/listas',
          builder: (context, state) => const Scaffold(body: ListsPage()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => Scaffold(
                body: ListDetailPage(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [memoryDatabase],
        child: MaterialApp.router(
          theme: buildTinoLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('Nenhuma lista ainda'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-list')));
    await settle();
    await tester.enterText(find.byType(TextField), 'Churrasco');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('list-name-save')));
    await settle();
    expect(find.text('Churrasco'), findsOneWidget);

    // Só o nome pelo campo do topo; a categoria vem da sugestão.
    final add = find.descendant(
      of: find.byKey(const ValueKey('add-list-item')),
      matching: find.byType(TextField),
    );
    await tester.enterText(add, 'Picanha');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle();
    await tester.enterText(add, 'Carvão');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle();

    expect(find.text('Picanha'), findsOneWidget);
    expect(find.text('Carnes e peixes'), findsOneWidget);
    expect(find.text('Carvão'), findsOneWidget);
    expect(find.text('Outros'), findsOneWidget);

    expect(find.text('0 de 2 no carrinho'), findsOneWidget);
    expect(find.text('Faltam 2'), findsOneWidget);

    // Marcar tira o item da lista e manda pro "No carrinho", recolhido.
    // Carnes vem antes de Outros: a primeira caixa é a da Picanha.
    final firstCheck = tester
        .widgetList(
          find.byWidgetPredicate(
            (w) => switch (w.key) {
              ValueKey<String>(:final value) => value.startsWith('list-check-'),
              _ => false,
            },
          ),
        )
        .first;
    final picanha = (firstCheck.key! as ValueKey<String>).value.substring(
      'list-check-'.length,
    );
    await tester.tap(find.byKey(ValueKey('list-check-$picanha')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle();
    expect(find.text('1 de 2 no carrinho'), findsOneWidget);
    expect(find.text('Faltam 1'), findsOneWidget);
    expect(find.text('Picanha'), findsNothing);
    expect(find.text('Carnes e peixes'), findsNothing);
    expect(find.text('No carrinho · 1'), findsOneWidget);

    // Aberto, mostra o marcado; desmarcar devolve à categoria.
    await tester.tap(find.byKey(const ValueKey('list-cart-toggle')));
    await settle();
    expect(find.text('Picanha'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('list-check-$picanha')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle();
    expect(find.text('Carnes e peixes'), findsOneWidget);
    expect(find.text('No carrinho · 1'), findsNothing);

    // Tocar na linha edita.
    await tester.tap(find.byKey(ValueKey('list-edit-$picanha')));
    await settle();
    expect(find.text('Editar item'), findsOneWidget);
  });
}
