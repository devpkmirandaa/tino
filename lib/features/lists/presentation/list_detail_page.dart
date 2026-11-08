import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../application/lists_providers.dart';
import '../domain/category_suggester.dart';
import '../domain/shopping_list.dart';
import 'lists_sheets.dart';
import 'organize_sheet.dart';

/// Lista (design/telas/08): "Adicionar item" no topo, itens por categoria
/// (ou numa lista só, na ordem manual, com alça de arrastar), marcar com
/// M12. Toque e segure edita. "Comprar com esta lista" liga a lista à
/// compra e volta ao Comprar.
class ListDetailPage extends ConsumerStatefulWidget {
  const ListDetailPage({super.key, required this.id});
  final int id;

  @override
  ConsumerState<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends ConsumerState<ListDetailPage> {
  final _add = TextEditingController();
  final _addFocus = FocusNode();

  /// Ordem manual arrastada, até o banco devolver a mesma ordem.
  List<ListItem>? _dragged;

  int get _id => widget.id;

  @override
  void dispose() {
    _add.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  /// Só o nome; a categoria vem da sugestão e a quantidade é 1.
  Future<void> _addItem() async {
    final name = _add.text.trim();
    if (name.isEmpty) return;
    _add.clear();
    final category = suggestCategory(
      name,
      learned: ref.read(learnedCategoriesProvider).value ?? const {},
    );
    await ref
        .read(listsActionsProvider)
        .addItem(_id, name: name, category: category);
    // Continua no campo: listas se fazem em sequência.
    if (mounted) _addFocus.requestFocus();
  }

  /// [to] já descontado o item retirado (`onReorderItem`).
  Future<void> _reorder(List<ListItem> items, int from, int to) async {
    final next = [...items];
    final moved = next.removeAt(from);
    next.insert(to, moved);
    setState(() => _dragged = next);
    await ref.read(listsActionsProvider).reorderItems(_id, [
      for (final i in next) i.id,
    ]);
    await ref.read(listItemsProvider(_id).future);
    if (mounted) setState(() => _dragged = null);
  }

  Future<void> _shop() async {
    await ref.read(shoppingProvider.future);
    ref.read(shoppingProvider.notifier).setList(_id);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final list = ref.watch(listProvider(_id));
    final items = ref.watch(listItemsProvider(_id)).value ?? const [];
    // Carrega as categorias aprendidas antes de adicionar pelo campo.
    ref.watch(learnedCategoriesProvider);
    final info = list.value;
    if (info == null) {
      return Center(
        child: list.isLoading
            ? const SizedBox.shrink()
            : Text(
                'Lista não encontrada.',
                style: TinoType.corpo.withColor(c.textPrimary),
              ),
      );
    }
    final manual = info.order == ListOrder.manual;
    final sections = arrangeList(
      items,
      info.order,
      categoryOrder: info.categoryOrder,
    );
    final manualItems = _dragged ?? sections.firstOrNull?.items ?? const [];
    const gutter = EdgeInsets.symmetric(horizontal: TinoSpace.s16);
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  TinoSpace.s16,
                  TinoSpace.s8,
                  TinoSpace.s16,
                  TinoSpace.s16,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        info: info,
                        onOrganize: () => showOrganizeSheet(
                          context,
                          list: info,
                          items: items,
                        ),
                      ),
                      const SizedBox(height: TinoSpace.s16),
                      TinoInput(
                        key: const ValueKey('add-list-item'),
                        hint: 'Adicionar item',
                        controller: _add,
                        focusNode: _addFocus,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addItem(),
                        trailing: _AddButton(onPressed: _addItem),
                      ),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverPadding(
                  padding: gutter,
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Escreva o primeiro item acima. A categoria é sugerida '
                      'pelo nome.',
                      style: TinoType.secundario.withColor(c.textSecondary),
                    ),
                  ),
                )
              else if (manual)
                SliverPadding(
                  padding: gutter,
                  sliver: SliverReorderableList(
                    itemCount: manualItems.length,
                    onReorderItem: (from, to) =>
                        _reorder(manualItems, from, to),
                    itemBuilder: (context, i) {
                      final item = manualItems[i];
                      return _ManualRow(
                        key: ValueKey('list-item-${item.id}'),
                        index: i,
                        first: i == 0,
                        last: i == manualItems.length - 1,
                        child: _ItemRow(
                          listId: _id,
                          item: item,
                          handle: ReorderableDragStartListener(
                            index: i,
                            child: _Grip(name: item.name),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: gutter,
                  sliver: SliverList.list(
                    children: [
                      for (final (i, section) in sections.indexed) ...[
                        if (i > 0) const SizedBox(height: TinoSpace.s16),
                        _Group(listId: _id, section: section),
                      ],
                    ],
                  ),
                ),
              if (items.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    TinoSpace.s16,
                    TinoSpace.s16,
                    TinoSpace.s16,
                    TinoSpace.s16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Toque e segure um item pra editar.',
                      textAlign: TextAlign.center,
                      style: TinoType.caption.withColor(c.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TinoSpace.s16,
            TinoSpace.s8,
            TinoSpace.s16,
            TinoSpace.s16,
          ),
          child: TinoButton.primary(
            key: const ValueKey('shop-with-list'),
            label: 'Comprar com esta lista',
            icon: LucideIcons.shoppingCart,
            size: TinoButtonSize.large,
            expand: true,
            onPressed: _shop,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info, required this.onOrganize});
  final ShoppingListInfo info;
  final VoidCallback onOrganize;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-TinoSpace.s12, 0),
          child: TinoIconButton(
            key: const ValueKey('list-back'),
            icon: LucideIcons.chevronLeft,
            semanticLabel: 'Voltar às listas',
            onPressed: () => context.go('/listas'),
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(-TinoSpace.s8, 0),
            child: Semantics(
              header: true,
              child: Text(
                info.name,
                style: TinoType.tela.withColor(c.textPrimary),
              ),
            ),
          ),
        ),
        TinoPressable(
          key: const ValueKey('list-organize'),
          onPressed: onOrganize,
          semanticLabel: 'Organizar lista',
          excludeSemantics: true,
          builder: (context, pressed) => Padding(
            padding: const EdgeInsets.symmetric(vertical: TinoSpace.s4),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: TinoSpace.s12),
              decoration: BoxDecoration(
                color: c.surfaceSoft,
                borderRadius: BorderRadius.circular(TinoRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.arrowDownUp,
                    size: TinoSize.iconCompact,
                    color: c.textPrimary,
                  ),
                  const SizedBox(width: TinoSpace.s4),
                  Text(
                    'Organizar',
                    style: TinoType.label.withColor(c.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// + dentro do campo: 40, raio 8, `action`; área de toque 48.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return TinoPressable(
      key: const ValueKey('add-list-item-button'),
      onPressed: onPressed,
      semanticLabel: 'Adicionar',
      excludeSemantics: true,
      builder: (context, pressed) => SizedBox.square(
        dimension: TinoSize.touchTarget,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pressed ? c.actionPressed : c.action,
              borderRadius: BorderRadius.circular(TinoRadius.chip),
            ),
            child: Icon(
              LucideIcons.plus,
              size: TinoSize.iconCompact,
              color: c.onAction,
            ),
          ),
        ),
      ),
    );
  }
}

/// Seção por categoria: rótulo 12/600 `text-secondary` + cartão raio 16.
class _Group extends StatelessWidget {
  const _Group({required this.listId, required this.section});
  final int listId;
  final ListSection section;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.category case final category?) ...[
          Semantics(
            header: true,
            child: Text(
              category.label,
              style: TinoType.caption
                  .withColor(c.textSecondary)
                  .weight(FontWeight.w600),
            ),
          ),
          const SizedBox(height: TinoSpace.s8),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
            border: Border.all(color: c.border, width: TinoSize.borderWidth),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
            child: Column(
              children: [
                for (final (i, item) in section.items.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: TinoSize.borderWidth,
                      thickness: TinoSize.borderWidth,
                      color: c.border,
                    ),
                  _ItemRow(
                    key: ValueKey('list-item-${item.id}'),
                    listId: listId,
                    item: item,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Linha na ordem manual: o cartão é montado linha a linha (a primeira e a
/// última arredondadas) para cada uma poder ser arrastada.
class _ManualRow extends StatelessWidget {
  const _ManualRow({
    super.key,
    required this.index,
    required this.first,
    required this.last,
    required this.child,
  });
  final int index;
  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    const r = Radius.circular(TinoRadius.cardCompact);
    final side = BorderSide(color: c.border, width: TinoSize.borderWidth);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.vertical(
          top: first ? r : Radius.zero,
          bottom: last ? r : Radius.zero,
        ),
        border: Border(
          left: side,
          right: side,
          top: first ? side : BorderSide.none,
          bottom: side,
        ),
      ),
      child: child,
    );
  }
}

/// Alça de arrastar (Lucide grip-vertical), botão 48.
class _Grip extends StatelessWidget {
  const _Grip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Mover $name',
    button: true,
    child: SizedBox.square(
      dimension: TinoSize.touchTarget,
      child: Icon(
        LucideIcons.gripVertical,
        size: TinoSize.iconCompact,
        color: context.tino.textSecondary,
      ),
    ),
  );
}

/// Linha de 52 com checkbox (M12): tocar marca e desmarca; segurar edita.
/// Marcado: nome em `text-secondary` e "No carrinho" em `action`.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    super.key,
    required this.listId,
    required this.item,
    this.handle,
  });
  final int listId;
  final ListItem item;
  final Widget? handle;

  static const _minHeight = 52.0;
  static const _fade = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final done = item.done;
    return Semantics(
      checked: done,
      label: done ? '${item.name}, no carrinho' : item.name,
      onLongPressHint: 'editar',
      excludeSemantics: handle == null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            ref.read(listsActionsProvider).setDone(listId, item.id, !done),
        onLongPress: () =>
            showListItemSheet(context, listId: listId, item: item),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: EdgeInsets.only(
              left: TinoSpace.s16,
              right: handle == null ? TinoSpace.s16 : TinoSpace.s4,
            ),
            child: Row(
              children: [
                _Check(done: done),
                const SizedBox(width: TinoSpace.s12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: _fade,
                    style: TinoType.corpo
                        .withColor(done ? c.textSecondary : c.textPrimary)
                        .weight(FontWeight.w500),
                    child: Text(item.name),
                  ),
                ),
                _InCart(visible: done),
                ?handle,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox 22: marcado em `action` com check `on-action`; o check entra
/// com escala 0,5 → 1 (`confirmacao`).
class _Check extends StatefulWidget {
  const _Check({required this.done});
  final bool done;

  @override
  State<_Check> createState() => _CheckState();
}

class _CheckState extends State<_Check> with SingleTickerProviderStateMixin {
  late final _scale = AnimationController.unbounded(
    vsync: this,
    value: widget.done ? 1 : 0,
  );

  static const _size = 22.0;

  @override
  void didUpdateWidget(_Check old) {
    super.didUpdateWidget(old);
    if (widget.done == old.done) return;
    if (!widget.done) {
      _scale.value = 0;
    } else if (TinoMotion.reduced(context)) {
      _scale.value = 1;
    } else {
      _scale.animateWith(TinoMotion.spring(TinoSprings.confirmacao, 0.5, 1));
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final done = widget.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: done ? c.action : c.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: done ? c.action : c.borderStrong, width: 2),
      ),
      child: done
          ? AnimatedBuilder(
              animation: _scale,
              builder: (context, child) =>
                  Transform.scale(scale: _scale.value, child: child),
              child: Icon(LucideIcons.check, size: 16, color: c.onAction),
            )
          : null,
    );
  }
}

/// "No carrinho" 12/600 `action`: entra com x 12 → 0 + opacidade (M12).
class _InCart extends StatelessWidget {
  const _InCart({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final reduced = TinoMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: visible ? 1 : 0),
      duration: reduced
          ? TinoMotion.reducedFade
          : const Duration(milliseconds: 220),
      curve: TinoCurves.easeOut,
      builder: (context, t, child) => t == 0
          ? const SizedBox.shrink()
          : Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(reduced ? 0 : 12 * (1 - t), 0),
                child: child,
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.only(left: TinoSpace.s8),
        child: Text(
          'No carrinho',
          style: TinoType.caption
              .withColor(context.tino.action)
              .weight(FontWeight.w600),
        ),
      ),
    );
  }
}
