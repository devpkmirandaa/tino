import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../application/lists_providers.dart';
import '../domain/shopping_list.dart';

/// Em Comprar: faixa da lista ligada à compra (fundo `info`), com o que já
/// está no carrinho e o que falta. Tocar abre a lista; o X desliga a lista
/// da compra. Itens que entram no carrinho são riscados sozinhos.
class ActiveListBand extends ConsumerWidget {
  const ActiveListBand(this.listId, {super.key});
  final int listId;

  /// Quantos nomes do que falta aparecem antes das reticências.
  static const _preview = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final info = ref.watch(listProvider(listId)).value;
    if (info == null) return const SizedBox.shrink();
    final items = ref.watch(listItemsProvider(listId)).value ?? const [];
    final pending = arrangeList(
      items,
      info.order,
      categoryOrder: info.categoryOrder,
    ).pending.expand((s) => s.items).map((i) => i.name).toList();
    final done = items.length - pending.length;
    final detail = items.isEmpty
        ? 'Lista sem itens'
        : pending.isEmpty
        ? 'Tudo da lista no carrinho'
        : '$done de ${items.length} no carrinho · faltam '
              '${pending.take(_preview).join(', ')}'
              '${pending.length > _preview ? '…' : ''}';
    return TinoPressable(
      key: const ValueKey('linked-list'),
      onPressed: () => context.go('/listas/${info.id}'),
      scale: TinoPressScale.surface,
      semanticLabel: 'Lista ${info.name}. $detail. Abrir lista',
      excludeSemantics: true,
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(
          TinoSpace.s16,
          TinoSpace.s4,
          TinoSpace.s4,
          TinoSpace.s4,
        ),
        decoration: BoxDecoration(
          color: c.info,
          borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.listChecks, size: TinoSize.icon, color: c.onInfo),
            const SizedBox(width: TinoSpace.s12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TinoSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: TinoType.label.withColor(c.onInfo)),
                    Text(detail, style: TinoType.caption.withColor(c.onInfo)),
                  ],
                ),
              ),
            ),
            _StopButton(
              onPressed: () =>
                  ref.read(shoppingProvider.notifier).setList(null),
            ),
          ],
        ),
      ),
    );
  }
}

/// X sobre o fundo `info`: o ícone usa `on-info`, não o `text-primary` do
/// tema (que no escuro some no azul-glacial).
class _StopButton extends StatelessWidget {
  const _StopButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TinoPressable(
    onPressed: onPressed,
    semanticLabel: 'Parar de usar a lista',
    excludeSemantics: true,
    builder: (context, _) => SizedBox.square(
      dimension: TinoSize.touchTarget,
      child: Icon(
        LucideIcons.x,
        size: TinoSize.iconCompact,
        color: context.tino.onInfo,
      ),
    ),
  );
}

/// Seletor "Usar uma lista": folha com as listas que ainda têm o que pegar.
Future<void> chooseShoppingList(BuildContext context, WidgetRef ref) async {
  final c = context.tino;
  final open = [
    for (final l in ref.read(listsProvider).value ?? const <ShoppingListInfo>[])
      if (l.doneCount < l.itemCount) l,
  ];
  final id = await showTinoSheet<int>(
    context,
    blocks: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          TinoSpace.s16,
          0,
          TinoSpace.s16,
          TinoSpace.s8,
        ),
        child: Text(
          'Usar qual lista?',
          style: TinoType.secao.withColor(c.textPrimary),
        ),
      ),
      if (open.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TinoSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhuma lista com itens pra pegar.',
                style: TinoType.secundario.withColor(c.textSecondary),
              ),
              const SizedBox(height: TinoSpace.s8),
              Builder(
                builder: (sheet) => TinoButton.text(
                  label: 'Ver listas',
                  icon: LucideIcons.listChecks,
                  onPressed: () {
                    Navigator.pop(sheet);
                    context.go('/listas');
                  },
                ),
              ),
            ],
          ),
        )
      else
        for (final l in open)
          Builder(
            builder: (sheet) => TinoItemRow(
              key: ValueKey('choose-list-${l.id}'),
              title: l.name,
              subtitle: 'Faltam ${l.itemCount - l.doneCount} de ${l.itemCount}',
              onPressed: () => Navigator.pop(sheet, l.id),
            ),
          ),
      const SizedBox(height: TinoSpace.s8),
    ],
  );
  if (id != null) ref.read(shoppingProvider.notifier).setList(id);
}
