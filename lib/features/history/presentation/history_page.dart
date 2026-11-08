import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/domain/finished_purchase.dart';
import '../../shopping/presentation/cart_entrance.dart';
import '../domain/history_summary.dart';

/// Histórico (design/telas/09): mês atual × anterior e as compras por mês.
/// A compra recém-concluída entra no topo com M3c.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  Timer? _settle;

  /// Depois da entrada, a linha recriada não repete o M3c.
  static const _settleAfter = Duration(milliseconds: 1500);

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final history = ref.watch(historyProvider);
    final fresh = ref.watch(freshPurchaseProvider);
    final purchases = history.value;
    // Só conta depois que a compra nova já está na lista.
    if (fresh != null &&
        _settle == null &&
        (purchases?.any((p) => p.id == fresh) ?? false)) {
      _settle = Timer(_settleAfter, () {
        _settle = null;
        ref.read(freshPurchaseProvider.notifier).set(null);
      });
    }
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TinoSpace.s16,
        TinoSpace.s16,
        TinoSpace.s16,
        TinoSpace.s24,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Histórico',
            style: TinoType.tela.withColor(c.textPrimary),
          ),
        ),
        const SizedBox(height: TinoSpace.s16),
        switch ((purchases, history)) {
          (final value?, _) when value.isEmpty => const _Empty(),
          (final value?, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthsCard(value, now: now),
              for (final group in groupByMonth(value, now)) ...[
                const SizedBox(height: TinoSpace.s16),
                _MonthGroup(group, now: now, fresh: fresh),
              ],
            ],
          ),
          (null, AsyncError()) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Não deu pra abrir o histórico.',
                style: TinoType.corpo.withColor(c.textPrimary),
              ),
              const SizedBox(height: TinoSpace.s12),
              TinoButton.outlined(
                label: 'Tentar de novo',
                onPressed: () => ref.invalidate(historyProvider),
              ),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// Mês atual × anterior: nome 14/500, valor 24/700 tabular, "N compras".
class _MonthsCard extends StatelessWidget {
  const _MonthsCard(this.purchases, {required this.now});
  final List<FinishedPurchase> purchases;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final (:current, :previous) = monthComparison(purchases, now);
    Widget month(MonthTotal m) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthName(m.month),
          style: TinoType.secundario.withColor(c.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            m.total.format(),
            style: TinoType.tela.withColor(c.textPrimary).money,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          purchaseCount(m.count),
          style: TinoType.caption.withColor(c.textSecondary),
        ),
      ],
    );
    return TinoCard(
      key: const ValueKey('history-months'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: month(current)),
            const SizedBox(width: TinoSpace.s12),
            VerticalDivider(
              width: TinoSize.borderWidth,
              thickness: TinoSize.borderWidth,
              color: c.border,
            ),
            const SizedBox(width: TinoSpace.s12),
            Expanded(child: month(previous)),
          ],
        ),
      ),
    );
  }
}

/// Rótulo do mês 12/600 + cartão raio 16 com as compras.
class _MonthGroup extends StatelessWidget {
  const _MonthGroup(this.group, {required this.now, required this.fresh});
  final MonthGroup group;
  final DateTime now;
  final int? fresh;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            group.label,
            style: TinoType.caption
                .withColor(c.textSecondary)
                .weight(FontWeight.w600),
          ),
        ),
        const SizedBox(height: TinoSpace.s8),
        TinoCard(
          compact: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, p) in group.purchases.indexed) ...[
                if (i > 0)
                  Divider(
                    height: TinoSize.borderWidth,
                    thickness: TinoSize.borderWidth,
                    color: c.border,
                  ),
                CartRowEntrance(
                  key: ValueKey('history-row-${p.id}'),
                  play: p.id == fresh,
                  child: _PurchaseRow(p, now: now),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Linha de 64: data 16/600, apoio 12/500, valor 16/700 tabular e seta.
class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow(this.purchase, {required this.now});
  final FinishedPurchase purchase;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final day = purchaseDay(purchase.finishedAt, now);
    final line = purchaseLine(purchase);
    final total = purchase.cart.total.format();
    return TinoPressable(
      key: ValueKey('history-purchase-${purchase.id}'),
      scale: TinoPressScale.surface,
      semanticLabel: '$day, $line, $total',
      excludeSemantics: true,
      onPressed: () => context.go('/historico/${purchase.id}'),
      builder: (context, pressed) => AnimatedContainer(
        duration: tinoSurfacePressDuration,
        curve: TinoCurves.easeOut,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: TinoSpace.s16,
          vertical: TinoSpace.s12,
        ),
        color: pressed ? c.surfaceSoft : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: TinoType.corpoForte.withColor(c.textPrimary),
                  ),
                  Text(
                    line,
                    style: TinoType.caption.withColor(c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TinoSpace.s12),
            Text(total, style: TinoType.corpo.withColor(c.textPrimary).money),
            const SizedBox(width: TinoSpace.s12),
            Icon(
              LucideIcons.chevronRight,
              size: TinoSize.iconCompact,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  static const _iconBox = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TinoSpace.s32),
      child: Column(
        children: [
          Container(
            width: _iconBox,
            height: _iconBox,
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(TinoRadius.card),
            ),
            child: Icon(
              LucideIcons.history,
              size: TinoSize.icon,
              color: c.action,
            ),
          ),
          const SizedBox(height: TinoSpace.s16),
          Text(
            'Nenhuma compra guardada',
            style: TinoType.subtitulo.withColor(c.textPrimary),
          ),
          const SizedBox(height: TinoSpace.s8),
          Text(
            'Ao concluir uma compra no Comprar, ela aparece aqui.',
            textAlign: TextAlign.center,
            style: TinoType.secundario.withColor(c.textSecondary),
          ),
        ],
      ),
    );
  }
}
