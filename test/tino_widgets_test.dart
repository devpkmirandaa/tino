import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tino/core/theme/tino_theme.dart';
import 'package:tino/core/widgets/tino_widgets.dart';

Widget _app(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool reduced = false,
}) => MaterialApp(
  theme: buildTinoTheme(brightness),
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: page!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

double _scale(WidgetTester tester, Finder of) => tester
    .widget<Transform>(
      find.descendant(of: of, matching: find.byType(Transform)).first,
    )
    .transform
    .entry(0, 0);

/// Avança [total] em quadros de 16 ms e devolve os valores lidos.
Future<List<double>> _frames(
  WidgetTester tester,
  double Function() read, {
  Duration total = const Duration(milliseconds: 800),
}) async {
  final values = <double>[];
  for (var t = 0; t < total.inMilliseconds; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
    values.add(read());
  }
  return values;
}

void main() {
  group('M1 · Pressionar', () {
    testWidgets(
      'Desativado: sem M1, sem háptico, surface-soft + text-secondary',
      (tester) async {
        final platform = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            platform.add(call.method);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(const TinoButton.primary(label: 'Ok', onPressed: null)),
        );
        final button = find.byType(TinoPressable);
        final gesture = await tester.startGesture(tester.getCenter(button));
        await tester.pump(kPressTimeout);
        await _frames(tester, () => 0);
        expect(_scale(tester, button), 1);
        await gesture.up();
        await tester.pumpAndSettle();

        const c = TinoColorScheme.light;
        final box = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect((box.decoration! as BoxDecoration).color, c.surfaceSoft);
        expect(
          tester.widget<Text>(find.text('Ok')).style?.color,
          c.textSecondary,
        );
        expect(platform.where((m) => m.startsWith('HapticFeedback')), isEmpty);
        expect(
          tester.getSemantics(button),
          isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
        semantics.dispose();
      },
    );

    testWidgets('Botão afunda a 0,94 e volta passando um pouco de 1', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(TinoButton.primary(label: 'Ok', onPressed: () => taps++)),
      );
      final button = find.byType(TinoPressable);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(kPressTimeout);
      await _frames(tester, () => 0);
      expect(_scale(tester, button), closeTo(0.94, 0.002));

      await gesture.up();
      final release = await _frames(tester, () => _scale(tester, button));
      expect(release.reduce((a, b) => a > b ? a : b), greaterThan(1));
      expect(release.last, closeTo(1, 0.001));
      expect(taps, 1);
    });

    testWidgets('Cartão tocável afunda a 0,96', (tester) async {
      await tester.pumpWidget(
        _app(TinoCard(onPressed: () {}, child: const Text('Cartão'))),
      );
      final card = find.byType(TinoPressable);
      await tester.startGesture(tester.getCenter(card));
      await tester.pump(kPressTimeout);
      await _frames(tester, () => 0);
      expect(_scale(tester, card), closeTo(0.96, 0.002));
    });

    testWidgets('Dedo sai do botão: cancela e volta, sem tocar', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(TinoButton.primary(label: 'Ok', onPressed: () => taps++)),
      );
      final button = find.byType(TinoPressable);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(kPressTimeout);
      await gesture.moveBy(const Offset(0, 200));
      await _frames(tester, () => 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scale(tester, button), closeTo(1, 0.001));
      expect(taps, 0);
    });

    testWidgets('Movimento reduzido: não escala, só troca a cor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(TinoButton.primary(label: 'Ok', onPressed: () {}), reduced: true),
      );
      final button = find.byType(TinoPressable);
      await tester.startGesture(tester.getCenter(button));
      await tester.pump(kPressTimeout);
      await tester.pumpAndSettle();
      expect(_scale(tester, button), 1);
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        TinoColorScheme.light.actionPressed,
      );
    });
  });

  testWidgets('M6 · Segmentado estica no meio do caminho e assenta', (
    tester,
  ) async {
    var selected = 'a';
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) => TinoSegmented<String>(
              segments: const [
                (value: 'a', label: 'Unidade'),
                (value: 'b', label: 'Peso'),
              ],
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      ),
    );
    final indicator = find.byKey(const ValueKey('tino-segmented-indicator'));
    final segment = tester.getSize(indicator).width;
    await tester.tap(find.text('Peso'));
    final widths = await _frames(tester, () => tester.getSize(indicator).width);
    expect(widths.reduce((a, b) => a > b ? a : b), greaterThan(segment * 1.08));
    expect(widths.last, closeTo(segment, 0.01));
    expect(
      tester.getTopRight(indicator).dx,
      closeTo(tester.getTopRight(find.byType(TinoSegmented<String>)).dx - 4, 1),
    );
  });

  testWidgets('Contador respeita o mínimo', (tester) async {
    var value = 1;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => TinoQuantityStepper(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Diminuir'));
    await tester.pumpAndSettle();
    expect(value, 1);
    await tester.tap(find.bySemanticsLabel('Aumentar'));
    await tester.pumpAndSettle();
    expect(value, 2);
    expect(find.text('2'), findsOneWidget);
  });

  group('M9 · Barra', () {
    double fill(WidgetTester tester) => tester
        .widget<FractionallySizedBox>(
          find.byKey(const ValueKey('tino-progress-fill')),
        )
        .widthFactor!;

    Widget bar(double value, {bool over = false}) => _app(
      SizedBox(
        width: 300,
        child: TinoProgressBar(
          value: value,
          over: over,
          overLabel: 'Passou R\$ 5,00',
        ),
      ),
    );

    testWidgets('Não anima ao abrir; anima com mola quando muda', (
      tester,
    ) async {
      await tester.pumpWidget(bar(0.5));
      expect(fill(tester), 0.5);
      await tester.pumpWidget(bar(0.8));
      await tester.pump(const Duration(milliseconds: 16));
      expect(fill(tester), allOf(greaterThan(0.5), lessThan(0.8)));
      await tester.pumpAndSettle();
      expect(fill(tester), closeTo(0.8, 0.001));
    });

    testWidgets('Passou do orçamento: treme uma vez e vibra em dois pulsos', (
      tester,
    ) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(bar(0.9));
      await tester.pumpWidget(bar(1, over: true));
      double shift() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(TinoProgressBar),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .x;
      final xs = await _frames(
        tester,
        shift,
        total: const Duration(milliseconds: 1500),
      );
      expect(xs.reduce((a, b) => a > b ? a : b), greaterThan(4));
      expect(xs.reduce((a, b) => a < b ? a : b), lessThan(-4));
      expect(xs.last, closeTo(0, 0.01));
      expect(haptics, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
      expect(find.text('Passou R\$ 5,00'), findsOneWidget);

      // Continuar acima do orçamento não treme de novo.
      haptics.clear();
      await tester.pumpWidget(bar(1, over: true));
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
    });
  });

  group('M5 · Folha', () {
    Future<void> open(
      WidgetTester tester, {
      bool reduced = false,
      bool tall = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTinoTheme(Brightness.light),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: page!,
          ),
          home: TinoSheetScope(
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TinoButton.primary(
                    label: 'Abrir',
                    onPressed: () => showTinoSheet<void>(
                      context,
                      blocks: [
                        SizedBox(
                          height: tall ? 1500 : 200,
                          child: const Text('Conteúdo'),
                        ),
                        const Text('Segundo bloco'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    double backScale(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('tino-sheet-scope-clip')),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .entry(0, 0);

    Finder handle() => find.byKey(const ValueKey('tino-sheet-handle'));
    double sheetHeight(WidgetTester tester) => tester
        .getSize(
          find.ancestor(of: handle(), matching: find.byType(Container)).last,
        )
        .height;

    testWidgets('Abre, tela de trás recua a 0,94 com cantos 24', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Segundo bloco'), findsOneWidget);
      expect(backScale(tester), closeTo(0.94, 0.001));
      final clip = tester.widget<ClipRRect>(
        find.byKey(const ValueKey('tino-sheet-scope-clip')),
      );
      expect(
        (clip.borderRadius as BorderRadius).topLeft.x,
        closeTo(TinoRadius.panel, 0.001),
      );
    });

    testWidgets('Arraste curto volta; tela de trás acompanha', (tester) async {
      await open(tester);
      final height = sheetHeight(tester);
      final gesture = await tester.startGesture(tester.getCenter(handle()));
      await gesture.moveBy(const Offset(0, kTouchSlop)); // vence o slop
      await gesture.moveBy(Offset(0, height * 0.2));
      await tester.pump();
      expect(backScale(tester), closeTo(1 - 0.06 * 0.8, 0.005));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Segundo bloco'), findsOneWidget);
      expect(backScale(tester), closeTo(0.94, 0.001));
    });

    testWidgets('Fecha depois de 30% da altura', (tester) async {
      await open(tester);
      final height = sheetHeight(tester);
      final gesture = await tester.startGesture(tester.getCenter(handle()));
      await gesture.moveBy(const Offset(0, kTouchSlop)); // vence o slop
      await gesture.moveBy(Offset(0, height * 0.35));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Segundo bloco'), findsNothing);
      expect(backScale(tester), 1);
    });

    testWidgets('Fecha com arremesso rápido mesmo com pouco deslocamento', (
      tester,
    ) async {
      await open(tester);
      // 70 px é menos de 30% da folha (284 px no teste); só a velocidade fecha.
      await tester.fling(handle(), const Offset(0, 70), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Segundo bloco'), findsNothing);
    });

    testWidgets('Pra cima resiste (× 0,3)', (tester) async {
      await open(tester);
      final rest = tester.getTopLeft(handle()).dy;
      final gesture = await tester.startGesture(tester.getCenter(handle()));
      await gesture.moveBy(const Offset(0, -kTouchSlop)); // vence o slop
      await tester.pump();
      final start = tester.getTopLeft(handle()).dy;
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(start - tester.getTopLeft(handle()).dy, closeTo(30, 0.5));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(handle()).dy, closeTo(rest, 0.5));
    });

    group('Conteúdo rolável', () {
      Finder content() => find.text('Conteúdo');
      // O texto ocupa os 1500 px do bloco: toca perto do topo dele.
      Offset grab(WidgetTester tester) =>
          tester.getTopLeft(content()) + const Offset(40, 40);
      double scrolled(WidgetTester tester) => tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const ValueKey('tino-sheet-scroll')),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;

      testWidgets('No topo, puxar o conteúdo pra baixo move a folha', (
        tester,
      ) async {
        await open(tester, tall: true);
        final top = tester.getTopLeft(handle()).dy;
        final gesture = await tester.startGesture(grab(tester));
        await gesture.moveBy(const Offset(0, kTouchSlop));
        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();
        expect(tester.getTopLeft(handle()).dy, greaterThan(top + 50));
        expect(scrolled(tester), 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(handle()).dy, closeTo(top, 0.5));
      });

      testWidgets('Pra cima, rola o conteúdo e a folha fica', (tester) async {
        await open(tester, tall: true);
        final top = tester.getTopLeft(handle()).dy;
        final gesture = await tester.startGesture(grab(tester));
        await gesture.moveBy(const Offset(0, -kTouchSlop));
        await gesture.moveBy(const Offset(0, -120));
        await tester.pump();
        expect(scrolled(tester), greaterThan(100));
        expect(tester.getTopLeft(handle()).dy, top);

        // Rolado, puxar pra baixo primeiro rola de volta, sem mover a folha.
        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();
        expect(scrolled(tester), lessThan(100));
        expect(tester.getTopLeft(handle()).dy, top);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Conteúdo'), findsOneWidget);
      });

      testWidgets('No topo, arremesso pra baixo pelo conteúdo fecha', (
        tester,
      ) async {
        await open(tester, tall: true);
        await tester.flingFrom(grab(tester), const Offset(0, 70), 1500);
        await tester.pumpAndSettle();
        expect(find.text('Conteúdo'), findsNothing);
      });
    });

    testWidgets('Movimento reduzido: tela de trás não escala', (tester) async {
      await open(tester, reduced: true);
      expect(find.text('Segundo bloco'), findsOneWidget);
      expect(backScale(tester), 1);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('Todos os componentes montam no tema ${brightness.name}', (
      tester,
    ) async {
      final c = TinoColorScheme.of(brightness);
      await tester.pumpWidget(
        _app(
          brightness: brightness,
          SingleChildScrollView(
            child: Column(
              children: [
                TinoButton.primary(label: 'Primário', onPressed: () {}),
                TinoButton.primary(
                  label: 'Escanear',
                  size: TinoButtonSize.scan,
                  onPressed: () {},
                ),
                TinoButton.outlined(label: 'Contornado', onPressed: () {}),
                TinoButton.text(label: 'Texto', onPressed: () {}),
                TinoIconButton(
                  icon: LucideIcons.plus,
                  semanticLabel: 'Ícone',
                  onPressed: () {},
                ),
                TinoChip(label: 'Chip', onPressed: () {}),
                const TinoInput(label: 'Campo'),
                const TinoCard(child: Text('Cartão')),
                const TinoItemRow(
                  title: 'Item',
                  subtitle: 'Apoio',
                  price: 'R\$ 1,00',
                ),
                TinoSegmented<int>(
                  segments: const [
                    (value: 0, label: 'A'),
                    (value: 1, label: 'B'),
                  ],
                  selected: 0,
                  onChanged: (_) {},
                ),
                TinoQuantityStepper(value: 1, onChanged: (_) {}),
                const TinoProgressBar(value: 0.5),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TinoPressable).first).height, 52);
      final primary = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect((primary.decoration! as BoxDecoration).color, c.action);
      expect(
        tester.getSize(find.bySemanticsLabel('Ícone')),
        const Size(48, 48),
      );
    });
  }

  test('Componentes base só usam tokens semânticos', () {
    const legacy = {'area_page.dart', 'tino_wordmark.dart'};
    final forbidden = RegExp(
      r'TinoTokens|TinoColors|Color\(0x|Colors\.(?!transparent\b)',
    );
    final files = [
      ...Directory('lib/core/widgets')
          .listSync()
          .whereType<File>()
          .where((f) => !legacy.contains(f.uri.pathSegments.last)),
    ];
    final hits = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) hits.add('${file.path}:${i + 1}');
      }
    }
    expect(files.length, greaterThan(10));
    expect(hits, isEmpty);
  });
}
