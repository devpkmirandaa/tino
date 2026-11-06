import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/theme/tino_theme.dart';

/// Confere o tema do app contra a fonte da verdade.
final _tokens = jsonDecode(
  File('design/tokens/tokens.json').readAsStringSync(),
) as Map<String, dynamic>;

Color _hex(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));

double _px(String value) => double.parse(value.replaceAll('px', ''));

Map<String, dynamic> _byName(String group) => {
  for (final t in (_tokens[group]['tokens'] as List)) t['name'] as String: t,
};

void main() {
  final colors = _byName('color');

  group('Cores', () {
    final palette = {
      'jade-profundo': TinoColors.jade,
      'jade-claro': TinoColors.lightJade,
      'azul-glacial': TinoColors.glacialBlue,
      'off-white-frio': TinoColors.offWhite,
      'grafite-profundo': TinoColors.ink,
      'branco-suave': TinoColors.softWhite,
    };
    Map<String, Color?> semantic(TinoColorScheme c) => {
      'canvas': c.canvas,
      'surface': c.surface,
      'surface-soft': c.surfaceSoft,
      'border': c.border,
      'border-strong': c.borderStrong,
      'text-primary': c.textPrimary,
      'text-secondary': c.textSecondary,
      'action': c.action,
      'on-action': c.onAction,
      'action-pressed': c.actionPressed,
      'info': c.info,
      'jade-tint': c.jadeTint,
      'blue-tint': c.blueTint,
    };

    test('Todo token de cor do JSON está mapeado', () {
      expect(
        colors.keys,
        unorderedEquals([
          ...palette.keys,
          ...semantic(TinoColorScheme.light).keys,
        ]),
      );
    });

    test('Paleta oficial', () {
      for (final MapEntry(:key, :value) in palette.entries) {
        expect(value, _hex(colors[key]['value']), reason: key);
      }
    });

    for (final (theme, scheme) in [
      ('light', TinoColorScheme.light),
      ('dark', TinoColorScheme.dark),
    ]) {
      test('Tokens semânticos do tema $theme', () {
        for (final MapEntry(:key, :value) in semantic(scheme).entries) {
          final hex = (colors[key]['value'] as Map)[theme] as String?;
          expect(value, hex == null ? isNull : _hex(hex), reason: key);
        }
      });
    }

    test('Constantes legadas iguais ao tema claro', () {
      const l = TinoColorScheme.light;
      expect(TinoTokens.canvas, l.canvas);
      expect(TinoTokens.textSecondary, l.textSecondary);
      expect(TinoTokens.action, l.action);
    });
  });

  test('Tipografia', () {
    final styles = {
      for (final g in (_tokens['type']['groups'] as List))
        for (final s in (g['styles'] as List)) s['name'] as String: s,
    };
    expect(TinoType.all.keys, unorderedEquals(styles.keys));
    for (final MapEntry(:key, :value) in TinoType.all.entries) {
      final s = styles[key];
      expect(value.fontSize, _px(s['fontSize']), reason: key);
      expect(value.lineHeight, _px(s['lineHeight']), reason: key);
      expect(value.fontWeight.value, s['fontWeight'], reason: key);
    }
  });

  test('Espaçamento, raios e medidas', () {
    final space = _byName('spacing');
    expect([
      TinoSpace.s4,
      TinoSpace.s8,
      TinoSpace.s12,
      TinoSpace.s16,
      TinoSpace.s24,
      TinoSpace.s32,
      TinoSpace.s48,
    ], space.values.map((t) => _px(t['value'])).toList());

    final radius = _byName('radius');
    final radii = {
      'radius-chip': TinoRadius.chip,
      'radius-control': TinoRadius.control,
      'radius-card-compact': TinoRadius.cardCompact,
      'radius-card': TinoRadius.card,
      'radius-panel': TinoRadius.panel,
      'radius-pill': TinoRadius.pill,
    };
    expect(radii.keys, unorderedEquals(radius.keys));
    for (final MapEntry(:key, :value) in radii.entries) {
      expect(value, _px(radius[key]['value']), reason: key);
    }

    final size = _byName('size');
    final sizes = {
      'touch-target': TinoSize.touchTarget,
      'input-height': TinoSize.inputHeight,
      'icon-size': TinoSize.icon,
      'icon-size-compact': TinoSize.iconCompact,
      'icon-stroke': TinoSize.iconStroke,
      'border-width': TinoSize.borderWidth,
    };
    expect(sizes.keys, unorderedEquals(size.keys));
    for (final MapEntry(:key, :value) in sizes.entries) {
      expect(value, _px(size[key]['value']), reason: key);
    }
  });

  for (final brightness in Brightness.values) {
    test('Tema ${brightness.name} usa os tokens e Plus Jakarta Sans', () {
      final theme = buildTinoTheme(brightness);
      final c = TinoColorScheme.of(brightness);
      expect(theme.extension<TinoColorScheme>(), same(c));
      expect(theme.brightness, brightness);
      expect(theme.scaffoldBackgroundColor, c.canvas);
      expect(theme.colorScheme.primary, c.action);
      expect(theme.iconTheme.size, TinoSize.icon);
      expect(theme.textTheme.bodyLarge?.fontFamily, tinoFontFamily);
      expect(
        theme.textTheme.displaySmall?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  }
}
