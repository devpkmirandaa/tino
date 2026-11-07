import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../application/shopping_controller.dart';

// Folha ainda no visual antigo: Finalizar (etapa 6). Item novo:
// type_price_sheet.dart; item do carrinho: item_detail_sheet.dart;
// orçamento: budget_sheet.dart.

Future<void> _sheet(BuildContext context, Widget child) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: child,
  ),
);

Future<void> showFinishSheet(BuildContext context) =>
    _sheet(context, const _FinishSheet());

class _FinishSheet extends ConsumerStatefulWidget {
  const _FinishSheet();

  @override
  ConsumerState<_FinishSheet> createState() => _FinishSheetState();
}

class _FinishSheetState extends ConsumerState<_FinishSheet> {
  var _busy = false;
  var _failed = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(shoppingProvider.notifier).finish();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context);
    messenger?.showSnackBar(
      const SnackBar(content: Text('Compra salva no Histórico.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final session = ref.watch(shoppingProvider).requireValue;
    final count = session.cart.items.length;
    final budget = session.budget;
    final total = session.cart.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Finalizar compra', style: text.titleLarge),
        const SizedBox(height: 16),
        Text(count == 1 ? '1 item' : '$count itens', style: text.bodyMedium),
        Text(total.format(), style: text.displaySmall),
        if (budget != null) ...[
          const SizedBox(height: 8),
          Text(
            total.cents > budget.cents
                ? 'Passou ${(total - budget).format()} do orçamento de '
                      '${budget.format()}.'
                : 'Dentro do orçamento de ${budget.format()}.',
            style: text.bodyMedium,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          _failed
              ? 'Não deu pra finalizar. Tente de novo.'
              : 'A compra vai para o Histórico e o carrinho fica vazio.',
          style: _failed ? text.labelLarge : text.bodyMedium,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _finish,
                child: const Text('Finalizar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quantidade inteira com − e +, sem teclado. Mínimo 1.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Diminuir',
          constraints: const BoxConstraints.tightFor(width: 52, height: 52),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(LucideIcons.minus, size: 20),
        ),
        SizedBox(
          width: 44,
          child: Semantics(
            label: 'Quantidade',
            value: '$value',
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Aumentar',
          constraints: const BoxConstraints.tightFor(width: 52, height: 52),
          onPressed: value < 999 ? () => onChanged(value + 1) : null,
          icon: const Icon(LucideIcons.plus, size: 20),
        ),
      ],
    );
  }
}
