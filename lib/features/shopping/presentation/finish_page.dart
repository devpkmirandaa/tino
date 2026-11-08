import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_haptics.dart';
import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../lists/application/lists_providers.dart';
import '../application/shopping_controller.dart';
import '../domain/finished_purchase.dart';
import '../domain/money.dart';
import 'budget_seal_chip.dart';

/// Finalizar (design/telas/06-finalizar.html): fora das abas. Mostra quanto
/// vai pagar, o que ficou fora da lista e o mercado; "Concluir e guardar"
/// faz o M11 e vai para o Histórico.
class FinishPage extends ConsumerStatefulWidget {
  const FinishPage({super.key});

  @override
  ConsumerState<FinishPage> createState() => _FinishPageState();
}

enum _Phase { idle, saving, done }

class _FinishPageState extends ConsumerState<FinishPage> {
  // Retrato da compra ao entrar: concluir esvazia o carrinho antes de sair.
  late final ShoppingSession _session =
      ref.read(shoppingProvider).value ?? const ShoppingSession();
  final _place = TextEditingController();
  var _phase = _Phase.idle;
  var _failed = false;

  /// M4 ao entrar: o valor conta de zero até o total.
  var _shownCents = 0;

  /// M11: 400 ms depois do check, vai para o Histórico.
  static const _leaveDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shownCents = _session.cart.total.cents);
    });
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() {
      _phase = _Phase.saving;
      _failed = false;
    });
    try {
      await ref.read(shoppingProvider.notifier).finish(place: _place.text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _phase = _Phase.idle;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    // Concluir vibra sempre (não depende das chaves de leitura).
    TinoHaptics.success();
    setState(() => _phase = _Phase.done);
    await Future<void>.delayed(_leaveDelay);
    if (mounted) context.go('/historico');
  }

  void _back() => context.canPop() ? context.pop() : context.go('/');

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final total = _session.cart.total;
    final seal = budgetSeal(total, _session.budget);
    final listId = _session.listId;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TinoSpace.s16,
                  TinoSpace.s8,
                  TinoSpace.s16,
                  TinoSpace.s16,
                ),
                children: [
                  Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(-TinoSpace.s12, 0),
                        child: TinoIconButton(
                          key: const ValueKey('finish-back'),
                          icon: LucideIcons.chevronLeft,
                          semanticLabel: 'Voltar',
                          onPressed: _phase == _Phase.idle ? _back : null,
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          'Finalizar compra',
                          style: TinoType.tela.withColor(c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TinoSpace.s16),
                  _PayCard(cents: _shownCents, seal: seal),
                  if (listId != null) ...[
                    const SizedBox(height: TinoSpace.s16),
                    _LeftOut(listId),
                  ],
                  const SizedBox(height: TinoSpace.s24),
                  TinoInput(
                    key: const ValueKey('finish-place'),
                    label: 'Onde foi a compra? (opcional)',
                    controller: _place,
                    textInputAction: TextInputAction.done,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_failed) ...[
                    Text(
                      'Não deu pra finalizar. Tente de novo.',
                      key: const ValueKey('finish-failed'),
                      textAlign: TextAlign.center,
                      style: TinoType.label.withColor(c.textPrimary),
                    ),
                    const SizedBox(height: TinoSpace.s8),
                  ],
                  _ConcludeButton(
                    phase: _phase,
                    onPressed: _phase == _Phase.idle ? _finish : null,
                  ),
                  const SizedBox(height: TinoSpace.s4),
                  TinoButton.text(
                    key: const ValueKey('finish-continue'),
                    label: 'Continuar comprando',
                    expand: true,
                    onPressed: _phase == _Phase.idle ? _back : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Você vai pagar" + valor 40/48 (M4 ao entrar) + selo do orçamento.
class _PayCard extends StatelessWidget {
  const _PayCard({required this.cents, required this.seal});
  final int cents;
  final ({String text, bool over})? seal;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final seal = this.seal;
    return TinoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TinoSpace.s16,
        vertical: TinoSpace.s24,
      ),
      child: Column(
        children: [
          Text(
            'Você vai pagar',
            style: TinoType.secundario.withColor(c.textSecondary),
          ),
          const SizedBox(height: TinoSpace.s4),
          TinoMoneyCounter(
            key: const ValueKey('finish-total'),
            cents: cents,
            format: (v) => Money(v).format(),
            style: TinoType.total.withColor(c.textPrimary).money,
            accent: c.action,
          ),
          if (seal != null) ...[
            const SizedBox(height: TinoSpace.s12),
            BudgetSealChip(
              key: ValueKey(seal.over ? 'finish-seal-over' : 'finish-seal'),
              seal: seal,
            ),
          ],
        ],
      ),
    );
  }
}

/// Faixa `info` "Ficaram fora do carrinho": itens da lista ativa ainda não
/// marcados. Some se a lista foi toda pega.
class _LeftOut extends ConsumerWidget {
  const _LeftOut(this.listId);
  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final items = ref.watch(listItemsProvider(listId)).value ?? const [];
    final left = [
      for (final i in items)
        if (!i.done) i.name,
    ];
    if (left.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('finish-left-out'),
      padding: const EdgeInsets.all(TinoSpace.s16),
      decoration: BoxDecoration(
        color: c.info,
        borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ficaram fora do carrinho',
            style: TinoType.label.withColor(c.onInfo),
          ),
          const SizedBox(height: TinoSpace.s8),
          Wrap(
            spacing: TinoSpace.s8,
            runSpacing: TinoSpace.s8,
            children: [
              for (final name in left)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TinoSpace.s8,
                    vertical: TinoSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(TinoRadius.chip),
                  ),
                  child: Text(
                    name,
                    style: TinoType.secundario.withColor(c.textPrimary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TinoSpace.s8),
          Text(
            'Eles continuam na lista pra próxima vez.',
            style: TinoType.caption.withColor(c.onInfo),
          ),
        ],
      ),
    );
  }
}

/// "Concluir e guardar" (56, raio 16) com M11: o rótulo some em 120 ms e o
/// check entra com escala 0,3 → 1 (`confirmacao`).
class _ConcludeButton extends StatefulWidget {
  const _ConcludeButton({required this.phase, required this.onPressed});
  final _Phase phase;
  final VoidCallback? onPressed;

  @override
  State<_ConcludeButton> createState() => _ConcludeButtonState();
}

class _ConcludeButtonState extends State<_ConcludeButton>
    with SingleTickerProviderStateMixin {
  late final _check = AnimationController.unbounded(vsync: this, value: 0);

  static const _height = 56.0;
  static const _labelFade = Duration(milliseconds: 120);

  @override
  void didUpdateWidget(_ConcludeButton old) {
    super.didUpdateWidget(old);
    if (widget.phase == _Phase.done && old.phase != _Phase.done) {
      if (TinoMotion.reduced(context)) {
        _check.value = 1;
      } else {
        _check.animateWith(TinoMotion.spring(TinoSprings.confirmacao, 0.3, 1));
      }
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final done = widget.phase == _Phase.done;
    final busy = widget.phase != _Phase.idle;
    return Semantics(
      button: true,
      label: done ? 'Compra guardada' : 'Concluir e guardar',
      excludeSemantics: true,
      child: TinoPressable(
        key: const ValueKey('finish-conclude'),
        onPressed: widget.onPressed,
        excludeSemantics: true,
        builder: (context, pressed) => Container(
          height: _height,
          decoration: BoxDecoration(
            // Durante a gravação e no check, o botão fica cheio.
            color: pressed && !busy ? c.actionPressed : c.action,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: done ? 0 : 1,
                duration: _labelFade,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: TinoSize.iconCompact,
                      color: c.onAction,
                    ),
                    const SizedBox(width: TinoSpace.s8),
                    Text(
                      'Concluir e guardar',
                      style: TinoType.corpoForte.withColor(c.onAction),
                    ),
                  ],
                ),
              ),
              if (done)
                AnimatedBuilder(
                  animation: _check,
                  builder: (context, child) =>
                      Transform.scale(scale: _check.value, child: child),
                  child: Icon(
                    LucideIcons.check,
                    size: TinoSize.icon,
                    color: c.onAction,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
