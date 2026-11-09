import 'dart:async';

import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';

/// Bloco de uma cascata de entrada: sobe [offset] px → 0 e cresce
/// [fromScale] → 1 com [spring], e a opacidade entra com ease-out,
/// começando [index] × 60 ms depois. Movimento reduzido: só opacidade 150 ms.
///
/// Usado pelas folhas (M5, y 24) e pela boas-vindas (M10, y 32).
class TinoCascadeBlock extends StatefulWidget {
  const TinoCascadeBlock({
    super.key,
    required this.index,
    required this.reduced,
    required this.offset,
    required this.child,
    this.fromScale = 1,
    this.spring = TinoSprings.cartao,
  });

  final int index;
  final bool reduced;
  final double offset;
  final double fromScale;
  final SpringDescription spring;
  final Widget child;

  @override
  State<TinoCascadeBlock> createState() => _TinoCascadeBlockState();
}

class _TinoCascadeBlockState extends State<TinoCascadeBlock>
    with TickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 200);

  late final _rise = AnimationController.unbounded(vsync: this, value: 0);
  late final _fade = AnimationController(
    vsync: this,
    duration: widget.reduced ? TinoMotion.reducedFade : _fadeDuration,
  );
  late final _opacity = CurvedAnimation(
    parent: _fade,
    curve: TinoCurves.easeOut,
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(TinoMotion.stagger * widget.index, () {
      _fade.forward();
      if (widget.reduced) {
        _rise.value = 1;
      } else {
        _rise.animateWith(TinoMotion.spring(widget.spring, 0, 1, 0));
      }
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _opacity.dispose();
    _rise.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: AnimatedBuilder(
      animation: _rise,
      child: widget.child,
      builder: (context, child) {
        final t = _rise.value;
        Widget moved = Transform.translate(
          offset: Offset(0, widget.offset * (1 - t)),
          child: child,
        );
        if (widget.fromScale != 1) {
          moved = Transform.scale(
            scale: widget.fromScale + (1 - widget.fromScale) * t,
            child: moved,
          );
        }
        return moved;
      },
    ),
  );
}
