import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../application/lists_providers.dart';
import '../domain/shopping_list.dart';
import 'lists_sheets.dart';

enum _Menu { rename, delete }

/// Itens de uma lista, por categoria ou ordem de adição; marcados no fim,
/// riscados. Tocar marca/desmarca; o lápis edita.
class ListDetailPage extends ConsumerWidget {
  const ListDetailPage({super.key, required this.id});
  final int id;

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    ShoppingListInfo list,
    _Menu choice,
  ) async {
    final repo = ref.read(listsActionsProvider);
    switch (choice) {
      case _Menu.rename:
        final name = await showListNameSheet(
          context,
          title: 'Renomear lista',
          initial: list.name,
        );
        if (name != null) await repo.renameList(id, name);
      case _Menu.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Apagar lista?'),
            content: Text(
              '"${list.name}" e os itens dela saem do aparelho. '
              'Não dá pra desfazer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apagar'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        if (context.mounted) context.go('/listas');
        await repo.deleteList(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final list = ref.watch(listProvider(id));
    final items = ref.watch(listItemsProvider(id)).value ?? const [];
    final info = list.value;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar às listas',
                    onPressed: () => context.go('/listas'),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  const Spacer(),
                  if (info != null) ...[
                    PopupMenuButton<ListOrder>(
                      key: const ValueKey('list-order'),
                      tooltip: 'Ordem',
                      icon: const Icon(LucideIcons.arrowDownUp),
                      initialValue: info.order,
                      onSelected: (o) =>
                          ref.read(listsActionsProvider).setOrder(id, o),
                      itemBuilder: (context) => [
                        // Manual chega com o arrastar (L1.5).
                        for (final o in [ListOrder.category, ListOrder.added])
                          CheckedPopupMenuItem(
                            value: o,
                            checked: info.order == o,
                            child: Text(o.label),
                          ),
                      ],
                    ),
                    PopupMenuButton<_Menu>(
                      tooltip: 'Mais opções',
                      icon: const Icon(LucideIcons.ellipsisVertical),
                      onSelected: (c) => _menu(context, ref, info, c),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _Menu.rename,
                          child: Text('Renomear'),
                        ),
                        PopupMenuItem(
                          value: _Menu.delete,
                          child: Text('Apagar lista'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: switch (info) {
                  null when list.isLoading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  null => const Text('Lista não encontrada.'),
                  final l => _Body(list: l, items: items, text: text),
                },
              ),
            ],
          ),
        ),
        if (info != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TinoSpace.s16,
              TinoSpace.s8,
              TinoSpace.s16,
              TinoSpace.s16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('add-list-item'),
                onPressed: () => showListItemSheet(context, listId: id),
                icon: const Icon(LucideIcons.plus, size: 20),
                label: const Text('Adicionar item'),
              ),
            ),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.list, required this.items, required this.text});
  final ShoppingListInfo list;
  final List<ListItem> items;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final arranged = arrangeList(
      items,
      list.order,
      categoryOrder: list.categoryOrder,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(list.name, style: text.headlineLarge),
        ),
        Text(
          items.isEmpty
              ? 'Vazia'
              : '${arranged.done.length} de ${items.length} marcados · '
                    '${list.order.label.toLowerCase()}',
          style: text.bodyMedium,
        ),
        const SizedBox(height: TinoSpace.s24),
        if (items.isEmpty)
          Text(
            'Toque em "Adicionar item" para começar. A categoria é sugerida '
            'pelo nome.',
            style: text.bodyMedium,
          ),
        for (final section in arranged.pending) ...[
          if (section.category case final c?) ...[
            Text(c.label, style: text.titleMedium),
            const SizedBox(height: TinoSpace.s8),
          ],
          _Group(listId: list.id, items: section.items),
          const SizedBox(height: TinoSpace.s16),
        ],
        if (arranged.done.isNotEmpty) ...[
          Text(
            'Marcados (${arranged.done.length})',
            style: text.titleMedium?.copyWith(color: TinoTokens.textSecondary),
          ),
          const SizedBox(height: TinoSpace.s8),
          _Group(listId: list.id, items: arranged.done),
        ],
      ],
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({required this.listId, required this.items});
  final int listId;
  final List<ListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TinoTokens.surface,
        border: Border.all(color: TinoTokens.border),
        borderRadius: BorderRadius.circular(TinoRadius.card),
      ),
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const Divider(indent: TinoSpace.s16),
            InkWell(
              onTap: () => ref
                  .read(listsActionsProvider)
                  .setDone(listId, item.id, !item.done),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.only(left: TinoSpace.s12),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? LucideIcons.circleCheck
                            : LucideIcons.circle,
                        size: 24,
                        color: item.done
                            ? TinoTokens.action
                            : TinoTokens.borderStrong,
                        semanticLabel: item.done ? 'Marcado' : 'Não marcado',
                      ),
                      const SizedBox(width: TinoSpace.s12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: text.bodyLarge?.copyWith(
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.done ? TinoTokens.textSecondary : null,
                          ),
                        ),
                      ),
                      Text(
                        item.amount,
                        style: text.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar ${item.name}',
                        onPressed: () => showListItemSheet(
                          context,
                          listId: listId,
                          item: item,
                        ),
                        icon: const Icon(LucideIcons.pencil, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
