import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../application/lists_providers.dart';
import '../domain/category_suggester.dart';
import '../domain/shopping_list.dart';

/// Título 20/700 da folha + fechar, como Digitar preço e Orçamento.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: TinoType.secao.withColor(context.tino.textPrimary),
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(TinoSpace.s12, 0),
        child: TinoIconButton(
          icon: LucideIcons.x,
          semanticLabel: 'Fechar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  );
}

/// Nome de uma lista (nova ou renomear); devolve nulo se cancelado.
Future<String?> showListNameSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Salvar',
}) {
  final name = TextEditingController(text: initial);
  void save(BuildContext sheet) {
    final text = name.text.trim();
    if (text.isNotEmpty) Navigator.pop(sheet, text);
  }

  return showTinoSheet<String>(
    context,
    barrierLabel: 'Fechar ${title.toLowerCase()}',
    onDisposed: name.dispose,
    blocks: [
      SheetHeader(title),
      Builder(
        builder: (sheet) => TinoInput(
          key: const ValueKey('list-name'),
          label: 'Nome da lista',
          hint: 'Ex.: Compra do mês',
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => save(sheet),
        ),
      ),
      ListenableBuilder(
        listenable: name,
        builder: (sheet, _) => TinoButton.primary(
          key: const ValueKey('list-name-save'),
          label: action,
          expand: true,
          onPressed: name.text.trim().isEmpty ? null : () => save(sheet),
        ),
      ),
    ],
  );
}

/// "Mais opções" (⋮) da Lista: renomear, apagar e, se a lista estiver na
/// compra, "Tirar da compra" (design/specs/lista-v2.md).
Future<void> showListOptionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required ShoppingListInfo list,
}) async {
  final linked = ref.read(shoppingProvider).value?.listId == list.id;
  final choice = await showTinoSheet<_ListOption>(
    context,
    barrierLabel: 'Fechar opções da lista',
    blocks: [
      SheetHeader(list.name),
      Builder(
        builder: (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TinoButton.text(
              key: const ValueKey('list-rename'),
              label: 'Renomear',
              icon: LucideIcons.pencil,
              expand: true,
              muted: true,
              onPressed: () => Navigator.pop(sheet, _ListOption.rename),
            ),
            if (linked)
              TinoButton.text(
                key: const ValueKey('list-unlink'),
                label: 'Tirar da compra',
                icon: LucideIcons.unlink,
                expand: true,
                muted: true,
                onPressed: () => Navigator.pop(sheet, _ListOption.unlink),
              ),
            TinoButton.text(
              key: const ValueKey('list-delete'),
              label: 'Apagar lista',
              icon: LucideIcons.trash2,
              expand: true,
              muted: true,
              onPressed: () => Navigator.pop(sheet, _ListOption.delete),
            ),
          ],
        ),
      ),
    ],
  );
  if (!context.mounted) return;
  switch (choice) {
    case _ListOption.rename:
      final name = await showListNameSheet(
        context,
        title: 'Renomear lista',
        initial: list.name,
      );
      if (name != null) {
        await ref.read(listsActionsProvider).renameList(list.id, name);
      }
    case _ListOption.unlink:
      ref.read(shoppingProvider.notifier).setList(null);
    case _ListOption.delete:
      await _deleteList(context, ref, list);
    case null:
      break;
  }
}

enum _ListOption { rename, unlink, delete }

Future<void> _deleteList(
  BuildContext context,
  WidgetRef ref,
  ShoppingListInfo list,
) async {
  final ok = await showTinoSheet<bool>(
    context,
    barrierLabel: 'Fechar apagar lista',
    blocks: [
      const SheetHeader('Apagar lista?'),
      Text(
        '"${list.name}" e os itens dela saem do aparelho. Não dá pra '
        'desfazer.',
        style: TinoType.corpo.withColor(context.tino.textSecondary),
      ),
      Builder(
        builder: (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TinoButton.primary(
              key: const ValueKey('delete-list-confirm'),
              label: 'Apagar lista',
              expand: true,
              onPressed: () => Navigator.pop(sheet, true),
            ),
            const SizedBox(height: TinoSpace.s4),
            TinoButton.text(
              label: 'Cancelar',
              expand: true,
              onPressed: () => Navigator.pop(sheet, false),
            ),
          ],
        ),
      ),
    ],
  );
  if (ok != true || !context.mounted) return;
  // Lista em uso na compra: a compra segue sem lista.
  if (ref.read(shoppingProvider).value?.listId == list.id) {
    ref.read(shoppingProvider.notifier).setList(null);
  }
  GoRouter.of(context).go('/listas');
  await ref.read(listsActionsProvider).deleteList(list.id);
}

/// Edita um item da lista (toque na linha da Lista): nome, quantidade e
/// categoria; "Tirar da lista" apaga.
Future<void> showListItemSheet(
  BuildContext context, {
  required int listId,
  required ListItem item,
}) {
  final draft = _ItemDraft(item);
  return showTinoSheet<void>(
    context,
    barrierLabel: 'Fechar editar item',
    onDisposed: draft.dispose,
    blocks: [
      const SheetHeader('Editar item'),
      TinoInput(
        key: const ValueKey('list-item-name'),
        label: 'Produto',
        controller: draft.name,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
      ),
      _QuantityBlock(draft),
      _CategoryBlock(draft),
      _ItemActions(listId: listId, draft: draft),
    ],
  );
}

class _ItemDraft extends ChangeNotifier {
  _ItemDraft(this.item) : quantity = item.quantity, category = item.category {
    name.addListener(notifyListeners);
  }

  final ListItem item;
  late final name = TextEditingController(text: item.name);
  int quantity;
  ItemCategory category;

  void setQuantity(int value) {
    quantity = value;
    notifyListeners();
  }

  void setCategory(ItemCategory value) {
    category = value;
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

class _QuantityBlock extends StatelessWidget {
  const _QuantityBlock(this.draft);
  final _ItemDraft draft;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) => Row(
      children: [
        Expanded(
          child: Text(
            'Quantidade',
            style: TinoType.label.withColor(context.tino.textPrimary),
          ),
        ),
        TinoQuantityStepper(
          key: const ValueKey('list-item-quantity'),
          value: draft.quantity,
          onChanged: draft.setQuantity,
        ),
      ],
    ),
  );
}

/// Categoria em chips; a escolhida com borda 2 `action`.
class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock(this.draft);
  final _ItemDraft draft;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: TinoType.label.withColor(context.tino.textPrimary),
        ),
        const SizedBox(height: TinoSpace.s4),
        Wrap(
          spacing: TinoSpace.s8,
          children: [
            for (final c in ItemCategory.values)
              TinoChip(
                key: ValueKey('list-item-category-${c.name}'),
                label: c.label,
                selected: draft.category == c,
                onPressed: () => draft.setCategory(c),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ItemActions extends ConsumerWidget {
  const _ItemActions({required this.listId, required this.draft});
  final int listId;
  final _ItemDraft draft;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final name = draft.name.text.trim();
    if (name.isEmpty) return;
    final actions = ref.read(listsActionsProvider);
    final suggested = suggestCategory(
      name,
      learned: ref.read(learnedCategoriesProvider).value ?? const {},
    );
    // Categoria diferente da sugerida: aprende para as próximas vezes.
    if (draft.category != suggested) {
      await actions.learnCategory(name, draft.category);
    }
    await actions.updateItem(
      listId,
      draft.item.id,
      name: name,
      category: draft.category,
      quantity: draft.quantity,
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Carrega as categorias aprendidas para comparar com a escolhida.
    ref.watch(learnedCategoriesProvider);
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TinoButton.primary(
            key: const ValueKey('list-item-save'),
            label: 'Salvar',
            expand: true,
            onPressed: draft.name.text.trim().isEmpty
                ? null
                : () => _save(context, ref),
          ),
          const SizedBox(height: TinoSpace.s4),
          TinoButton.text(
            key: const ValueKey('list-item-remove'),
            label: 'Tirar da lista',
            icon: LucideIcons.trash2,
            muted: true,
            onPressed: () async {
              await ref
                  .read(listsActionsProvider)
                  .deleteItem(listId, draft.item.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
