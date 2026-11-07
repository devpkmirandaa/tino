import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../application/shopping_controller.dart';
import '../domain/cart.dart';
import '../domain/item_edit.dart';
import 'cart_removal.dart';

/// Detalhe do item (design/telas/05-detalhe-item.html): corrige nome, modo,
/// preço e quantidade ou peso de um item que já está no carrinho. Folha M5
/// (arrastar pra baixo fecha), segmentado M6, tirar com desfazer (M8).
Future<void> showItemDetailSheet(BuildContext context, CartItem item) {
  final draft = _Draft(item);
  return showTinoSheet<void>(
    context,
    barrierLabel: 'Fechar detalhe do item',
    onDisposed: draft.dispose,
    blocks: [
      _Header(draft),
      _NameBlock(draft),
      _ModeBlock(draft),
      _AmountBlock(draft),
      _SubtotalBlock(draft),
      _ActionsBlock(draft),
    ],
  );
}

/// Estado da folha, dividido entre os blocos da cascata.
class _Draft extends ChangeNotifier {
  _Draft(this.original) {
    final edit = editOf(original);
    byWeight = edit.byWeight;
    quantity = edit.quantity;
    name = TextEditingController(text: edit.name)..addListener(notifyListeners);
    price = TextEditingController(text: edit.price)
      ..addListener(notifyListeners);
    weight = TextEditingController(text: edit.weight)
      ..addListener(notifyListeners);
  }

  final CartItem original;
  late bool byWeight;
  late int quantity;
  late final TextEditingController name;
  late final TextEditingController price;
  late final TextEditingController weight;

  CartItem? get result => applyEdit(original, (
    name: name.text,
    byWeight: byWeight,
    price: price.text,
    quantity: quantity,
    weight: weight.text,
  ));

  void setByWeight(bool value) {
    if (value == byWeight) return;
    byWeight = value;
    notifyListeners();
  }

  void setQuantity(int value) {
    quantity = value;
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    weight.dispose();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  const _Header(this.draft);
  final _Draft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              draft.original.name,
              style: TinoType.secao.withColor(c.textPrimary),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(TinoSpace.s12, 0),
          child: TinoIconButton(
            key: const ValueKey('item-detail-close'),
            icon: LucideIcons.x,
            semanticLabel: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock(this.draft);
  final _Draft draft;

  @override
  Widget build(BuildContext context) {
    final tag = draft.original.tagText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TinoInput(
          key: const ValueKey('item-detail-name'),
          label: 'Nome',
          controller: draft.name,
          textInputAction: TextInputAction.next,
        ),
        if (tag != null && tag.isNotEmpty) ...[
          const SizedBox(height: TinoSpace.s4),
          Text(
            'Na etiqueta: $tag',
            style: TinoType.caption.withColor(context.tino.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _ModeBlock extends StatelessWidget {
  const _ModeBlock(this.draft);
  final _Draft draft;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) => TinoSegmented<bool>(
      key: const ValueKey('item-detail-mode'),
      segments: const [
        (value: false, label: 'Por unidade'),
        (value: true, label: 'Por quilo'),
      ],
      selected: draft.byWeight,
      onChanged: draft.setByWeight,
    ),
  );
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock(this.draft);
  final _Draft draft;

  static const _decimal = TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TinoInput(
              key: const ValueKey('item-detail-price'),
              label: draft.byWeight ? 'Preço por kg' : 'Preço',
              controller: draft.price,
              keyboardType: _decimal,
              money: true,
              valueStyle: TinoType.subtitulo,
              suffix: draft.byWeight ? 'R\$/kg' : 'R\$',
            ),
          ),
          const SizedBox(width: TinoSpace.s12),
          if (draft.byWeight)
            Expanded(
              child: TinoInput(
                key: const ValueKey('item-detail-weight'),
                label: 'Peso',
                controller: draft.weight,
                keyboardType: _decimal,
                hint: '0,350',
                suffix: 'kg',
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantidade',
                  style: TinoType.label.withColor(c.textPrimary),
                ),
                const SizedBox(height: TinoSpace.s8),
                TinoQuantityStepper(
                  key: const ValueKey('item-detail-quantity'),
                  value: draft.quantity,
                  onChanged: draft.setQuantity,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SubtotalBlock extends StatelessWidget {
  const _SubtotalBlock(this.draft);
  final _Draft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final total = draft.result?.total.format();
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TinoSpace.s16,
            vertical: TinoSpace.s12,
          ),
          decoration: BoxDecoration(
            color: c.surfaceSoft,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Subtotal',
                  style: TinoType.secundario.withColor(c.textSecondary),
                ),
              ),
              Text(
                total ?? '—',
                key: const ValueKey('item-detail-subtotal'),
                style: TinoType.secao.withColor(c.textPrimary).money,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionsBlock extends ConsumerWidget {
  const _ActionsBlock(this.draft);
  final _Draft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) {
      final result = draft.result;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TinoButton.primary(
            key: const ValueKey('item-detail-save'),
            label: 'Salvar',
            expand: true,
            onPressed: result == null
                ? null
                : () {
                    ref.read(shoppingProvider.notifier).replace(result);
                    Navigator.pop(context);
                  },
          ),
          const SizedBox(height: TinoSpace.s4),
          TinoButton.text(
            key: const ValueKey('item-detail-remove'),
            label: 'Tirar do carrinho',
            icon: LucideIcons.trash2,
            muted: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(cartRemovalProvider.notifier).remove(draft.original.id);
            },
          ),
        ],
      );
    },
  );
}
