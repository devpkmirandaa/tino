import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/presentation/shopping_page.dart';
import '../application/lists_providers.dart';
import '../domain/category_suggester.dart';
import '../domain/frequent_items.dart';
import '../domain/shopping_list.dart';
import 'lists_sheets.dart';
import 'organize_sheet.dart';

/// Lista v2 (design/specs/lista-v2.md, telas/08): progresso e itens que
/// faltam em cima; o que se faz durante a compra fica no painel de baixo
/// ("Adicionar item", "Você costuma levar" e "Escanear preço"). Marcar tira
/// o item da lista e manda para "No carrinho"; tocar na linha edita.
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

  /// Seção "No carrinho" aberta (recolhida por padrão).
  bool _cartOpen = false;

  int get _id => widget.id;

  @override
  void dispose() {
    _add.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  /// Categoria sugerida pelo nome e quantidade 1.
  Future<void> _addNamed(String name) => ref
      .read(listsActionsProvider)
      .addItem(
        _id,
        name: name,
        category: suggestCategory(
          name,
          learned: ref.read(learnedCategoriesProvider).value ?? const {},
        ),
      );

  /// Tecla de confirmar ou botão "Adicionar": adiciona, limpa o campo e o
  /// teclado continua aberto para o próximo item.
  Future<void> _addFromField() async {
    final name = _add.text.trim();
    _keepKeyboard();
    if (name.isEmpty) return;
    _add.clear();
    await _addNamed(name);
    _keepKeyboard();
  }

  /// O campo não perde o foco na tecla de confirmar (onEditingComplete),
  /// mas há teclados que se fecham sozinhos nela (Moto G54): o campo pede o
  /// foco de volta e reabre o teclado.
  void _keepKeyboard() {
    if (!mounted) return;
    if (!_addFocus.hasFocus) _addFocus.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  /// Chip "Você costuma levar": adiciona e limpa o que estava digitado.
  Future<void> _addFrequent(String name) async {
    _add.clear();
    await _addNamed(name);
  }

  /// [to] já descontado o item retirado (`onReorderItem`).
  Future<void> _reorder(List<ListItem> items, int from, int to) async {
    final next = [...items];
    next.insert(to, next.removeAt(from));
    setState(() => _dragged = next);
    await ref.read(listsActionsProvider).reorderItems(_id, [
      for (final i in next) i.id,
    ]);
    await ref.read(listItemsProvider(_id).future);
    if (mounted) setState(() => _dragged = null);
  }

  /// Liga a lista à compra (se ainda não estiver) e abre o scanner a partir
  /// do botão ([button]).
  Future<void> _scan(BuildContext button) async {
    final session = await ref.read(shoppingProvider.future);
    if (session.listId != _id) {
      ref.read(shoppingProvider.notifier).setList(_id);
    }
    if (button.mounted) await scanPrice(button);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final list = ref.watch(listProvider(_id));
    final items = ref.watch(listItemsProvider(_id)).value ?? const [];
    // Carrega as categorias aprendidas antes de adicionar pelo campo.
    ref.watch(learnedCategoriesProvider);
    final linked = ref.watch(shoppingProvider).value?.listId == _id;
    final past = ref.watch(pastPurchasesProvider).value ?? const [];
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
    final (:pending, :done) = splitDone(items);
    final manual = info.order == ListOrder.manual;
    final sections = arrangeList(
      pending,
      info.order,
      categoryOrder: info.categoryOrder,
    );
    final inCart = [
      for (final s in arrangeList(
        done,
        info.order,
        categoryOrder: info.categoryOrder,
      ))
        ...s.items,
    ];
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
                  TinoSpace.s12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        info: info,
                        onMore: () =>
                            showListOptionsSheet(context, ref, list: info),
                      ),
                      const SizedBox(height: TinoSpace.s12),
                      _Progress(
                        done: done.length,
                        total: items.length,
                        linked: linked,
                      ),
                      const SizedBox(height: TinoSpace.s12),
                      _Toolbar(
                        missing: pending.length,
                        order: info.order,
                        onOrganize: () => showOrganizeSheet(
                          context,
                          list: info,
                          items: items,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty || pending.isEmpty)
                SliverPadding(
                  padding: gutter,
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      items.isEmpty
                          ? 'Escreva o primeiro item no campo de baixo. A '
                                'categoria é sugerida pelo nome.'
                          : 'Tudo no carrinho.',
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
              if (inCart.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    TinoSpace.s16,
                    TinoSpace.s16,
                    TinoSpace.s16,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _CartToggle(
                        count: inCart.length,
                        open: _cartOpen,
                        onPressed: () => setState(() => _cartOpen = !_cartOpen),
                      ),
                      if (_cartOpen) ...[
                        const SizedBox(height: TinoSpace.s8),
                        _Group(
                          listId: _id,
                          section: (category: null, items: inCart),
                        ),
                      ],
                    ],
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: TinoSpace.s16)),
            ],
          ),
        ),
        // Só o painel acompanha o que é digitado.
        ValueListenableBuilder(
          valueListenable: _add,
          builder: (context, value, _) {
            final typed = value.text.trim();
            final typing = typed.isNotEmpty;
            return _BottomPanel(
              field: TinoInput(
                key: const ValueKey('add-list-item'),
                hint: 'Adicionar item',
                height: 56,
                controller: _add,
                focusNode: _addFocus,
                highlight: typing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onEditingComplete: _addFromField,
                trailing: _AddPill(visible: typing, onPressed: _addFromField),
              ),
              category: typing
                  ? suggestCategory(
                      typed,
                      learned:
                          ref.read(learnedCategoriesProvider).value ?? const {},
                    )
                  : null,
              frequent: frequentItems(past, items, query: typed),
              onFrequent: _addFrequent,
              onScan: _scan,
            );
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info, required this.onMore});
  final ShoppingListInfo info;
  final VoidCallback onMore;

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
        Transform.translate(
          offset: const Offset(TinoSpace.s12, 0),
          child: TinoIconButton(
            key: const ValueKey('list-more'),
            icon: LucideIcons.ellipsisVertical,
            semanticLabel: 'Mais opções da lista',
            onPressed: onMore,
          ),
        ),
      ],
    );
  }
}

/// Cartão "N de M no carrinho" com a barra M9 de 6 e o selo "Na compra".
class _Progress extends StatelessWidget {
  const _Progress({
    required this.done,
    required this.total,
    required this.linked,
  });
  final int done;
  final int total;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Container(
      padding: const EdgeInsets.all(TinoSpace.s16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(TinoRadius.card),
        border: Border.all(color: c.border, width: TinoSize.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$done de $total no carrinho',
                  style: TinoType.subtitulo
                      .withColor(c.textPrimary)
                      .copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
              if (linked) const _LinkedSeal(),
            ],
          ),
          const SizedBox(height: TinoSpace.s12),
          TinoProgressBar(
            value: total == 0 ? 0 : done / total,
            compact: true,
            haptics: false,
            semanticLabel: 'Itens no carrinho',
          ),
        ],
      ),
    );
  }
}

/// "Na compra": corrente + rótulo 12/600 `action`, fundo `surface-soft`
/// (no escuro, `jade-tint`).
class _LinkedSeal extends StatelessWidget {
  const _LinkedSeal();

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Container(
      key: const ValueKey('list-linked'),
      height: 28,
      padding: const EdgeInsets.only(left: TinoSpace.s8, right: 10),
      decoration: BoxDecoration(
        color: c.jadeTint ?? c.surfaceSoft,
        borderRadius: BorderRadius.circular(TinoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.link, size: 14, color: c.action),
          const SizedBox(width: TinoSpace.s4),
          Text(
            'Na compra',
            style: TinoType.caption.withColor(c.action).weight(FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// "Faltam N" à esquerda; chip da ordem à direita, que abre o Organizar.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.missing,
    required this.order,
    required this.onOrganize,
  });
  final int missing;
  final ListOrder order;
  final VoidCallback onOrganize;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Faltam $missing',
            style: TinoType.label.withColor(c.textSecondary),
          ),
        ),
        TinoPressable(
          key: const ValueKey('list-organize'),
          onPressed: onOrganize,
          semanticLabel: 'Ordem: ${order.label.toLowerCase()}. Mudar',
          excludeSemantics: true,
          builder: (context, pressed) => Padding(
            padding: const EdgeInsets.symmetric(vertical: TinoSpace.s4),
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 14, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TinoRadius.pill),
                border: Border.all(
                  color: c.borderStrong,
                  width: TinoSize.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(order.label, style: TinoType.label.withColor(c.action)),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.chevronDown, size: 18, color: c.action),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seção: rótulo 12/600 `text-secondary` (se houver categoria) + cartão
/// raio 16 com as linhas.
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

/// Linha de 56: caixa de marcar numa área de 48 à esquerda; o resto da
/// linha edita o item (nome 16/500, apoio 12/500, lápis 20). Marcar mostra
/// o check (M12) e só então o item muda de seção.
class _ItemRow extends ConsumerStatefulWidget {
  const _ItemRow({
    super.key,
    required this.listId,
    required this.item,
    this.handle,
  });
  final int listId;
  final ListItem item;
  final Widget? handle;

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  /// Estado mostrado enquanto o check anima, antes de gravar.
  bool? _shown;

  static const _beforeMove = Duration(milliseconds: 300);

  Future<void> _toggle() async {
    if (_shown != null) return;
    final next = !widget.item.done;
    setState(() => _shown = next);
    if (!TinoMotion.reduced(context)) await Future<void>.delayed(_beforeMove);
    await ref
        .read(listsActionsProvider)
        .setDone(widget.listId, widget.item.id, next);
    if (mounted) setState(() => _shown = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final item = widget.item;
    final done = _shown ?? item.done;
    final detail = itemDetail(item);
    return Padding(
      padding: EdgeInsets.only(
        left: TinoSpace.s4,
        right: widget.handle == null ? 0 : TinoSpace.s4,
      ),
      child: Row(
        children: [
          Semantics(
            checked: done,
            label: '${item.name} no carrinho',
            child: GestureDetector(
              key: ValueKey('list-check-${item.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: SizedBox.square(
                dimension: TinoSize.touchTarget,
                child: Center(child: _Check(done: done)),
              ),
            ),
          ),
          Expanded(
            child: TinoPressable(
              key: ValueKey('list-edit-${item.id}'),
              scale: TinoPressScale.surface,
              semanticLabel: 'Editar ${item.name}',
              excludeSemantics: true,
              onPressed: () =>
                  showListItemSheet(context, listId: widget.listId, item: item),
              builder: (context, pressed) => ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: TinoSpace.s4,
                    right: widget.handle == null ? TinoSpace.s16 : 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: TinoType.corpo
                                  .withColor(
                                    done ? c.textSecondary : c.textPrimary,
                                  )
                                  .weight(FontWeight.w500),
                              child: Text(item.name),
                            ),
                            if (detail != null)
                              Text(
                                detail,
                                style: TinoType.caption.withColor(
                                  c.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: TinoSpace.s12),
                      Icon(
                        LucideIcons.pencil,
                        size: TinoSize.iconCompact,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ?widget.handle,
        ],
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

/// "No carrinho · N": botão 48 em `surface-soft`, "Ver"/"Esconder" + seta.
class _CartToggle extends StatelessWidget {
  const _CartToggle({
    required this.count,
    required this.open,
    required this.onPressed,
  });
  final int count;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Semantics(
      expanded: open,
      child: TinoPressable(
        key: const ValueKey('list-cart-toggle'),
        scale: TinoPressScale.surface,
        semanticLabel: 'No carrinho, $count',
        excludeSemantics: true,
        onPressed: onPressed,
        builder: (context, pressed) => Container(
          constraints: const BoxConstraints(minHeight: TinoSize.touchTarget),
          padding: const EdgeInsets.only(
            left: TinoSpace.s16,
            right: TinoSpace.s12,
          ),
          decoration: BoxDecoration(
            color: c.surfaceSoft,
            borderRadius: BorderRadius.circular(TinoRadius.control),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'No carrinho · $count',
                  style: TinoType.label.withColor(c.textPrimary),
                ),
              ),
              Text(
                open ? 'Esconder' : 'Ver',
                style: TinoType.caption.withColor(c.textSecondary),
              ),
              const SizedBox(width: 10),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: TinoMotion.reduced(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: TinoSize.iconCompact,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painel fixo: fundo `surface`, raio superior 24, borda superior `border`.
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.field,
    required this.category,
    required this.frequent,
    required this.onFrequent,
    required this.onScan,
  });
  final Widget field;

  /// Categoria sugerida enquanto há texto ("Vai pra Mercearia").
  final ItemCategory? category;
  final List<String> frequent;
  final ValueChanged<String> onFrequent;
  final ValueChanged<BuildContext> onScan;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        TinoSpace.s16,
        TinoSpace.s16,
        TinoSpace.s16,
        TinoSpace.s24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TinoRadius.panel),
        ),
        border: Border(
          top: BorderSide(color: c.border, width: TinoSize.borderWidth),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          if (category case final category?) ...[
            const SizedBox(height: TinoSpace.s8),
            Padding(
              padding: const EdgeInsets.only(left: TinoSpace.s4),
              child: Text(
                'Vai pra ${category.label}',
                key: const ValueKey('list-add-category'),
                style: TinoType.caption.withColor(c.textSecondary),
              ),
            ),
          ],
          if (frequent.isNotEmpty) ...[
            const SizedBox(height: TinoSpace.s8),
            Semantics(
              label: 'Você costuma levar',
              container: true,
              child: SingleChildScrollView(
                key: const ValueKey('list-frequent'),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (final (i, name) in frequent.indexed) ...[
                      if (i > 0) const SizedBox(width: TinoSpace.s8),
                      _FrequentChip(
                        name: name,
                        onPressed: () => onFrequent(name),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: TinoSpace.s4),
          ] else
            const SizedBox(height: TinoSpace.s12),
          Builder(
            builder: (button) => TinoButton.primary(
              key: const ValueKey('list-scan'),
              label: 'Escanear preço',
              icon: LucideIcons.scanLine,
              size: TinoButtonSize.large,
              expand: true,
              onPressed: () => onScan(button),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Adicionar" dentro do campo (telas/08a): pílula de 40 (toque 48) em
/// `action`, check 18 + rótulo 14/600 `on-action`. Entra e sai com
/// opacidade (150 ms) e escala 0,8 → 1 na mola `selecao`; sem texto, some.
class _AddPill extends StatefulWidget {
  const _AddPill({required this.visible, required this.onPressed});
  final bool visible;
  final VoidCallback onPressed;

  @override
  State<_AddPill> createState() => _AddPillState();
}

class _AddPillState extends State<_AddPill> with TickerProviderStateMixin {
  static const _hidden = 0.8;

  late final _scale = AnimationController.unbounded(
    vsync: this,
    value: widget.visible ? 1 : _hidden,
  );
  late final _fade = AnimationController(
    vsync: this,
    duration: TinoMotion.reducedFade,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(_AddPill old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    final to = widget.visible ? 1.0 : _hidden;
    if (widget.visible) {
      _fade.forward();
    } else {
      _fade.reverse();
    }
    if (TinoMotion.reduced(context)) {
      _scale.value = to;
    } else {
      _scale.animateWith(
        TinoMotion.spring(
          TinoSprings.selecao,
          _scale.value,
          to,
          _scale.velocity,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final pill = TinoPressable(
      key: const ValueKey('add-list-item-button'),
      onPressed: widget.visible ? widget.onPressed : null,
      semanticLabel: 'Adicionar',
      excludeSemantics: true,
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.only(
          left: TinoSpace.s8,
          right: 6,
          top: TinoSpace.s4,
          bottom: TinoSpace.s4,
        ),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 10, right: 14),
          decoration: BoxDecoration(
            color: pressed ? c.actionPressed : c.action,
            borderRadius: BorderRadius.circular(TinoRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.check, size: 18, color: c.onAction),
              const SizedBox(width: 6),
              Text('Adicionar', style: TinoType.label.withColor(c.onAction)),
            ],
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_scale, _fade]),
      child: pill,
      builder: (context, child) {
        if (_fade.value == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: TinoCurves.easeOut.transform(_fade.value),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}

/// Chip de 40 (toque 48) em pílula `surface-soft`, + em `action`.
class _FrequentChip extends StatelessWidget {
  const _FrequentChip({required this.name, required this.onPressed});
  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return TinoPressable(
      key: ValueKey('frequent-$name'),
      onPressed: onPressed,
      semanticLabel: 'Adicionar $name',
      excludeSemantics: true,
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.symmetric(vertical: TinoSpace.s4),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 10, right: 14),
          decoration: BoxDecoration(
            color: c.surfaceSoft,
            borderRadius: BorderRadius.circular(TinoRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 16, color: c.action),
              const SizedBox(width: TinoSpace.s4),
              Text(name, style: TinoType.label.withColor(c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
