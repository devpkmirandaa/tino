import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/history/presentation/history_page.dart';
import 'package:tino/features/history/presentation/purchase_detail_page.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/presentation/shopping_page.dart';

import 'widget_test.dart' as areas;

void main() {
  testWidgets('finaliza, lista no Histórico e abre o detalhe', (tester) async {
    await areas.openApp(tester);
    await tester.tap(find.byKey(const ValueKey('nav-Comprar')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShoppingPage)),
    );
    await tester.runAsync(() => container.read(shoppingProvider.future));
    await tester.pump();

    expect(find.text('Finalizar compra'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('add-product')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Produto'), 'Café');
    await tester.enterText(find.widgetWithText(TextField, 'Preço'), '18,90');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finalizar compra'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => tester.tap(find.widgetWithText(FilledButton, 'Finalizar')),
    );
    await tester.runAsync(
      () => container.read(shoppingProvider.notifier).flush(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carrinho vazio'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Histórico')));
    await tester.runAsync(() => container.read(historyProvider.future));
    await tester.pumpAndSettle();
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text(r'R$ 18,90'), findsOneWidget);

    await tester.tap(find.text('1 item'));
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseDetailPage), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseDetailPage), findsNothing);
    expect(find.byType(HistoryPage), findsOneWidget);
  });
}
