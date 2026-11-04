import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../application/shopping_controller.dart';
import '../domain/cart.dart';
import '../domain/decimal_input.dart';
import '../domain/money.dart';
import '../domain/tag_reader.dart';

/// [draft] pré-preenche um produto novo (ex.: leitura do scanner).
Future<void> showItemSheet(
  BuildContext context, {
  CartItem? item,
  TagReading? draft,
}) => _sheet(context, _ItemSheet(item: item, draft: draft));

Future<void> showBudgetSheet(BuildContext context) =>
    _sheet(context, const _BudgetSheet());

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

/// Valor inteiro na escala dada, para edição: 1290 (2) → "12,90".
String _plain(int value, int scale) {
  final s = value.toString().padLeft(scale + 1, '0');
  return '${s.substring(0, s.length - scale)},${s.substring(s.length - scale)}';
}

enum _Conflict { update, separate }

class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet({this.item, this.draft});
  final CartItem? item;
  final TagReading? draft;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  late final CartItem? _item = widget.item;
  late final _id = _item?.id ?? ref.read(shoppingProvider.notifier).newId();
  late final _draft = widget.draft;
  late bool _byWeight = _item is WeightItem || (_draft?.perKg ?? false);
  late final _name = TextEditingController(text: _item?.name ?? _draft?.name);
  late final _price = TextEditingController(
    text: switch (_item) {
      UnitItem(:final price) => _plain(price.cents, 2),
      WeightItem(:final pricePerKg) => _plain(pricePerKg.cents, 2),
      null => switch (_draft?.price) {
        final p? => _plain(p.cents, 2),
        null => '',
      },
    },
  );
  late final _amount = TextEditingController(
    text: switch (_item) {
      UnitItem(:final quantity) => '$quantity',
      WeightItem(:final grams) => _plain(grams, 3),
      null => _byWeight ? '' : '1',
    },
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _amount.dispose();
    super.dispose();
  }

  CartItem? _parse() {
    final name = _name.text.trim();
    final price = parseScaled(_price.text, 2);
    final amount = parseScaled(_amount.text, _byWeight ? 3 : 0);
    if (name.isEmpty || price == null || amount == null || amount < 1) {
      return null;
    }
    return _byWeight
        ? WeightItem(
            id: _id,
            name: name,
            pricePerKg: Money(price),
            grams: amount,
          )
        : UnitItem(id: _id, name: name, price: Money(price), quantity: amount);
  }

  Future<void> _save() async {
    final parsed = _parse();
    if (parsed == null) {
      setState(
        () => _error = _byWeight
            ? 'Informe produto, preço por kg e peso (ex.: 0,350).'
            : 'Informe produto e preço.',
      );
      return;
    }
    final controller = ref.read(shoppingProvider.notifier);
    if (_item != null) {
      controller.replace(parsed);
    } else if (controller.add(parsed) case PriceConflict(:final existing)) {
      final added = parsed as UnitItem;
      final choice = await _askConflict(existing, added);
      if (choice == null) return;
      if (choice == _Conflict.update) {
        controller.replace(
          existing.copyWith(
            price: added.price,
            quantity: existing.quantity + added.quantity,
          ),
        );
      } else {
        controller.add(added, force: true);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<_Conflict?> _askConflict(UnitItem existing, UnitItem added) =>
      showDialog<_Conflict>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${existing.name} já está no carrinho'),
          content: Text(
            'Preço anterior: ${existing.price.format()}\n'
            'Novo preço: ${added.price.format()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _Conflict.separate),
              child: const Text('Adicionar separado'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _Conflict.update),
              child: const Text('Atualizar preço'),
            ),
          ],
        ),
      );

  void _changed(String _) => setState(() => _error = null);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final preview = _parse()?.total;
    final item = _item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item == null ? 'Adicionar produto' : 'Editar produto',
          style: text.titleLarge,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          // Com nome lido pelo scanner, o painel abre pronto para confirmar.
          autofocus: item == null && _draft?.name == null,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Produto'),
          onChanged: _changed,
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Unidade'),
              icon: Icon(LucideIcons.shoppingCart, size: 20),
            ),
            ButtonSegment(
              value: true,
              label: Text('Peso'),
              icon: Icon(LucideIcons.scale, size: 20),
            ),
          ],
          selected: {_byWeight},
          onSelectionChanged: (s) => setState(() {
            _byWeight = s.single;
            _amount.text = _byWeight ? '' : '1';
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _byWeight ? 'Preço por kg' : 'Preço',
                  prefixText: 'R\$ ',
                ),
                onChanged: _changed,
              ),
            ),
            const SizedBox(width: 12),
            if (_byWeight)
              Expanded(
                child: TextField(
                  controller: _amount,
                  autofocus: _item == null && _draft?.name != null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Peso',
                    suffixText: 'kg',
                  ),
                  onChanged: _changed,
                  onSubmitted: (_) => _save(),
                ),
              )
            else
              QuantityStepper(
                value: int.tryParse(_amount.text) ?? 1,
                onChanged: (q) => setState(() {
                  _amount.text = '$q';
                  _error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _error ?? 'Total do item: ${preview?.format() ?? '—'}',
          style: text.bodyMedium?.copyWith(
            fontWeight: _error == null ? null : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (item != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(shoppingProvider.notifier).remove(item.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.trash2, size: 20),
                  label: const Text('Remover'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: _save,
                child: Text(item == null ? 'Adicionar' : 'Salvar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet();

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  late final Money? _budget = ref.read(shoppingProvider).value?.budget;
  late final _value = TextEditingController(
    text: switch (_budget) {
      final b? => _plain(b.cents, 2),
      null => '',
    },
  );
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final cents = parseScaled(_value.text, 2);
    if (cents == null || cents < 1) {
      setState(() => _error = 'Informe um valor maior que zero.');
      return;
    }
    ref.read(shoppingProvider.notifier).setBudget(Money(cents));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Orçamento da compra', style: text.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Opcional. O Tino avisa ao chegar a 90% e ao passar do valor.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor',
            prefixText: 'R\$ ',
            errorText: _error,
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (_budget != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(shoppingProvider.notifier).setBudget(null);
                    Navigator.pop(context);
                  },
                  child: const Text('Remover'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: _save,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
