import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../application/lists_providers.dart';
import '../domain/category_suggester.dart';
import '../domain/shopping_list.dart';

/// Quantidade inteira com − e +, sem teclado. Mínimo 1. Visual antigo das
/// folhas de lista (etapa 7).
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

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
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

/// Pede o nome de uma lista; devolve nulo se cancelado.
Future<String?> showListNameSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Salvar',
}) => _sheet<String>(
  context,
  _NameSheet(title: title, initial: initial, action: action),
);

/// Adiciona (sem [item]) ou edita um item da lista.
Future<void> showListItemSheet(
  BuildContext context, {
  required int listId,
  ListItem? item,
}) => _sheet<void>(context, _ItemSheet(listId: listId, item: item));

class _NameSheet extends StatefulWidget {
  const _NameSheet({
    required this.title,
    required this.initial,
    required this.action,
  });
  final String title;
  final String initial;
  final String action;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: TinoSpace.s16),
      TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nome da lista',
          hintText: 'Ex.: Compra do mês',
        ),
        onSubmitted: (_) => _save(),
      ),
      const SizedBox(height: TinoSpace.s16),
      ValueListenableBuilder(
        valueListenable: _name,
        builder: (context, value, _) => FilledButton(
          onPressed: value.text.trim().isEmpty ? null : _save,
          child: Text(widget.action),
        ),
      ),
    ],
  );
}

class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet({required this.listId, this.item});
  final int listId;
  final ListItem? item;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  late final _name = TextEditingController(text: widget.item?.name);
  late var _quantity = widget.item?.quantity ?? 1;
  late var _category = widget.item?.category ?? ItemCategory.outros;

  /// A categoria acompanha o nome até o usuário escolher uma.
  late var _chosen = widget.item != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ItemCategory _suggest(String name) => suggestCategory(
    name,
    learned: ref.read(learnedCategoriesProvider).value ?? const {},
  );

  void _onName(String name) {
    if (_chosen) return;
    final next = _suggest(name);
    if (next != _category) setState(() => _category = next);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(listsActionsProvider);
    // Categoria diferente da sugerida: aprende para as próximas vezes.
    if (_category != _suggest(name)) await repo.learnCategory(name, _category);
    final item = widget.item;
    if (item == null) {
      await repo.addItem(
        widget.listId,
        name: name,
        category: _category,
        quantity: _quantity,
      );
      if (!mounted) return;
      // Continua aberto para o próximo item: listas se fazem em sequência.
      setState(() {
        _name.clear();
        _quantity = 1;
        _category = ItemCategory.outros;
        _chosen = false;
      });
      return;
    }
    await repo.updateItem(
      widget.listId,
      item.id,
      name: name,
      category: _category,
      quantity: _quantity,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref
        .read(listsActionsProvider)
        .deleteItem(widget.listId, widget.item!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Carrega as categorias aprendidas antes de o usuário digitar.
    ref.watch(learnedCategoriesProvider);
    final text = Theme.of(context).textTheme;
    final editing = widget.item != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(editing ? 'Editar item' : 'Novo item', style: text.titleLarge),
        const SizedBox(height: TinoSpace.s16),
        TextField(
          controller: _name,
          autofocus: !editing,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Produto'),
          onChanged: _onName,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: TinoSpace.s16),
        Row(
          children: [
            Expanded(child: Text('Quantidade', style: text.bodyLarge)),
            QuantityStepper(
              value: _quantity,
              onChanged: (q) => setState(() => _quantity = q),
            ),
          ],
        ),
        const SizedBox(height: TinoSpace.s16),
        DropdownButtonFormField<ItemCategory>(
          key: ValueKey(_category),
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: [
            for (final c in ItemCategory.values)
              DropdownMenuItem(value: c, child: Text(c.label)),
          ],
          onChanged: (c) => setState(() {
            if (c != null) _category = c;
            _chosen = true;
          }),
        ),
        const SizedBox(height: TinoSpace.s24),
        ValueListenableBuilder(
          valueListenable: _name,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _save,
            child: Text(editing ? 'Salvar' : 'Adicionar'),
          ),
        ),
        if (editing) ...[
          const SizedBox(height: TinoSpace.s8),
          TextButton(onPressed: _delete, child: const Text('Remover')),
        ],
      ],
    );
  }
}
