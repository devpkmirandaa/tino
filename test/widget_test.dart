import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tino/app/router.dart';
import 'package:tino/app/tino_app.dart';
import 'package:tino/features/onboarding/data/onboarding_preference.dart';
import 'package:tino/features/home/presentation/home_page.dart';
import 'package:tino/features/lists/presentation/lists_page.dart';
import 'package:tino/features/shopping/presentation/shopping_page.dart';
import 'package:tino/features/history/presentation/history_page.dart';
import 'package:tino/features/settings/presentation/settings_page.dart';

import 'support/memory_preferences.dart';

Future<void> openApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(
          MemoryPreferences({OnboardingPreference.seenKey: true}),
        ),
      ],
      child: const TinoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Abre no Início e mantém as cinco áreas na ordem definida', (
    tester,
  ) async {
    await openApp(tester);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Comprar bem\ncomeça antes.'), findsOneWidget);
    final positions = [
      for (final label in [
        'Início',
        'Listas',
        'Comprar',
        'Histórico',
        'Ajustes',
      ])
        tester.getCenter(find.byKey(ValueKey('nav-$label'))).dx,
    ];
    expect(positions, orderedEquals([...positions]..sort()));
    expect(find.text('Flutter Demo'), findsNothing);
  });

  testWidgets('Navega, sinaliza seleção e Voltar retorna ao Início', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await openApp(tester);
      final destinations = [
        (label: 'Listas', page: ListsPage, path: '/listas'),
        (label: 'Comprar', page: ShoppingPage, path: '/comprar'),
        (label: 'Histórico', page: HistoryPage, path: '/historico'),
        (label: 'Ajustes', page: SettingsPage, path: '/ajustes'),
      ];
      for (final destination in destinations) {
        await tester.tap(find.byKey(ValueKey('nav-${destination.label}')));
        await tester.pumpAndSettle();
        expect(find.byType(destination.page), findsOneWidget);
        expect(
          tester.getSemantics(
            find.byKey(ValueKey('destination-${destination.label}')),
          ),
          isSemantics(
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            label: destination.label,
          ),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TinoApp)),
        );
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          destination.path,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(destination.page), findsNothing);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Troca entre áreas e retorna pelo destino Início', (
    tester,
  ) async {
    await openApp(tester);
    for (final label in [
      'Comprar',
      'Ajustes',
      'Listas',
      'Histórico',
      'Início',
    ]) {
      await tester.tap(find.byKey(ValueKey('nav-$label')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Atalhos do Início abrem Comprar e Listas', (tester) async {
    await openApp(tester);
    await tester.ensureVisible(find.text('Ir para Comprar'));
    await tester.tap(find.text('Ir para Comprar'));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ir para Listas'));
    await tester.tap(find.text('Ir para Listas'));
    await tester.pumpAndSettle();
    expect(find.byType(ListsPage), findsOneWidget);
  });

  testWidgets('Tela estreita e texto ampliado mantêm navegação utilizável', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openApp(tester);
    for (final label in [
      'Listas',
      'Comprar',
      'Histórico',
      'Ajustes',
      'Início',
    ]) {
      await tester.tap(find.byKey(ValueKey('nav-$label')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
