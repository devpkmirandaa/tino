import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../shopping/application/shopping_controller.dart';
import '../application/lists_providers.dart';
import '../domain/shopping_list.dart';

/// Em Comprar: a lista ligada à compra, com o que falta pegar. Itens que
/// entram no carrinho são riscados sozinhos; tocar risca à mão.
class LinkedListCard extends ConsumerStatefulWidget {
  const LinkedListCard(this.listId, {super.key});
  final int listId;

  @override
  ConsumerState<LinkedListCard> createState() => _LinkedListCardState();
}

class _LinkedListCardState extends ConsumerState<LinkedListCard> {
  var _open = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final list = ref.watch(listProvider(widget.listId));
    final info = list.value;
    if (info == null) return const SizedBox.shrink();
    final items = ref.watch(listItemsProvider(widget.listId)).value ?? const [];
    final pending = arrangeList(
      items,
      info.order,
      categoryOrder: info.categoryOrder,
    ).pending.expand((s) => s.items).toList();
    return Container(
      key: const ValueKey('linked-list'),
      decoration: BoxDecoration(
        color: TinoTokens.surface,
        border: Border.all(color: TinoTokens.border),
        borderRadius: BorderRadius.circular(TinoRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: pending.isEmpty
                ? null
                : () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(TinoRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.listChecks, color: TinoTokens.action),
                  const SizedBox(width: TinoSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.name, style: text.titleMedium),
                        Text(
                          pending.isEmpty
                              ? 'Tudo da lista no carrinho.'
                              : 'Falta pegar ${pending.length} de '
                                    '${items.length}',
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver lista',
                    onPressed: () => context.go('/listas/${info.id}'),
                    icon: const Icon(LucideIcons.externalLink, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Parar de usar a lista',
                    onPressed: () =>
                        ref.read(shoppingProvider.notifier).setList(null),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_open && pending.isNotEmpty) ...[
            const Divider(height: 1),
            for (final item in pending)
              InkWell(
                onTap: () => ref
                    .read(listsActionsProvider)
                    .setDone(info.id, item.id, true),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circle,
                          size: 20,
                          color: TinoTokens.borderStrong,
                          semanticLabel: 'Riscar ${item.name}',
                        ),
                        const SizedBox(width: TinoSpace.s12),
                        Expanded(child: Text(item.name, style: text.bodyLarge)),
                        Text(item.amount, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: TinoSpace.s4),
          ],
        ],
      ),
    );
  }
}

/// Em Comprar, sem lista ligada: diz isso e deixa escolher uma lista com
/// itens pendentes. Some quando não há lista com o que pegar.
class UseListPrompt extends ConsumerWidget {
  const UseListPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final open = [
      for (final l
          in ref.watch(listsProvider).value ?? const <ShoppingListInfo>[])
        if (l.doneCount < l.itemCount) l,
    ];
    if (open.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('use-list'),
      margin: const EdgeInsets.only(top: TinoSpace.s16),
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: TinoTokens.surface,
        border: Border.all(color: TinoTokens.border),
        borderRadius: BorderRadius.circular(TinoRadius.card),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.listChecks, color: TinoTokens.textSecondary),
          const SizedBox(width: TinoSpace.s12),
          Expanded(
            child: Text('Sem lista nesta compra', style: text.bodyLarge),
          ),
          TextButton(
            onPressed: () => _choose(context, ref, open),
            child: const Text('Usar lista'),
          ),
        ],
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingListInfo> lists,
  ) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Usar qual lista?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final l in lists)
              ListTile(
                minTileHeight: 56,
                title: Text(l.name),
                subtitle: Text(
                  'Faltam ${l.itemCount - l.doneCount} de ${l.itemCount}',
                ),
                onTap: () => Navigator.pop(context, l.id),
              ),
            const SizedBox(height: TinoSpace.s8),
          ],
        ),
      ),
    );
    if (id != null) ref.read(shoppingProvider.notifier).setList(id);
  }
}
