import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_wordmark.dart';
import '../application/shopping_controller.dart';
import '../domain/budget.dart';
import '../domain/cart.dart';
import '../domain/decimal_input.dart';
import 'shopping_sheets.dart';

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final session = ref.watch(shoppingProvider);
      final items = session.cart.items;
      final text = Theme.of(context).textTheme;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: TinoWordmark(),
                ),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text('Comprar', style: text.headlineLarge),
                ),
                const SizedBox(height: 24),
                _TotalCard(session),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => showItemSheet(context),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: const Text('Adicionar produto'),
                ),
                const SizedBox(height: 28),
                if (items.isEmpty) ...[
                  Text('Carrinho vazio', style: text.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione produtos manualmente. A leitura de etiquetas '
                    'pela câmera chega em uma próxima etapa.',
                    style: text.bodyLarge,
                  ),
                ] else ...[
                  Text(
                    items.length == 1 ? '1 item' : '${items.length} itens',
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final item in items.reversed) _ItemTile(item),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard(this.session);
  final ShoppingSession session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = session.cart.total;
    final budget = session.budget;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TinoColors.softWhite,
        border: Border.all(color: TinoColors.lightJade),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Total no carrinho', style: text.bodyMedium),
          const SizedBox(height: 4),
          Text(
            total.format(),
            key: const ValueKey('cart-total'),
            style: text.headlineLarge,
          ),
          const SizedBox(height: 16),
          if (budget == null)
            OutlinedButton.icon(
              onPressed: () => showBudgetSheet(context),
              icon: const Icon(LucideIcons.wallet, size: 20),
              label: const Text('Definir orçamento'),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (total.cents / budget.cents).clamp(0, 1).toDouble(),
                minHeight: 8,
                color: TinoColors.jade,
                backgroundColor: TinoColors.offWhite,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (session.status != BudgetStatus.within) ...[
                  const Icon(LucideIcons.triangleAlert, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _budgetLine(session),
                    style: session.status == BudgetStatus.within
                        ? text.bodyMedium
                        : text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar orçamento',
                  onPressed: () => showBudgetSheet(context),
                  icon: const Icon(LucideIcons.pencil, size: 20),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _budgetLine(ShoppingSession s) {
    final budget = s.budget!;
    final left = (budget - s.cart.total).format();
    return switch (s.status) {
      BudgetStatus.over =>
        'Passou ${(s.cart.total - budget).format()} do orçamento de '
            '${budget.format()}',
      BudgetStatus.near =>
        'Perto do limite: restam $left de ${budget.format()}',
      _ => 'Restam $left de ${budget.format()}',
    };
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile(this.item);
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = switch (item) {
      UnitItem(:final quantity, :final price) =>
        '$quantity × ${price.format()}',
      WeightItem(:final grams, :final pricePerKg) =>
        '${formatKg(grams)} × ${pricePerKg.format()}/kg',
    };
    return InkWell(
      onTap: () => showItemSheet(context, item: item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(detail, style: text.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.total.format(),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
