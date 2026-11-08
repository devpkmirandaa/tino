import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../settings/data/settings_preferences.dart';
import '../application/shopping_controller.dart';
import '../domain/decimal_input.dart';
import '../domain/money.dart';

/// Atalhos de valor da folha Orçamento (telas/12), em reais.
const budgetShortcuts = [100, 150, 200, 300];

/// Orçamento (design/telas/12-orcamento.html): quanto gastar nesta compra,
/// atalhos, aviso de 90% e "Compra sem orçamento". Abre pelo chip
/// "Orçamento" e pela barra do Comprar.
Future<void> showBudgetSheet(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final current = container.read(shoppingProvider).value?.budget;
  final value = TextEditingController(
    text: current == null ? '' : plainScaled(current.cents, 2),
  );
  return showTinoSheet<void>(
    context,
    barrierLabel: 'Fechar orçamento',
    onDisposed: value.dispose,
    blocks: [
      const _Header(),
      _ValueBlock(value),
      _ShortcutsBlock(value),
      const _AlertBlock(),
      _ActionsBlock(value),
    ],
  );
}

/// Valor digitado em centavos; nulo se vazio, inválido ou zero.
int? _cents(TextEditingController value) {
  final cents = parseScaled(value.text, 2);
  return cents == null || cents < 1 ? null : cents;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Orçamento',
                  style: TinoType.secao.withColor(c.textPrimary),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(TinoSpace.s12, 0),
              child: TinoIconButton(
                key: const ValueKey('budget-close'),
                icon: LucideIcons.x,
                semanticLabel: 'Fechar',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
        Text(
          'Quanto você quer gastar nesta compra?',
          style: TinoType.secundario.withColor(c.textSecondary),
        ),
      ],
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock(this.value);
  final TextEditingController value;

  /// Campo do valor em 64 de altura (telas/12); texto 24/32/700.
  static const _height = 64.0;

  @override
  Widget build(BuildContext context) => TinoInput(
    key: const ValueKey('budget-value'),
    label: 'Valor',
    controller: value,
    autofocus: true,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: TextInputAction.done,
    money: true,
    valueStyle: TinoType.tela,
    height: _height,
    suffix: 'R\$',
  );
}

class _ShortcutsBlock extends StatelessWidget {
  const _ShortcutsBlock(this.value);
  final TextEditingController value;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: value,
    builder: (context, _) {
      final cents = _cents(value);
      return Wrap(
        spacing: TinoSpace.s8,
        children: [
          for (final reais in budgetShortcuts)
            TinoChip(
              key: ValueKey('budget-shortcut-$reais'),
              label: 'R\$ $reais',
              selected: cents == reais * 100,
              onPressed: () {
                final text = plainScaled(reais * 100, 2);
                value.value = TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                );
              },
            ),
        ],
      );
    },
  );
}

class _AlertBlock extends ConsumerWidget {
  const _AlertBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final on = ref.watch(nearBudgetAlertProvider).value ?? true;
    void toggle(bool v) => ref.read(nearBudgetAlertProvider.notifier).set(v);
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => toggle(!on),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TinoSpace.s16,
            vertical: TinoSpace.s12,
          ),
          decoration: BoxDecoration(
            color: c.surfaceSoft,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avisar quando faltar pouco',
                      style: TinoType.corpoForte.withColor(c.textPrimary),
                    ),
                    Text(
                      'Avisa e vibra quando passar de 90% do valor.',
                      style: TinoType.caption.withColor(c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TinoSpace.s12),
              TinoSwitch(
                key: const ValueKey('budget-alert'),
                value: on,
                onChanged: toggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionsBlock extends ConsumerWidget {
  const _ActionsBlock(this.value);
  final TextEditingController value;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListenableBuilder(
    listenable: value,
    builder: (context, _) {
      final cents = _cents(value);
      final shopping = ref.read(shoppingProvider.notifier);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TinoSpace.s8),
          TinoButton.primary(
            key: const ValueKey('budget-use'),
            label: cents == null ? 'Usar' : 'Usar ${Money(cents).format()}',
            expand: true,
            onPressed: cents == null
                ? null
                : () {
                    shopping.setBudget(Money(cents));
                    Navigator.pop(context);
                  },
          ),
          const SizedBox(height: TinoSpace.s4),
          TinoButton.text(
            key: const ValueKey('budget-none'),
            label: 'Compra sem orçamento',
            muted: true,
            onPressed: () {
              shopping.setBudget(null);
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
