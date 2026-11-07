import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../application/shopping_controller.dart';
import '../domain/cart.dart';
import '../domain/decimal_input.dart';
import '../domain/item_edit.dart';
import '../domain/scan_add.dart';
import '../domain/tag_reader.dart';
import 'cart_entrance.dart';
import 'price_conflict.dart';

/// Digitar preço (design/telas/11-digitar-preco.html): item novo pelo
/// teclado numérico do celular. Abre pelos botões "Digitar preço", pelo
/// "Digitar" do scanner ou com o rascunho de uma leitura ([draft]), que
/// chega preenchido e com o foco no que falta. Mesmo produto com outro
/// preço: mesmo bloco e regra do scanner.
Future<void> showTypePriceSheet(BuildContext context, {TagReading? draft}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final entry = _Entry(
    container.read(shoppingProvider.notifier).newId(),
    draft,
  );
  return showTinoSheet<void>(
    context,
    barrierLabel: 'Fechar ${entry.title.toLowerCase()}',
    onDisposed: entry.dispose,
    blocks: [
      _Header(entry),
      _ModeBlock(entry),
      _AmountBlock(entry),
      _NameBlock(entry),
      _ActionBlock(entry),
    ],
  );
}

/// O que falta na leitura decide título e foco.
enum _Focus { price, weight, name }

class _Entry extends ChangeNotifier {
  _Entry(this.id, TagReading? draft)
    : tagText = draft?.tagText,
      byWeight = draft?.perKg ?? false,
      focus = switch (draft) {
        TagReading(perKg: true) => _Focus.weight,
        TagReading(name: null) => _Focus.name,
        _ => _Focus.price,
      },
      title = switch (draft) {
        TagReading(perKg: true) => 'Informar peso',
        TagReading(name: null) => 'Dar nome',
        _ => 'Digitar preço',
      } {
    final price = draft?.price;
    for (final c in [name, this.price, weight]) {
      c.addListener(_changed);
    }
    name.text = draft?.name ?? '';
    if (price != null) this.price.text = plainScaled(price.cents, 2);
  }

  final String id;
  final String? tagText;
  final String title;
  final _Focus focus;
  bool byWeight;
  int quantity = 1;
  final name = TextEditingController();
  final price = TextEditingController();
  final weight = TextEditingController();

  /// Adição esperando a escolha: já tem esse produto com outro preço.
  ScanAdd? pending;

  CartItem? get result => buildItem(id, (
    name: name.text,
    byWeight: byWeight,
    price: price.text,
    quantity: quantity,
    weight: weight.text,
  ), tagText: tagText);

  void _changed() {
    pending = null;
    notifyListeners();
  }

  void setByWeight(bool value) {
    if (value == byWeight) return;
    byWeight = value;
    _changed();
  }

  void setQuantity(int value) {
    quantity = value;
    _changed();
  }

  void ask(ScanAdd scan) {
    pending = scan;
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
  const _Header(this.entry);
  final _Entry entry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            entry.title,
            style: TinoType.secao.withColor(context.tino.textPrimary),
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(TinoSpace.s12, 0),
        child: TinoIconButton(
          key: const ValueKey('type-price-close'),
          icon: LucideIcons.x,
          semanticLabel: 'Fechar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  );
}

class _ModeBlock extends StatelessWidget {
  const _ModeBlock(this.entry);
  final _Entry entry;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: entry,
    builder: (context, _) => TinoSegmented<bool>(
      key: const ValueKey('type-price-mode'),
      segments: const [
        (value: false, label: 'Por unidade'),
        (value: true, label: 'Por quilo'),
      ],
      selected: entry.byWeight,
      onChanged: entry.setByWeight,
    ),
  );
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock(this.entry);
  final _Entry entry;

  static const _decimal = TextInputType.numberWithOptions(decimal: true);

  /// Preço em 56 de altura, 24/700 tabular (telas/11).
  static const _priceHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return ListenableBuilder(
      listenable: entry,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TinoInput(
              key: const ValueKey('type-price-price'),
              label: entry.byWeight ? 'Preço por kg' : 'Preço',
              controller: entry.price,
              keyboardType: _decimal,
              textInputAction: TextInputAction.next,
              autofocus: entry.focus == _Focus.price,
              money: true,
              valueStyle: TinoType.tela,
              height: _priceHeight,
              suffix: entry.byWeight ? 'R\$/kg' : 'R\$',
            ),
          ),
          const SizedBox(width: TinoSpace.s12),
          if (entry.byWeight)
            Expanded(
              child: TinoInput(
                key: const ValueKey('type-price-weight'),
                label: 'Peso',
                controller: entry.weight,
                keyboardType: _decimal,
                textInputAction: TextInputAction.next,
                autofocus: entry.focus == _Focus.weight,
                height: _priceHeight,
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
                  key: const ValueKey('type-price-quantity'),
                  value: entry.quantity,
                  onChanged: entry.setQuantity,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock(this.entry);
  final _Entry entry;

  @override
  Widget build(BuildContext context) => TinoInput(
    key: const ValueKey('type-price-name'),
    label: 'Nome (opcional)',
    hint: 'Ex.: Arroz',
    controller: entry.name,
    autofocus: entry.focus == _Focus.name,
    textInputAction: TextInputAction.done,
  );
}

class _ActionBlock extends ConsumerWidget {
  const _ActionBlock(this.entry);
  final _Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListenableBuilder(
    listenable: entry,
    builder: (context, _) {
      final pending = entry.pending;
      final existing = pending?.conflict;
      if (pending != null && existing != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PriceConflictBlock(
              name: existing.name,
              current: existing.price,
              next: pending.item.price,
              nextLabel: 'Digitado',
            ),
            const SizedBox(height: TinoSpace.s16),
            TinoButton.primary(
              key: const ValueKey('type-price-use-new'),
              label: 'Atualizar para ${pending.item.price.format()}',
              expand: true,
              onPressed: () => _finish(
                context,
                ref,
                pending.copyWith(choice: ConflictChoice.useNew).apply()!,
              ),
            ),
            const SizedBox(height: TinoSpace.s8),
            TinoButton.outlined(
              key: const ValueKey('type-price-keep'),
              label: 'Manter ${existing.price.format()}',
              expand: true,
              // O carrinho fica como está; o que foi digitado é descartado.
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      }
      final item = entry.result;
      return TinoButton.primary(
        key: const ValueKey('type-price-add'),
        label: item == null
            ? 'Adicionar'
            : 'Adicionar · ${item.total.format()}',
        icon: LucideIcons.plus,
        expand: true,
        onPressed: item == null ? null : () => _add(context, ref, item),
      );
    },
  );

  void _add(BuildContext context, WidgetRef ref, CartItem item) {
    final cart = ref.read(shoppingProvider).value?.cart;
    if (cart == null) return;
    if (item is UnitItem) {
      final scan = ScanAdd(before: cart, item: item);
      final result = scan.apply();
      if (result == null) return entry.ask(scan);
      return _finish(context, ref, result);
    }
    // Por peso nunca soma nem conflita: cada pesagem é uma linha.
    _finish(context, ref, (
      cart: cart.add(item).cart,
      lineId: item.id,
      unitPrice: (item as WeightItem).pricePerKg,
    ));
  }

  void _finish(BuildContext context, WidgetRef ref, ScanAddResult result) {
    ref.read(shoppingProvider.notifier).setCart(result.cart);
    final item = entry.result;
    // Linha nova entra no topo do Comprar com M3c; soma em linha existente não.
    if (result.lineId == entry.id) {
      final entrance = ref.read(cartEntranceProvider.notifier)
        ..mark(result.lineId)
        ..release();
      Timer(const Duration(seconds: 1), entrance.settle);
    }
    if (item != null) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${item.unnamed ? 'Item' : item.name}, ${item.total.format()}, '
        'adicionado',
        Directionality.of(context),
      );
    }
    Navigator.pop(context);
  }
}
