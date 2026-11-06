import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';

/// Linhas que entraram pelo scanner: [pending] enquanto o scanner está
/// aberto, [playing] quando ele fecha e o Comprar aparece (M3c).
typedef CartEntranceState = ({Set<String> pending, Set<String> playing});

final cartEntranceProvider = NotifierProvider<CartEntrance, CartEntranceState>(
  CartEntrance.new,
);

class CartEntrance extends Notifier<CartEntranceState> {
  @override
  CartEntranceState build() => (pending: const {}, playing: const {});

  void mark(String id) =>
      state = (pending: {...state.pending, id}, playing: state.playing);

  void unmark(String id) =>
      state = (pending: {...state.pending}..remove(id), playing: state.playing);

  /// Scanner fechou: as linhas marcadas fazem a entrada agora.
  void release() => state = (pending: const {}, playing: state.pending);

  /// Entrada já tocou: linhas recriadas depois não repetem.
  void settle() => state = (pending: state.pending, playing: const {});
}

/// M3c · linha nova no topo do carrinho: altura 0 → natural com `cartao`,
/// conteúdo y −20 → 0, escala 0,96 → 1 e opacidade; o fundo começa em
/// `surface-soft` e esmaece pra `surface` em 900 ms. Toca quando [play]
/// passa a verdadeiro. Movimento reduzido: só opacidade, 150 ms.
class CartRowEntrance extends StatefulWidget {
  const CartRowEntrance({super.key, required this.play, required this.child});
  final bool play;
  final Widget child;

  @override
  State<CartRowEntrance> createState() => _CartRowEntranceState();
}

class _CartRowEntranceState extends State<CartRowEntrance>
    with TickerProviderStateMixin {
  late final _rise = AnimationController.unbounded(vsync: this, value: 1);
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  late final _tint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.play) _start();
  }

  @override
  void didUpdateWidget(CartRowEntrance old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _start();
  }

  void _start() {
    _started = true;
    if (TinoMotion.reduced(context)) {
      _fade
        ..duration = TinoMotion.reducedFade
        ..forward(from: 0);
      return;
    }
    _fade.forward(from: 0);
    _tint.forward(from: 0);
    _rise.animateWith(TinoMotion.spring(TinoSprings.cartao, 0, 1));
  }

  @override
  void dispose() {
    _rise.dispose();
    _fade.dispose();
    _tint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rise, _fade, _tint]),
        child: widget.child,
        builder: (context, child) {
          final p = _rise.value;
          return ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: p.clamp(0.0, 1.5),
              child: ColoredBox(
                color: Color.lerp(
                  c.surfaceSoft,
                  c.surface,
                  TinoCurves.easeOut.transform(_tint.value),
                )!,
                child: Opacity(
                  opacity: TinoCurves.easeOut.transform(_fade.value),
                  child: Transform.translate(
                    offset: Offset(0, -20 * (1 - p)),
                    child: Transform.scale(
                      scale: 0.96 + 0.04 * p,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
