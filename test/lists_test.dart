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

    test('por categoria: seções na ordem do mercado, marcados no fim', () {
      final r = arrangeList(items, ListOrder.category);
      expect(
        [for (final s in r.pending) s.category],
        [ItemCategory.hortifruti, ItemCategory.limpeza],
      );
      expect(
        [for (final i in r.pending.first.items) i.name],
        ['Tomate', 'Banana'],
      );
      expect([for (final i in r.done) i.name], ['Leite']);
    });

    test('ordem de adição: sem seções, marcados no fim', () {
      final r = arrangeList(items, ListOrder.added);
      expect(r.pending.single.category, isNull);
      expect(
        [for (final i in r.pending.single.items) i.name],
        ['Detergente', 'Tomate', 'Banana'],
      );
      expect([for (final i in r.done) i.name], ['Leite']);
    });

    test('manual: ordem das categorias e posição dos itens', () {
      final r = arrangeList(
        [
          item(1, 'Tomate', ItemCategory.hortifruti, position: 1),
          item(2, 'Banana', ItemCategory.hortifruti, position: 0),
          item(3, 'Detergente', ItemCategory.limpeza),
        ],
        ListOrder.manual,
        categoryOrder: [ItemCategory.limpeza],
      );
      expect(
        [for (final s in r.pending) s.category],
        [ItemCategory.limpeza, ItemCategory.hortifruti],
      );
      expect(
        [for (final i in r.pending.last.items) i.name],
        ['Banana', 'Tomate'],
      );
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
      await repo.setOrder(id, ListOrder.added);
      expect((await repo.lists()).single.order, ListOrder.added);
      await repo.deleteList(id);
      expect(await repo.lists(), isEmpty);
      expect(await repo.items(id), isEmpty);
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
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Churrasco');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar lista'));
    await settle();
    expect(find.text('Churrasco'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-list-item')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Produto'),
      'Picanha',
    );
    await tester.pump();
    expect(find.text('Carnes e peixes'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
    await settle();
    // O painel continua aberto para o próximo item.
    await tester.enterText(find.widgetWithText(TextField, 'Produto'), 'Carvão');
    await tester.pump();
    expect(find.text('Outros'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
    await settle();
    Navigator.of(tester.element(find.text('Novo item'))).pop();
    await settle();

    expect(find.text('Picanha'), findsOneWidget);
    expect(find.text('Carnes e peixes'), findsOneWidget);
    expect(find.text('0 de 2 marcados · por categoria'), findsOneWidget);

    await tester.tap(find.text('Picanha'));
    await settle();
    expect(find.text('Marcados (1)'), findsOneWidget);
    final style = tester.widget<Text>(find.text('Picanha')).style!;
    expect(style.decoration, TextDecoration.lineThrough);
  });
}
