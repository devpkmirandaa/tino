import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/domain/finished_purchase.dart';
import '../../shopping/presentation/budget_seal_chip.dart';
import '../../shopping/presentation/cart_item_row.dart';
import '../domain/history_summary.dart';

/// Resumo da compra (design/telas/16), somente leitura: data, "Você
/// pagou" com selo do orçamento e mercado, e os itens (5 e "Ver os N").
class PurchaseDetailPage extends ConsumerStatefulWidget {
  const PurchaseDetailPage({super.key, required this.id});
  final int id;

  @override
  ConsumerState<PurchaseDetailPage> createState() => _PurchaseDetailState();
}

class _PurchaseDetailState extends ConsumerState<PurchaseDetailPage> {
  bool _all = false;

  static const _preview = 5;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final history = ref.watch(historyProvider);
    final purchase = history.value?.where((p) => p.id == widget.id).firstOrNull;
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TinoSpace.s16,
        TinoSpace.s8,
        TinoSpace.s16,
        TinoSpace.s24,
      ),
      children: [
        Row(
          children: [
            Transform.translate(
              offset: const Offset(-TinoSpace.s12, 0),
              child: TinoIconButton(
                key: const ValueKey('purchase-back'),
                icon: LucideIcons.chevronLeft,
                semanticLabel: 'Voltar ao Histórico',
                onPressed: () => context.go('/historico'),
              ),
            ),
            if (purchase != null)
              Expanded(
                child: Transform.translate(
                  offset: const Offset(-TinoSpace.s8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          dayMonth(purchase.finishedAt, now),
                          style: TinoType.tela.withColor(c.textPrimary),
                        ),
                      ),
                      Text(
                        summarySubtitle(purchase),
                        style: TinoType.secundario.withColor(c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: TinoSpace.s16),
        if (purchase != null) ...[
          _PaidCard(purchase),
          const SizedBox(height: TinoSpace.s16),
          Text(
            'Itens',
            style: TinoType.caption
                .withColor(c.textSecondary)
                .weight(FontWeight.w600),
          ),
          const SizedBox(height: TinoSpace.s8),
          _Items(
            purchase,
            limit: _all ? null : _preview,
            onShowAll: () => setState(() => _all = true),
          ),
          const SizedBox(height: TinoSpace.s24),
          Text(
            'Compras guardadas ficam como foram registradas.',
            textAlign: TextAlign.center,
            style: TinoType.caption.withColor(c.textSecondary),
          ),
        ] else if (!history.isLoading)
          Text(
            'Compra não encontrada.',
            style: TinoType.corpo.withColor(c.textPrimary),
          ),
      ],
    );
  }
}

/// "Você pagou" 40/48 + selo do orçamento + mercado, cada um só se houver.
class _PaidCard extends StatelessWidget {
  const _PaidCard(this.purchase);
  final FinishedPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final seal = budgetSeal(purchase.cart.total, purchase.budget);
    final place = purchase.place;
    return TinoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TinoSpace.s16,
        vertical: TinoSpace.s24,
      ),
      child: Column(
        children: [
          Text(
            'Você pagou',
            style: TinoType.secundario.withColor(c.textSecondary),
          ),
          const SizedBox(height: TinoSpace.s4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              purchase.cart.total.format(),
              key: const ValueKey('purchase-total'),
              style: TinoType.total.withColor(c.textPrimary).money,
            ),
          ),
          if (seal != null) ...[
            const SizedBox(height: TinoSpace.s8),
            BudgetSealChip(
              key: ValueKey(seal.over ? 'purchase-seal-over' : 'purchase-seal'),
              seal: seal,
              icon: LucideIcons.circleCheck,
            ),
          ],
          if (place != null) ...[
            const SizedBox(height: TinoSpace.s8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: c.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    place,
                    style: TinoType.caption.withColor(c.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Cartão de itens com a linha padrão do carrinho; com [limit], mostra só
/// os primeiros e "Ver os N itens".
class _Items extends StatelessWidget {
  const _Items(this.purchase, {required this.limit, required this.onShowAll});
  final FinishedPurchase purchase;
  final int? limit;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final items = purchase.cart.items;
    final cut = limit != null && items.length > limit!;
    final shown = cut ? items.take(limit!) : items;
    final divider = Divider(
      height: TinoSize.borderWidth,
      thickness: TinoSize.borderWidth,
      color: c.border,
    );
    return TinoCard(
      compact: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in shown.indexed) ...[
            if (i > 0) divider,
            TinoItemRow(
              title: cartItemName(item),
              titleMuted: item.unnamed,
              subtitle: cartItemDetail(item),
              price: item.total.format(),
            ),
          ],
          if (cut) ...[
            divider,
            TinoButton.text(
              key: const ValueKey('purchase-show-all'),
              label: 'Ver os ${items.length} itens',
              expand: true,
              onPressed: onShowAll,
            ),
          ],
        ],
      ),
    );
  }
}
