import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';

/// M4 · Total mudando. O número conta do valor antigo pro novo em 450 ms
/// (ease-out), ganha um impulso de escala com a mola `confirmacao` (acumula
/// em leituras seguidas) e a cor vai pra [accent] e volta em 500 ms. Nunca
/// anima na primeira exibição. Movimento reduzido: troca direta.
class TinoMoneyCounter extends StatefulWidget {
  const TinoMoneyCounter({
    super.key,
    required this.cents,
    required this.format,
    required this.style,
    required this.accent,
  });

  /// Valor em centavos.
  final int cents;
  final String Function(int cents) format;

  /// Estilo de repouso; a cor dele é a de volta do impulso.
  final TextStyle style;
  final Color accent;

  /// Velocidade somada à escala a cada mudança (≈ 1,10 no pico).
  static const impulse = 3.5;

  @override
  State<TinoMoneyCounter> createState() => _TinoMoneyCounterState();
}

class _TinoMoneyCounterState extends State<TinoMoneyCounter>
    with TickerProviderStateMixin {
  late final _count = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );
  late final _scale = AnimationController.unbounded(vsync: this, value: 1);
  late int _from = widget.cents;

  int get _shown {
    final t = TinoCurves.easeOut.transform(_count.value);
    return (_from + (widget.cents - _from) * t).round();
  }

  @override
  void didUpdateWidget(TinoMoneyCounter old) {
    super.didUpdateWidget(old);
    if (old.cents == widget.cents) return;
    if (TinoMotion.reduced(context)) {
      _from = widget.cents;
      return;
    }
    // Parte do número que está na tela, se a contagem anterior não acabou.
    final t = TinoCurves.easeOut.transform(_count.value);
    _from = (_from + (old.cents - _from) * t).round();
    _count.forward(from: 0);
    _flash.forward(from: 0);
    _scale.animateWith(
      TinoMotion.spring(
        TinoSprings.confirmacao,
        _scale.value,
        1,
        _scale.velocity + TinoMoneyCounter.impulse,
      ),
    );
  }

  @override
  void dispose() {
    _count.dispose();
    _flash.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: widget.format(widget.cents),
    excludeSemantics: true,
    child: AnimatedBuilder(
      animation: Listenable.merge([_count, _flash, _scale]),
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Text(
          widget.format(_shown),
          maxLines: 1,
          style: widget.style.copyWith(
            color: Color.lerp(
              widget.accent,
              widget.style.color,
              TinoCurves.easeOut.transform(_flash.value),
            ),
          ),
        ),
      ),
    ),
  );
}
