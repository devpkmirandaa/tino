import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../application/shopping_controller.dart';
import '../domain/cart.dart';

/// Item tirado do carrinho e a posição que ele ocupava, para desfazer.
typedef RemovedItem = ({CartItem item, int index});

/// M8 no Comprar: [leaving] são as linhas que ainda fazem a saída;
/// [undo] é o último item tirado, com o aviso "Item tirado. Desfazer".
typedef CartRemovalState = ({List<RemovedItem> leaving, RemovedItem? undo});

final cartRemovalProvider = NotifierProvider<CartRemoval, CartRemovalState>(
  CartRemoval.new,
);

class CartRemoval extends Notifier<CartRemovalState> {
  /// Quanto tempo o aviso fica na tela.
  static const undoWindow = Duration(seconds: 4);

  Timer? _timer;

  @override
  CartRemovalState build() {
    ref.onDispose(() => _timer?.cancel());
    return (leaving: const [], undo: null);
  }

  /// Tira o item do carrinho na hora (o total já muda) e abre o desfazer.
  void remove(String id) {
    final items = ref.read(shoppingProvider).value?.cart.items ?? const [];
    final index = items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final removed = (item: items[index], index: index);
    ref.read(shoppingProvider.notifier).remove(id);
    state = (leaving: [...state.leaving, removed], undo: removed);
    _timer?.cancel();
    _timer = Timer(undoWindow, dismiss);
  }

  /// Põe o item de volta onde estava.
  void undo() {
    final removed = state.undo;
    if (removed == null) return;
    _timer?.cancel();
    final notifier = ref.read(shoppingProvider.notifier);
    final cart = ref.read(shoppingProvider).value?.cart ?? const Cart();
    notifier.setCart(cart.restore(removed.item, removed.index));
    state = (
      leaving: [
        for (final l in state.leaving)
          if (l.item.id != removed.item.id) l,
      ],
      undo: null,
    );
  }

  void dismiss() {
    _timer?.cancel();
    state = (leaving: state.leaving, undo: null);
  }

  /// A linha terminou a saída.
  void settle(String id) => state = (
    leaving: [
      for (final l in state.leaving)
        if (l.item.id != id) l,
    ],
    undo: state.undo,
  );
}

/// M8 · linha saindo: x 0 → −80 e opacidade → 0, depois a altura fecha com
/// `cartao`. Movimento reduzido: só opacidade, 150 ms.
class CartRowExit extends StatefulWidget {
  const CartRowExit({super.key, required this.onDone, required this.child});
  final VoidCallback onDone;
  final Widget child;

  @override
  State<CartRowExit> createState() => _CartRowExitState();
}

class _CartRowExitState extends State<CartRowExit>
    with TickerProviderStateMixin {
  late final _slide = AnimationController.unbounded(vsync: this);
  late final _height = AnimationController.unbounded(vsync: this, value: 1);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  Future<void> _run() async {
    if (TinoMotion.reduced(context)) {
      await _slide.animateTo(1, duration: TinoMotion.reducedFade);
      _height.value = 0;
    } else {
      await _slide.animateWith(TinoMotion.spring(TinoSprings.cartao, 0, 1));
      await _height.animateWith(TinoMotion.spring(TinoSprings.cartao, 1, 0));
    }
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _slide.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = TinoMotion.reduced(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_slide, _height]),
            child: widget.child,
            builder: (context, child) {
              final p = _slide.value.clamp(0.0, 1.0);
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _height.value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: 1 - p,
                    child: Transform.translate(
                      offset: Offset(reduced ? 0 : -80 * _slide.value, 0),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Aviso "Item tirado. Desfazer" (M8): sobe de baixo (y 80 → 0,
/// `confirmacao`). Usa as cores do tema oposto para destacar do fundo.
class CartUndoToast extends ConsumerStatefulWidget {
  const CartUndoToast({super.key});

  @override
  ConsumerState<CartUndoToast> createState() => _CartUndoToastState();
}

class _CartUndoToastState extends ConsumerState<CartUndoToast>
    with SingleTickerProviderStateMixin {
  late final _y = AnimationController.unbounded(vsync: this, value: 0);
  RemovedItem? _shown;

  @override
  void dispose() {
    _y.dispose();
    super.dispose();
  }

  void _sync(RemovedItem? undo) {
    if (undo == null) {
      if (_shown == null) return;
      final reduced = TinoMotion.reduced(context);
      final hide = reduced
          ? _y.animateTo(0, duration: TinoMotion.reducedFade)
          : _y.animateWith(
              TinoMotion.spring(TinoSprings.confirmacao, _y.value, 0),
            );
      hide.whenComplete(() {
        if (mounted && ref.read(cartRemovalProvider).undo == null) {
          setState(() => _shown = null);
        }
      });
      return;
    }
    setState(() => _shown = undo);
    if (TinoMotion.reduced(context)) {
      _y.animateTo(1, duration: TinoMotion.reducedFade);
    } else {
      _y.animateWith(TinoMotion.spring(TinoSprings.confirmacao, _y.value, 1));
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      '${undo.item.name} tirado do carrinho.',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartRemovalProvider.select((s) => s.undo), (_, next) {
      _sync(next);
    });
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    final reduced = TinoMotion.reduced(context);
    final inverse = TinoColorScheme.of(
      context.tino.brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
    );
    return AnimatedBuilder(
      animation: _y,
      builder: (context, child) => reduced
          ? Opacity(opacity: _y.value.clamp(0.0, 1.0), child: child)
          : Transform.translate(
              offset: Offset(0, 80 * (1 - _y.value)),
              child: Opacity(opacity: _y.value.clamp(0.0, 1.0), child: child),
            ),
      child: Container(
        key: const ValueKey('cart-undo-toast'),
        padding: const EdgeInsets.only(
          left: TinoSpace.s16,
          right: TinoSpace.s4,
        ),
        decoration: BoxDecoration(
          color: inverse.surface,
          borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
          border: Border.all(
            color: inverse.border,
            width: TinoSize.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Item tirado.',
                style: TinoType.secundario.withColor(inverse.textPrimary),
              ),
            ),
            Theme(
              data: buildTinoTheme(inverse.brightness),
              child: TinoButton.text(
                key: const ValueKey('cart-undo'),
                label: 'Desfazer',
                onPressed: ref.read(cartRemovalProvider.notifier).undo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
