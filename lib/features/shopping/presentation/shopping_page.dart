import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../lists/presentation/linked_list_card.dart';
import '../../settings/data/settings_preferences.dart';
import '../application/shopping_controller.dart';
import '../domain/budget.dart';
import '../domain/cart.dart';
import '../application/camera_access.dart';
import 'budget_sheet.dart';
import 'camera_sheets.dart';
import 'cart_entrance.dart';
import 'cart_item_row.dart';
import 'cart_removal.dart';
import 'item_detail_sheet.dart';
import 'scanner_page.dart';
import 'scanner_route.dart';
import 'shopping_sheets.dart';
import 'type_price_sheet.dart';

/// Aba inicial (design/specs/telas.md · 02 Comprar vazio e 04 com itens).
class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final state = ref.watch(shoppingProvider);
    if (state.hasError && !state.hasValue) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TinoSpace.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Não deu pra abrir a compra salva.',
                style: TinoType.corpo.withColor(c.textPrimary),
              ),
              const SizedBox(height: TinoSpace.s12),
              TinoButton.outlined(
                label: 'Tentar de novo',
                onPressed: () => ref.invalidate(shoppingProvider),
              ),
            ],
          ),
        ),
      );
    }
    final loading = !state.hasValue;
    final session = state.value ?? const ShoppingSession();
    final items = session.cart.items;
    final listId = session.listId;
    final entering = ref.watch(cartEntranceProvider).playing;
    final leaving = ref.watch(cartRemovalProvider).leaving;

    final header = [
      Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Comprar',
                style: TinoType.tela.withColor(c.textPrimary),
              ),
            ),
          ),
          TinoIconButton(
            key: const ValueKey('open-settings'),
            icon: LucideIcons.settings2,
            semanticLabel: 'Ajustes',
            onPressed: () => context.push('/ajustes'),
          ),
        ],
      ),
      const SizedBox(height: TinoSpace.s16),
      _TotalCard(session),
      if (listId != null) ...[
        const SizedBox(height: TinoSpace.s16),
        ActiveListBand(listId),
      ],
    ];

    final scroll = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            TinoSpace.s16,
            TinoSpace.s16,
            TinoSpace.s16,
            TinoSpace.s16,
          ),
          sliver: SliverToBoxAdapter(
            child: _Width(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  if (items.isNotEmpty || leaving.isNotEmpty) ...[
                    const SizedBox(height: TinoSpace.s16),
                    TinoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, row) in _rows(
                            items,
                            leaving,
                          ).indexed) ...[
                            if (i > 0) const Divider(),
                            switch (row) {
                              (item: final item, leaving: true) => CartRowExit(
                                key: ValueKey('cart-exit-${item.id}'),
                                onDone: () => ref
                                    .read(cartRemovalProvider.notifier)
                                    .settle(item.id),
                                child: TinoItemRow(
                                  title: cartItemName(item),
                                  titleMuted: item.unnamed,
                                  subtitle: cartItemDetail(item),
                                  price: item.total.format(),
                                ),
                              ),
                              (item: final item, leaving: false) =>
                                CartRowEntrance(
                                  key: ValueKey('cart-row-${item.id}'),
                                  play: entering.contains(item.id),
                                  child: TinoItemRow(
                                    key: ValueKey('cart-item-$i'),
                                    title: cartItemName(item),
                                    titleMuted: item.unnamed,
                                    subtitle: cartItemDetail(item),
                                    price: item.total.format(),
                                    onPressed: () =>
                                        showItemDetailSheet(context, item),
                                  ),
                                ),
                            },
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: TinoSpace.s16),
                    TinoButton.outlined(
                      key: const ValueKey('finish'),
                      label: 'Finalizar compra',
                      accent: true,
                      expand: true,
                      onPressed: () => showFinishSheet(context),
                    ),
                    const SizedBox(height: TinoSpace.s8),
                    TinoButton.text(
                      key: const ValueKey('clear-cart'),
                      label: 'Limpar carrinho',
                      icon: LucideIcons.trash2,
                      onPressed: () => _confirmClear(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (items.isEmpty && leaving.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyCart()),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: scroll),
              // Aviso do M8 logo acima dos botões do rodapé.
              const Positioned(
                left: TinoSpace.s16,
                right: TinoSpace.s16,
                bottom: TinoSpace.s8,
                child: _Width(child: CartUndoToast()),
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
          child: _Width(
            child: items.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ScanButton(loading: loading),
                      const SizedBox(height: TinoSpace.s4),
                      TinoButton.text(
                        key: const ValueKey('add-product'),
                        label: 'Digitar preço',
                        icon: LucideIcons.keyboard,
                        onPressed: loading
                            ? null
                            : () => showTypePriceSheet(context),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _TypeSquareButton(
                        onPressed: loading
                            ? null
                            : () => showTypePriceSheet(context),
                      ),
                      const SizedBox(width: TinoSpace.s8),
                      Expanded(child: _ScanButton(loading: loading)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Linhas do carrinho, a mais nova no topo, com as que estão saindo (M8)
/// de volta no lugar que ocupavam até terminarem a animação.
List<({CartItem item, bool leaving})> _rows(
  List<CartItem> items,
  List<RemovedItem> leaving,
) {
  final rows = [for (final i in items.reversed) (item: i, leaving: false)];
  for (final l in leaving) {
    // Posição na ordem invertida de antes da remoção.
    final position = rows.length - l.index;
    rows.insert(position.clamp(0, rows.length), (item: l.item, leaving: true));
  }
  return rows;
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.loading});
  final bool loading;

  @override
  Widget build(BuildContext context) => TinoButton.primary(
    key: const ValueKey('scan'),
    label: 'Escanear preço',
    icon: LucideIcons.scanLine,
    size: TinoButtonSize.scan,
    expand: true,
    onPressed: loading ? null : () => _scan(context),
  );
}

/// Quadrado 64 "Digitar preço" ao lado do Escanear (04 · rodapé). Mesmas
/// medidas provisórias do botão de escanear.
class _TypeSquareButton extends StatelessWidget {
  const _TypeSquareButton({required this.onPressed});
  final VoidCallback? onPressed;

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final enabled = onPressed != null;
    return TinoPressable(
      key: const ValueKey('add-product'),
      onPressed: onPressed,
      semanticLabel: 'Digitar preço',
      excludeSemantics: true,
      builder: (context, _) => Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
          border: Border.all(
            color: enabled ? c.borderStrong : c.border,
            width: TinoSize.borderWidth,
          ),
        ),
        child: Icon(
          LucideIcons.keyboard,
          size: TinoSize.icon,
          color: enabled ? c.action : c.textSecondary,
        ),
      ),
    );
  }
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
        TinoButton.text(
          label: 'Cancelar',
          onPressed: () => Navigator.pop(context, false),
        ),
        TinoButton.primary(
          label: 'Limpar',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (ok == true) ref.read(shoppingProvider.notifier).clear();
}

/// Abre o scanner e leva a leitura (ou um pedido para digitar) ao painel.
/// O scanner cresce a partir do botão tocado ([context]) (M2).
Future<void> _scan(BuildContext context) async {
  if (context.findRenderObject() case final RenderBox box? when box.hasSize) {
    ScannerOrigin.rect = box.localToGlobal(Offset.zero) & box.size;
  }
  final container = ProviderScope.containerOf(context, listen: false);
  final access = container.read(cameraAccessProvider);
  // Câmera nunca pedida: folha 14 antes do sistema; negada: folha 15.
  switch (await access.step()) {
    case CameraStep.scan:
      break;
    case CameraStep.ask:
      if (!context.mounted) return;
      final choice = await showCameraAskSheet(context);
      if (!context.mounted) return;
      if (choice == CameraAskChoice.type) return showTypePriceSheet(context);
      if (choice != CameraAskChoice.allow) return;
      if (!await access.request()) {
        if (context.mounted) await _cameraDenied(context, access);
        return;
      }
    case CameraStep.denied:
      if (context.mounted) await _cameraDenied(context, access);
      return;
  }
  if (!context.mounted) return;
  final result = await context.push<ScanResult>('/escanear');
  if (!context.mounted) return;
  // Linhas que entraram pelo scanner fazem o M3c enquanto ele fecha.
  final entrance = container.read(cartEntranceProvider.notifier)..release();
  Timer(const Duration(seconds: 1), entrance.settle);
  switch (result) {
    case ScanRead(:final reading):
      await showTypePriceSheet(context, draft: reading);
    case ScanEdit(:final itemId):
      final items = container.read(shoppingProvider).value?.cart.items;
      final item = items?.where((i) => i.id == itemId).firstOrNull;
      if (item != null) await showItemDetailSheet(context, item);
    case ScanTypeInstead():
      await showTypePriceSheet(context);
    case ScanCameraDenied():
      await _cameraDenied(context, container.read(cameraAccessProvider));
    case null:
      break;
  }
}

/// Folha 15: digitar o preço ou abrir os ajustes do Tino no sistema.
Future<void> _cameraDenied(BuildContext context, CameraAccess access) async {
  if (!context.mounted) return;
  final choice = await showCameraDeniedSheet(context);
  switch (choice) {
    case CameraDeniedChoice.type:
      if (context.mounted) await showTypePriceSheet(context);
    case CameraDeniedChoice.settings:
      await access.openSettings();
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

class _TotalCard extends ConsumerWidget {
  const _TotalCard(this.session);
  final ShoppingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final total = session.cart.total;
    final budget = session.budget;
    final count = session.cart.items.length;
    final label = count == 0
        ? 'Total'
        : 'Total · ${count == 1 ? '1 item' : '$count itens'}';
    return TinoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TinoType.secundario.withColor(c.textSecondary)),
          const SizedBox(height: TinoSpace.s4),
          Text(
            total.format(),
            key: const ValueKey('cart-total'),
            style: TinoType.total.withColor(c.textPrimary).money,
          ),
          if (budget != null) ...[
            const SizedBox(height: TinoSpace.s12),
            _BudgetMeter(session),
          ],
          if (budget == null || session.listId == null) ...[
            const SizedBox(height: TinoSpace.s8),
            Wrap(
              spacing: TinoSpace.s8,
              children: [
                if (budget == null)
                  TinoChip(
                    key: const ValueKey('budget-chip'),
                    label: 'Orçamento',
                    icon: LucideIcons.wallet,
                    onPressed: () => showBudgetSheet(context),
                  ),
                if (session.listId == null)
                  TinoChip(
                    key: const ValueKey('use-list'),
                    label: 'Usar uma lista',
                    icon: LucideIcons.listChecks,
                    onPressed: () => chooseShoppingList(context, ref),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Orçamento no Comprar (telas/04, 04a, 04b): barra (M9), "Faltam R$ X" /
/// "de R$ Y" e o chip "Mudar". Perto do limite: faixa `info`, só com "Avisar
/// quando faltar pouco" ligado; passou: barra em `text-primary` e faixa
/// invertida, sempre. Estado sempre em texto, não só cor.
class _BudgetMeter extends ConsumerWidget {
  const _BudgetMeter(this.session);
  final ShoppingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final nearAlert = ref.watch(nearBudgetAlertProvider).value ?? true;
    final budget = session.budget!;
    final total = session.cart.total;
    final status = session.status;
    final over = status == BudgetStatus.over;
    final passed = (total - budget).format();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TinoProgressBar(
          key: const ValueKey('budget-meter'),
          value: total.cents / budget.cents,
          over: over,
          semanticLabel: 'Orçamento usado',
        ),
        const SizedBox(height: TinoSpace.s8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    over
                        ? 'Passou $passed'
                        : 'Faltam ${(budget - total).format()}',
                    key: const ValueKey('budget-left'),
                    style: TinoType.label.withColor(c.textPrimary).money,
                  ),
                  Text(
                    'de ${budget.format()}',
                    style: TinoType.caption
                        .withColor(c.textSecondary)
                        .copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TinoSpace.s12),
            Semantics(
              label: 'Mudar orçamento',
              child: TinoChip(
                key: const ValueKey('budget-change'),
                label: 'Mudar',
                icon: LucideIcons.pencil,
                accent: true,
                onPressed: () => showBudgetSheet(context),
              ),
            ),
          ],
        ),
        if (status == BudgetStatus.near && nearAlert) ...[
          const SizedBox(height: TinoSpace.s12),
          _BudgetBand(
            key: const ValueKey('budget-near'),
            icon: LucideIcons.circleAlert,
            title: 'Perto do limite do orçamento',
            detail: 'Você já usou ${budgetUsedPercent(total, budget)}%.',
            background: c.info,
            foreground: c.onInfo,
          ),
        ],
        if (over) ...[
          const SizedBox(height: TinoSpace.s12),
          _BudgetBand(
            key: const ValueKey('budget-over'),
            icon: LucideIcons.triangleAlert,
            title: 'Passou $passed do orçamento.',
            detail: 'Tire um item ou mude o valor.',
            background: c.textPrimary,
            foreground: c.canvas,
          ),
        ],
      ],
    );
  }
}

/// Faixa de estado do orçamento: raio 12, padding 12, ícone 20, título
/// 14/700 e apoio 12/500. Anunciada pelo leitor de tela ao aparecer.
class _BudgetBand extends StatelessWidget {
  const _BudgetBand({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: Container(
      padding: const EdgeInsets.all(TinoSpace.s12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TinoRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, size: TinoSize.iconCompact, color: foreground),
          const SizedBox(width: TinoSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TinoType.label
                      .withColor(foreground)
                      .weight(FontWeight.w700),
                ),
                Text(detail, style: TinoType.caption.withColor(foreground)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  static const _iconBox = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TinoSpace.s24,
        0,
        TinoSpace.s24,
        TinoSpace.s16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _iconBox,
            height: _iconBox,
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(TinoRadius.card),
            ),
            child: Icon(
              LucideIcons.shoppingCart,
              size: TinoSize.icon,
              color: c.action,
            ),
          ),
          const SizedBox(height: TinoSpace.s16),
          Text(
            'Carrinho vazio',
            textAlign: TextAlign.center,
            style: TinoType.subtitulo.withColor(c.textPrimary),
          ),
          const SizedBox(height: TinoSpace.s8),
          Text(
            'Aponte a câmera para a primeira etiqueta. O resto o Tino soma.',
            textAlign: TextAlign.center,
            style: TinoType.secundario.withColor(c.textSecondary),
          ),
        ],
      ),
    );
  }
}
