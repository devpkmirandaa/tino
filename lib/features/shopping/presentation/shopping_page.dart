import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../lists/presentation/linked_list_card.dart';
import '../application/shopping_controller.dart';
import '../domain/budget.dart';
import 'cart_item_row.dart';
import 'scanner_page.dart';
import 'shopping_sheets.dart';

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final session = switch (ref.watch(shoppingProvider)) {
        AsyncData(:final value) => value,
        AsyncError() => null,
        _ => const ShoppingSession(),
      };
      if (session == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(TinoSpace.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não deu pra abrir a compra salva.'),
                const SizedBox(height: TinoSpace.s12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(shoppingProvider),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        );
      }
      final loading = !ref.watch(shoppingProvider).hasValue;
      final items = session.cart.items;
      final text = Theme.of(context).textTheme;
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TinoSpace.s16,
                TinoSpace.s24,
                TinoSpace.s16,
                TinoSpace.s16,
              ),
              child: _Width(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Comprar', style: text.headlineLarge),
                    ),
                    const SizedBox(height: TinoSpace.s16),
                    _TotalCard(session),
                    if (session.listId case final listId?) ...[
                      const SizedBox(height: TinoSpace.s16),
                      LinkedListCard(listId),
                    ] else
                      const UseListPrompt(),
                    const SizedBox(height: TinoSpace.s24),
                    if (items.isEmpty)
                      const _EmptyCart()
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              items.length == 1
                                  ? '1 item'
                                  : '${items.length} itens',
                              style: text.titleLarge,
                            ),
                          ),
                          TextButton.icon(
                            key: const ValueKey('clear-cart'),
                            onPressed: () => _confirmClear(context, ref),
                            icon: const Icon(LucideIcons.trash2, size: 20),
                            label: const Text('Limpar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: TinoSpace.s12),
                      _Card(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, item) in items.reversed.indexed) ...[
                              if (i > 0) const Divider(indent: TinoSpace.s16),
                              CartItemRow(
                                item,
                                onTap: () => showItemSheet(context, item: item),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: TinoSpace.s16),
                      OutlinedButton(
                        onPressed: () => showFinishSheet(context),
                        child: const Text('Finalizar compra'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TinoSpace.s16,
              TinoSpace.s8,
              TinoSpace.s16,
              TinoSpace.s16,
            ),
            child: _Width(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('add-product'),
                      onPressed: loading ? null : () => showItemSheet(context),
                      icon: const Icon(LucideIcons.keyboard, size: 20),
                      label: const Text('Digitar'),
                    ),
                  ),
                  const SizedBox(width: TinoSpace.s12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: loading ? null : () => _scan(context),
                      icon: const Icon(LucideIcons.scanLine, size: 20),
                      label: const Text('Escanear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Pergunta antes de esvaziar o carrinho: não dá para desfazer.
Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
  final count = ref.read(shoppingProvider).value?.cart.items.length ?? 0;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Limpar carrinho?'),
      content: Text(
        '${count == 1 ? 'O item sai' : 'Os $count itens saem'} do carrinho. '
        'O orçamento continua.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Limpar'),
        ),
      ],
    ),
  );
  if (ok == true) ref.read(shoppingProvider.notifier).clear();
}

/// Abre o scanner e leva a leitura (ou um pedido para digitar) ao painel.
Future<void> _scan(BuildContext context) async {
  final result = await context.push<ScanResult>('/escanear');
  if (!context.mounted) return;
  switch (result) {
    case ScanRead(:final reading):
      await showItemSheet(context, draft: reading);
    case ScanTypeInstead():
      await showItemSheet(context);
    case null:
      break;
  }
}

class _Width extends StatelessWidget {
  const _Width({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(TinoSpace.s16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: TinoTokens.surface,
      border: Border.all(color: TinoTokens.border),
      borderRadius: BorderRadius.circular(TinoRadius.card),
    ),
    child: child,
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Total no carrinho', style: text.bodyMedium),
          const SizedBox(height: TinoSpace.s4),
          Text(
            total.format(),
            key: const ValueKey('cart-total'),
            style: text.displaySmall,
          ),
          const SizedBox(height: TinoSpace.s12),
          if (budget == null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showBudgetSheet(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: TinoSpace.s8),
                ),
                icon: const Icon(LucideIcons.wallet, size: 20),
                label: const Text('Definir orçamento'),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orçamento ${budget.format()}',
                    style: text.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar orçamento',
                  onPressed: () => showBudgetSheet(context),
                  icon: const Icon(LucideIcons.pencil, size: 20),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(TinoRadius.chip),
              child: LinearProgressIndicator(
                value: (total.cents / budget.cents).clamp(0, 1).toDouble(),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: TinoSpace.s12),
            _BudgetStatus(session),
          ],
        ],
      ),
    );
  }
}

class _BudgetStatus extends StatelessWidget {
  const _BudgetStatus(this.session);
  final ShoppingSession session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final budget = session.budget!;
    final total = session.cart.total;
    final left = (budget - total).format();
    final message = switch (session.status) {
      BudgetStatus.over => 'Passou ${(total - budget).format()} do orçamento.',
      BudgetStatus.near => 'Perto do limite. Faltam $left.',
      _ => 'Faltam $left do orçamento.',
    };
    if (session.status == BudgetStatus.within) {
      return Text(message, style: text.bodyMedium);
    }
    return Container(
      padding: const EdgeInsets.all(TinoSpace.s12),
      decoration: BoxDecoration(
        color: TinoTokens.info,
        borderRadius: BorderRadius.circular(TinoRadius.control),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 20,
            color: TinoTokens.textPrimary,
          ),
          const SizedBox(width: TinoSpace.s8),
          Expanded(child: Text(message, style: text.labelLarge)),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(TinoSpace.s24),
      decoration: BoxDecoration(
        color: TinoTokens.surfaceSoft,
        borderRadius: BorderRadius.circular(TinoRadius.card),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.shoppingCart, color: TinoTokens.textSecondary),
          const SizedBox(height: TinoSpace.s12),
          Text('Carrinho vazio', style: text.titleMedium),
          const SizedBox(height: TinoSpace.s4),
          Text(
            'Escaneie a etiqueta ou digite o primeiro produto '
            'para acompanhar o total.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
