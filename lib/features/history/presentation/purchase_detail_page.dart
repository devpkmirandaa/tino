import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/presentation/cart_item_row.dart';
import 'history_page.dart';

/// Detalhe somente leitura de uma compra finalizada.
class PurchaseDetailPage extends ConsumerWidget {
  const PurchaseDetailPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final history = ref.watch(historyProvider);
    final purchase = history.value?.where((p) => p.id == id).firstOrNull;
    final budget = purchase?.budget;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Voltar ao Histórico',
            onPressed: () => context.go('/historico'),
            icon: const Icon(LucideIcons.arrowLeft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: switch (purchase) {
            null when history.isLoading => const Center(
              child: CircularProgressIndicator(),
            ),
            null => const Text('Compra não encontrada.'),
            final p => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    formatDateTime(p.finishedAt),
                    style: text.headlineLarge,
                  ),
                ),
                const SizedBox(height: TinoSpace.s16),
                Text('Total', style: text.bodyMedium),
                Text(p.cart.total.format(), style: text.displaySmall),
                if (budget != null)
                  Text(
                    p.cart.total.cents > budget.cents
                        ? 'Passou ${(p.cart.total - budget).format()} do '
                              'orçamento de ${budget.format()}.'
                        : 'Dentro do orçamento de ${budget.format()}.',
                    style: text.bodyMedium,
                  ),
                const SizedBox(height: TinoSpace.s24),
                Text(itemCount(p.cart.items.length), style: text.titleLarge),
                const SizedBox(height: TinoSpace.s12),
                ItemsCard(
                  children: [
                    for (final item in p.cart.items) CartItemRow(item),
                  ],
                ),
              ],
            ),
          },
        ),
      ],
    );
  }
}
