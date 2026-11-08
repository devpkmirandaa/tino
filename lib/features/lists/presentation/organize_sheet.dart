import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../application/lists_providers.dart';
import '../domain/shopping_list.dart';
import 'lists_sheets.dart';

/// Organizar lista (design/telas/13): "Por categoria" ou "Ordem manual",
/// ordem das categorias pela alça e "Pronto", que grava tudo. Fechar
/// arrastando descarta. No fim, renomear e apagar a lista.
Future<void> showOrganizeSheet(
  BuildContext context, {
  required ShoppingListInfo list,
  required List<ListItem> items,
}) {
  final draft = _OrganizeDraft(list, items);
  return showTinoSheet<void>(
    context,
    barrierLabel: 'Fechar organizar lista',
    onDisposed: draft.dispose,
    blocks: [
      const SheetHeader('Organizar lista'),
      _OrderBlock(draft),
      _CategoriesBlock(draft),
      _DoneButton(draft),
      _ListBlock(list),
    ],
  );
}

class _OrganizeDraft extends ChangeNotifier {
  _OrganizeDraft(this.list, this.items)
    : order = list.order,
      categories = presentCategories(items, list.categoryOrder);

  final ShoppingListInfo list;
  final List<ListItem> items;
  ListOrder order;
  List<ItemCategory> categories;

  void setOrder(ListOrder value) {
    order = value;
    notifyListeners();
  }

  /// [to] já descontado o item retirado (`onReorderItem`).
  void move(int from, int to) {
    final next = [...categories];
    next.insert(to, next.removeAt(from));
    categories = next;
    notifyListeners();
  }
}

/// Opções em cartões de 64: escolhida com borda 2 `action` e radio cheio.
class _OrderBlock extends StatelessWidget {
  const _OrderBlock(this.draft);
  final _OrganizeDraft draft;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) => Semantics(
      label: 'Ordem dos itens',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, o) in ListOrder.values.indexed) ...[
            if (i > 0) const SizedBox(height: TinoSpace.s8),
            _OrderOption(
              order: o,
              selected: draft.order == o,
              onPressed: () => draft.setOrder(o),
            ),
          ],
        ],
      ),
    ),
  );
}

class _OrderOption extends StatelessWidget {
  const _OrderOption({
    required this.order,
    required this.selected,
    required this.onPressed,
  });
  final ListOrder order;
  final bool selected;
  final VoidCallback onPressed;

  static const _radio = 22.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final edge = selected ? 2.0 : TinoSize.borderWidth;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: TinoPressable(
        key: ValueKey('organize-${order.name}'),
        onPressed: onPressed,
        scale: TinoPressScale.surface,
        semanticLabel: '${order.label}. ${order.detail}',
        excludeSemantics: true,
        builder: (context, _) => Container(
          constraints: const BoxConstraints(minHeight: 64),
          // A borda de 2 tira 1 px do respiro: o cartão não muda de tamanho.
          padding: EdgeInsets.symmetric(
            horizontal: TinoSpace.s16 - edge + 1,
            vertical: TinoSpace.s12 - edge + 1,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
            border: Border.all(
              color: selected ? c.action : c.border,
              width: edge,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: _radio,
                height: _radio,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.action : c.borderStrong,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.action,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: TinoSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.label,
                      style: TinoType.corpoForte.withColor(c.textPrimary),
                    ),
                    Text(
                      order.detail,
                      style: TinoType.caption.withColor(c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Ordem das categorias": só em "Por categoria" e com itens na lista.
/// Arrasta só pela alça, pra não brigar com o arrastar da folha.
class _CategoriesBlock extends StatelessWidget {
  const _CategoriesBlock(this.draft);
  final _OrganizeDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        if (draft.order != ListOrder.category || draft.categories.isEmpty) {
          return const SizedBox.shrink();
        }
        final cats = draft.categories;
        const r = Radius.circular(TinoRadius.cardCompact);
        final side = BorderSide(color: c.border, width: TinoSize.borderWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ordem das categorias',
              style: TinoType.caption
                  .withColor(c.textSecondary)
                  .weight(FontWeight.w600),
            ),
            const SizedBox(height: TinoSpace.s8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: cats.length,
              onReorderItem: draft.move,
              itemBuilder: (context, i) {
                final cat = cats[i];
                return DecoratedBox(
                  key: ValueKey('organize-category-${cat.name}'),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? r : Radius.zero,
                      bottom: i == cats.length - 1 ? r : Radius.zero,
                    ),
                    border: Border(
                      left: side,
                      right: side,
                      top: i == 0 ? side : BorderSide.none,
                      bottom: side,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: TinoSpace.s16,
                        right: TinoSpace.s4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.label,
                              style: TinoType.corpo
                                  .withColor(c.textPrimary)
                                  .weight(FontWeight.w500),
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: Semantics(
                              label: 'Mover ${cat.label}',
                              button: true,
                              child: SizedBox.square(
                                dimension: TinoSize.touchTarget,
                                child: Icon(
                                  LucideIcons.gripVertical,
                                  size: TinoSize.iconCompact,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: TinoSpace.s8),
            Text(
              'Arraste pela alça pra seguir o caminho que você faz no mercado.',
              style: TinoType.caption.withColor(c.textSecondary),
            ),
          ],
        );
      },
    );
  }
}

class _DoneButton extends ConsumerWidget {
  const _DoneButton(this.draft);
  final _OrganizeDraft draft;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final list = draft.list;
    final categoryOrder = mergeCategoryOrder(
      draft.categories,
      list.categoryOrder,
    );
    // Ao passar para manual, começa na ordem que a pessoa via.
    final manualIds =
        draft.order == ListOrder.manual && list.order != ListOrder.manual
        ? [
            for (final s in arrangeList(
              draft.items,
              ListOrder.category,
              categoryOrder: categoryOrder,
            ))
              for (final i in s.items) i.id,
          ]
        : null;
    await ref
        .read(listsActionsProvider)
        .organize(
          list.id,
          order: draft.order,
          categoryOrder: categoryOrder,
          manualIds: manualIds,
        );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => TinoButton.primary(
    key: const ValueKey('organize-done'),
    label: 'Pronto',
    expand: true,
    onPressed: () => _save(context, ref),
  );
}

/// Seção "Lista" no fim: renomear e apagar.
class _ListBlock extends ConsumerWidget {
  const _ListBlock(this.list);
  final ShoppingListInfo list;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showListNameSheet(
      context,
      title: 'Renomear lista',
      initial: list.name,
    );
    if (name != null) {
      await ref.read(listsActionsProvider).renameList(list.id, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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
    final shopping = ref.read(shoppingProvider.notifier);
    if (ref.read(shoppingProvider).value?.listId == list.id) {
      shopping.setList(null);
    }
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.go('/listas');
    await ref.read(listsActionsProvider).deleteList(list.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: TinoSpace.s16, color: c.border),
        Text(
          'Lista',
          style: TinoType.caption
              .withColor(c.textSecondary)
              .weight(FontWeight.w600),
        ),
        const SizedBox(height: TinoSpace.s4),
        TinoButton.text(
          key: const ValueKey('organize-rename'),
          label: 'Renomear lista',
          icon: LucideIcons.pencil,
          expand: true,
          muted: true,
          onPressed: () => _rename(context, ref),
        ),
        TinoButton.text(
          key: const ValueKey('organize-delete'),
          label: 'Apagar lista',
          icon: LucideIcons.trash2,
          expand: true,
          muted: true,
          onPressed: () => _delete(context, ref),
        ),
      ],
    );
  }
}
