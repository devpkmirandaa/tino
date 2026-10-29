import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/app/tino_app.dart';
import 'package:tino/core/widgets/tino_wordmark.dart';
import 'package:tino/features/home/presentation/home_page.dart';
import 'package:tino/features/onboarding/data/onboarding_preference.dart';
import 'package:tino/features/onboarding/presentation/onboarding_page.dart';
import 'package:tino/features/settings/presentation/settings_page.dart';

import 'support/memory_preferences.dart';

Future<void> launch(WidgetTester tester, MemoryPreferences preferences) async {
  // Desmonta todo o app: outro ProviderScope e outro roteador, como nova abertura.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const TinoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> review(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('nav-Ajustes')));
  await tester.pumpAndSettle();
  await tap(tester, 'Sobre o Tino');
}

Future<void> swipe(WidgetTester tester, {bool back = false}) async {
  final width = tester.getSize(find.byType(PageView)).width;
  await tester.fling(
    find.byType(PageView),
    Offset(width * (back ? .8 : -.8), 0),
    1000,
  );
  await tester.pumpAndSettle();
}

void expectSelected(WidgetTester tester, int index) {
  final selected = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.label == 'Página ${index + 1} de 3',
  );
  expect(tester.widget<Semantics>(selected).properties.selected, isTrue);
}

void main() {
  interactionTests();
  testWidgets('Primeiro acesso apresenta três telas e só grava ao concluir', (
    tester,
  ) async {
    final disk = <String, bool>{};
    final preferences = MemoryPreferences(disk);
    await launch(tester, preferences);
    expect(find.text('Comprar bem começa antes.'), findsOneWidget);
    expect(find.text('Pular'), findsOneWidget);
    expectSelected(tester, 0);
    expect(find.byKey(const ValueKey('nav-Início')), findsNothing);
    expect(disk, isEmpty);

    await swipe(tester);
    expect(find.text('Aponte. Confira. Adicione.'), findsOneWidget);
    expectSelected(tester, 1);
    await swipe(tester);
    expect(find.text('Seu limite, sempre à vista.'), findsOneWidget);
    expectSelected(tester, 2);
    expect(find.text('Próximo'), findsNothing);
    expect(disk, isEmpty);
    await tap(tester, 'Começar');
    expect(find.byType(HomePage), findsOneWidget);
    expect(disk[OnboardingPreference.seenKey], isTrue);

    await launch(tester, MemoryPreferences(disk));
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);

    disk.clear(); // Equivale à ausência da preferência após limpar dados.
    await launch(tester, MemoryPreferences(disk));
    expect(find.text('Comprar bem começa antes.'), findsOneWidget);
  });

  for (var step = 0; step < 2; step++) {
    testWidgets('Pular na tela ${step + 1} persiste ao reabrir', (
      tester,
    ) async {
      final disk = <String, bool>{};
      await launch(tester, MemoryPreferences(disk));
      for (var i = 0; i < step; i++) {
        await swipe(tester);
      }
      await tap(tester, 'Pular');
      expect(find.byType(HomePage), findsOneWidget);
      expect(disk[OnboardingPreference.seenKey], isTrue);
      await launch(tester, MemoryPreferences(disk));
      expect(find.byType(HomePage), findsOneWidget);
    });
  }

  testWidgets(
    'Interromper não grava; Voltar na apresentação retorna uma tela',
    (tester) async {
      final preferences = MemoryPreferences();
      await launch(tester, preferences);
      await swipe(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Comprar bem começa antes.'), findsOneWidget);
      await swipe(tester);
      await launch(tester, MemoryPreferences(preferences.disk));
      expect(find.text('Comprar bem começa antes.'), findsOneWidget);
      expect(preferences.disk, isEmpty);
    },
  );

  testWidgets(
    'Ajustes permite rever, sair, pular e concluir sem mudar preferência',
    (tester) async {
      final preferences = MemoryPreferences({
        OnboardingPreference.seenKey: true,
      });
      await launch(tester, preferences);
      await review(tester);
      expect(find.text('Comprar bem começa antes.'), findsOneWidget);
      await swipe(tester);
      await tester.tap(find.byTooltip('Fechar apresentação'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tap(tester, 'Sobre o Tino');
      await swipe(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tap(tester, 'Sobre o Tino');
      await tap(tester, 'Pular');
      expect(find.byType(SettingsPage), findsOneWidget);

      await tap(tester, 'Sobre o Tino');
      await swipe(tester);
      await swipe(tester);
      await tap(tester, 'Começar');
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(preferences.writes, 0);
      expect(preferences.disk[OnboardingPreference.seenKey], isTrue);
      await launch(tester, MemoryPreferences(preferences.disk));
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  testWidgets('Aguarda gravação e permite tentar novamente se ela falhar', (
    tester,
  ) async {
    final preferences = MemoryPreferences()
      ..pendingWrite = Completer<void>()
      ..failWrite = true;
    await launch(tester, preferences);
    await tap(tester, 'Pular');
    expect(find.byType(HomePage), findsNothing);
    expect(preferences.disk, isEmpty);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Pular'))
          .onPressed,
      isNull,
    );
    preferences.pendingWrite!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível salvar sua escolha. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(HomePage), findsNothing);
    preferences.failWrite = false;
    await tap(tester, 'Pular');
    expect(find.byType(HomePage), findsOneWidget);
    expect(preferences.disk[OnboardingPreference.seenKey], isTrue);
  });

  testWidgets(
    'Falha de leitura não presume primeiro acesso e permite repetir',
    (tester) async {
      final preferences = MemoryPreferences({
        OnboardingPreference.seenKey: true,
      })..failRead = true;
      await launch(tester, preferences);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);
      preferences.failRead = false;
      await tap(tester, 'Tentar novamente');
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  testWidgets(
    'Apresentação e revisão cabem com texto ampliado em tela estreita',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, MemoryPreferences());
      await swipe(tester);
      await swipe(tester);
      await tap(tester, 'Começar');
      await review(tester);
      await tester.tap(find.byTooltip('Fechar apresentação'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

void interactionTests() {
  testWidgets('Conteúdo acompanha o dedo, encaixa e não repete a dica', (
    tester,
  ) async {
    await launch(tester, MemoryPreferences());
    final title = find.text('Comprar bem começa antes.');
    expect(find.text('Próximo'), findsNothing);
    expect(find.text('Voltar aos Ajustes'), findsNothing);
    expect(find.text('Começar').hitTestable(), findsNothing);
    expect(find.text('Deslize para continuar'), findsOneWidget);
    expect(tester.widget<TinoWordmark>(find.byType(TinoWordmark)).width, 96);
    final startX = tester.getTopLeft(title).dx;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(tester.getTopLeft(title).dx, lessThan(startX));
    await gesture.up();
    await tester.pumpAndSettle();
    expectSelected(tester, 0);
    await swipe(tester);
    expectSelected(tester, 1);
    expect(find.text('Deslize para continuar').hitTestable(), findsNothing);
    expect(find.byType(TinoWordmark).hitTestable(), findsNothing);
    await tester.tap(find.byKey(const ValueKey('intro-indicator-2')));
    await tester.pumpAndSettle();
    expectSelected(tester, 2);
    expect(find.text('Pular').hitTestable(), findsNothing);
    expect(find.text('Começar'), findsOneWidget);
    await swipe(tester, back: true);
    expectSelected(tester, 1);
    await swipe(tester, back: true);
    expectSelected(tester, 0);
    expect(find.text('Deslize para continuar').hitTestable(), findsNothing);
  });

  testWidgets(
    'Indicadores acessíveis anunciam posição e seleção e têm alvo de 48 dp',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await launch(tester, MemoryPreferences());
        for (var index = 0; index < 3; index++) {
          final target = find.byKey(ValueKey('intro-indicator-$index'));
          expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(
            tester.getSemantics(
              find.bySemanticsLabel('Página ${index + 1} de 3'),
            ),
            isSemantics(isButton: true, hasTapAction: true, isSelected: true),
          );
        }
        expect(
          find.bySemanticsLabel('Comprar bem começa antes.'),
          findsNothing,
        );
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Seu limite, sempre à vista.'),
          ),
          isSemantics(isHeader: true),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('Introdução sem overflow com texto 3x em $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, MemoryPreferences());
      for (var index = 0; index < 3; index++) {
        final indicator = find.byKey(ValueKey('intro-indicator-$index'));
        await tester.ensureVisible(indicator);
        await tester.tap(indicator);
        await tester.pumpAndSettle();
        expectSelected(tester, index);
        expect(tester.takeException(), isNull);
      }
      await tap(tester, 'Começar');
      expect(find.byType(HomePage), findsOneWidget);
    });
  }
}
