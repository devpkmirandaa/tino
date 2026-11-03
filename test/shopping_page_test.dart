import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/theme/tino_theme.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/domain/decimal_input.dart';
import 'package:tino/features/shopping/presentation/shopping_page.dart';

import 'support/memory_database.dart';

Future<void> openPage(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [memoryDatabase],
      child: MaterialApp(
        theme: buildTinoLightTheme(),
        home: const Scaffold(body: ShoppingPage()),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ShoppingPage)),
  );
  await tester.runAsync(() => container.read(shoppingProvider.future));
  await tester.pump();
}

Future<void> addItem(
  WidgetTester tester,
  String name,
  String price, {
  String? amount,
  bool weight = false,
}) async {
  await tester.ensureVisible(find.text('Adicionar produto'));
  await tester.tap(find.text('Adicionar produto'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Produto'), name);
  if (weight) {
    await tester.tap(find.text('Peso'));
    await tester.pump();
  }
  await tester.enterText(
    find.widgetWithText(TextField, weight ? 'Preço por kg' : 'Preço'),
    price,
  );
  if (amount != null) {
    await tester.enterText(
      find.widgetWithText(TextField, weight ? 'Peso' : 'Quantidade'),
      amount,
    );
  }
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
  await tester.pumpAndSettle();
}

String total(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data!;

void main() {
  test('parseScaled lê formatos brasileiros sem ponto flutuante', () {
    expect(parseScaled('12,90', 2), 1290);
    expect(parseScaled('R\$ 1.234,5', 2), 123450);
    expect(parseScaled('12.90', 2), 1290);
    expect(parseScaled('1.234', 2), 123400);
    expect(parseScaled('7', 2), 700);
    expect(parseScaled('0,347', 3), 347);
    expect(parseScaled('3', 0), 3);
    expect(parseScaled('2,5', 0), isNull);
    expect(parseScaled('1,999', 2), isNull);
    expect(parseScaled('abc', 2), isNull);
    expect(parseScaled('', 2), isNull);
    expect(formatKg(347), '0,347 kg');
    expect(formatKg(1250), '1,250 kg');
  });

  testWidgets('adiciona por unidade e por peso e soma o total', (tester) async {
    await openPage(tester);
    expect(find.text('Carrinho vazio'), findsOneWidget);
    expect(total(tester), r'R$ 0,00');

    await addItem(tester, 'Arroz', '24,90', amount: '2');
    await addItem(tester, 'Tomate', '8,99', amount: '1,250', weight: true);

    expect(find.text('2 itens'), findsOneWidget);
    expect(find.text('1,250 kg × R\$ 8,99/kg'), findsOneWidget);
    expect(total(tester), r'R$ 61,04');
  });

  testWidgets('duplicata com outro preço pergunta e atualiza', (tester) async {
    await openPage(tester);
    await addItem(tester, 'Café', '18,90');
    await addItem(tester, 'café', '17,90');

    expect(find.text('Café já está no carrinho'), findsOneWidget);
    await tester.tap(find.text('Atualizar preço'));
    await tester.pumpAndSettle();

    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('2 × R\$ 17,90'), findsOneWidget);
    expect(total(tester), r'R$ 35,80');
  });

  testWidgets('edita e remove item', (tester) async {
    await openPage(tester);
    await addItem(tester, 'Pão', '1,00', amount: '3');
    await tester.tap(find.text('Pão'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Preço'), '1,50');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(total(tester), r'R$ 4,50');

    await tester.tap(find.text('Pão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Carrinho vazio'), findsOneWidget);
  });

  testWidgets('orçamento mostra perto do limite e estouro', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('Definir orçamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '100');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Faltam R\$ 100,00 do orçamento.'), findsOneWidget);

    await addItem(tester, 'Carne', '95,00');
    expect(find.text('Perto do limite. Faltam R\$ 5,00.'), findsOneWidget);

    await addItem(tester, 'Queijo', '10,00');
    expect(find.text('Passou R\$ 5,00 do orçamento.'), findsOneWidget);
  });

  testWidgets('dados inválidos mostram orientação sem adicionar', (
    tester,
  ) async {
    await openPage(tester);
    await addItem(tester, 'Leite', 'abc');
    expect(
      find.text('Informe produto, preço e quantidade inteira.'),
      findsOneWidget,
    );
    expect(total(tester), r'R$ 0,00');
  });
}
