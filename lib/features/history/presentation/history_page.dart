import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/domain/finished_purchase.dart';

/// "03/11/2026 · 17:02".
String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} · '
      '${two(d.hour)}:${two(d.minute)}';
}

String itemCount(int n) => n == 1 ? '1 item' : '$n itens';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final text = Theme.of(context).textTheme;
      final history = ref.watch(historyProvider);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          Semantics(
            header: true,
            child: Text('Histórico', style: text.headlineLarge),
          ),
          const SizedBox(height: TinoSpace.s16),
          switch (history) {
            AsyncData(:final value) when value.isEmpty => Container(
              padding: const EdgeInsets.all(TinoSpace.s24),
              decoration: BoxDecoration(
                color: TinoTokens.surfaceSoft,
                borderRadius: BorderRadius.circular(TinoRadius.card),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.history,
                    color: TinoTokens.textSecondary,
                  ),
                  const SizedBox(height: TinoSpace.s12),
                  Text('Nenhuma compra finalizada', style: text.titleMedium),
                  const SizedBox(height: TinoSpace.s4),
                  Text(
                    'Ao finalizar uma compra em Comprar, ela aparece aqui.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AsyncData(:final value) => ItemsCard(
              children: [for (final p in value) _PurchaseRow(p)],
            ),
            AsyncError() => Column(
              children: [
                const Text('Não deu pra abrir o histórico.'),
                const SizedBox(height: TinoSpace.s12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      );
    },
  );
}

/// Cartão com linhas separadas por divisórias.
class ItemsCard extends StatelessWidget {
  const ItemsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: TinoTokens.surface,
      border: Border.all(color: TinoTokens.border),
      borderRadius: BorderRadius.circular(TinoRadius.card),
    ),
    child: Column(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(indent: TinoSpace.s16),
          child,
        ],
      ],
    ),
  );
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow(this.purchase);
  final FinishedPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.go('/historico/${purchase.id}'),
      child: Padding(
        padding: const EdgeInsets.all(TinoSpace.s16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDateTime(purchase.finishedAt),
                    style: text.bodyLarge?.weight(FontWeight.w600),
                  ),
                  Text(
                    itemCount(purchase.cart.items.length),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Text(purchase.cart.total.format(), style: text.bodyLarge?.money),
            const SizedBox(width: TinoSpace.s8),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: TinoTokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
