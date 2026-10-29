import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/app/tino_app.dart';
import 'package:tino/core/theme/tino_theme.dart';
import 'package:tino/features/home/presentation/home_page.dart';
import 'package:tino/features/onboarding/data/onboarding_preference.dart';

import 'onboarding_test.dart' as intro;
import 'support/memory_preferences.dart';
import 'widget_test.dart' as areas;

Finder dot(int page) => find.byKey(ValueKey('intro-dot-$page'));
Finder indicator(int page) => find.byKey(ValueKey('intro-indicator-$page'));
FadeTransition entry(WidgetTester tester) =>
    tester.widget<FadeTransition>(find.byKey(const ValueKey('intro-entry')));

void main() {
  testWidgets(
    'Arraste reversível interpola indicadores; cancelamento encaixa sem bounce',
    (tester) async {
      await intro.launch(tester, MemoryPreferences());
      final title = find.text('Comprar bem começa antes.');
      final initialX = tester.getTopLeft(title).dx;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();
      final draggedX = tester.getTopLeft(title).dx;
      final width0 = tester.getSize(dot(0)).width;
      expect(width0, inExclusiveRange(8, 24));
      expect(tester.getSize(dot(1)).width + width0, closeTo(32, .01));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(tester.getTopLeft(title).dx - draggedX, closeTo(60, .1));
      expect(tester.getSize(dot(0)).width, greaterThan(width0));
      expect(entry(tester).opacity.value, 1);
      await gesture.cancel();
      await tester.pumpAndSettle();
      intro.expectSelected(tester, 0);
      expect(tester.getTopLeft(title).dx, closeTo(initialX, .1));
      expect(tester.getSize(dot(0)).width, 24);
      final edge = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await edge.moveBy(const Offset(140, 0));
      await tester.pump();
      expect(tester.getTopLeft(title).dx, closeTo(initialX, .1));
      await edge.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Toque dura 300 ms e uma sequência rápida termina no último destino',
    (tester) async {
      await intro.launch(tester, MemoryPreferences());
      await tester.tap(indicator(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller!.position.isScrollingNotifier.value, isTrue);
      await tester.pump(const Duration(milliseconds: 30));
      expect(pageView.controller!.position.isScrollingNotifier.value, isFalse);
      for (final page in [0, 2, 0, 1]) {
        await tester.tap(indicator(page));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      intro.expectSelected(tester, 1);
      expect(entry(tester).opacity.value, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Entrada única de 220 ms não disputa o gesto nem reinicia por rebuild',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
          child: const TinoApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(entry(tester).opacity.value, lessThan(1));
      await tester.pump(const Duration(milliseconds: 110));
      expect(entry(tester).opacity.value, inExclusiveRange(0, 1));
      final pointer = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump();
      expect(entry(tester).opacity.value, 1);
      await pointer.cancel();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(780, 600);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pump();
      expect(entry(tester).opacity.value, 1);
    },
  );

  testWidgets('Movimento reduzido remove entrada e animação por toque', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await intro.launch(tester, MemoryPreferences());
    expect(entry(tester).opacity.value, 1);
    await tester.tap(indicator(2));
    await tester.pump();
    await tester.pump();
    intro.expectSelected(tester, 2);
    final pages = tester.widget<PageView>(find.byType(PageView));
    expect(pages.controller!.page, 2);
    expect(pages.controller!.position.isScrollingNotifier.value, isFalse);
    expect(find.text('Começar').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'Barra fica estável, cor interpola e rolagem da área é preservada',
    (tester) async {
      await areas.openApp(tester);
      final home = tester.element(find.byType(HomePage));
      final scrolling = find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrolling.first).position;
      position.jumpTo(100);
      await tester.pumpAndSettle();
      final before = position.pixels;
      final nav = find.byKey(const ValueKey('nav-Comprar'));
      final barPosition = tester.getRect(nav);
      final iconFinder = find.descendant(of: nav, matching: find.byType(Icon));
      final originalIcon = tester.widget<Icon>(iconFinder).icon;
      await tester.tap(nav);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final midway = tester.widget<Icon>(iconFinder);
      expect(midway.color, isNot(TinoColors.ink));
      expect(midway.color, isNot(TinoColors.jade));
      expect(midway.icon, originalIcon);
      expect(tester.getRect(nav), barPosition);
      final content = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('area-content-fade')),
      );
      expect(content.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(tester.widget<Icon>(iconFinder).color, TinoColors.jade);
      await tester.tap(find.byKey(const ValueKey('nav-Início')));
      await tester.pumpAndSettle();
      expect(identical(tester.element(find.byType(HomePage)), home), isTrue);
      expect(position.pixels, before);
    },
  );

  testWidgets(
    'Dois toques para sair da revisão retornam uma única vez aos Ajustes',
    (tester) async {
      await areas.openApp(tester);
      await tester.tap(find.byKey(const ValueKey('nav-Ajustes')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sobre o Tino'));
      await tester.tap(find.text('Sobre o Tino'));
      await tester.pumpAndSettle();
      final skipPosition = tester.getCenter(find.text('Pular').hitTestable());
      await tester.tapAt(skipPosition);
      await tester.tapAt(skipPosition);
      await tester.pumpAndSettle();
      expect(find.text('Sobre o Tino'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Trocas rápidas e movimento reduzido não deixam transições pendentes',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await areas.openApp(tester);
      for (final label in [
        'Listas',
        'Comprar',
        'Histórico',
        'Ajustes',
        'Início',
      ]) {
        await tester.tap(find.byKey(ValueKey('nav-$label')));
        await tester.pump();
        await tester.pump();
        final fade = tester.widget<FadeTransition>(
          find.byKey(const ValueKey('area-content-fade')),
        );
        expect(fade.opacity.value, 1);
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(HomePage), findsOneWidget);
    },
  );
}
