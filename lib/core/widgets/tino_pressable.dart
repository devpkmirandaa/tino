import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';

/// Escalas do M1 (design/motion/motion.md).
abstract final class TinoPressScale {
  /// Botões, chips e controles.
  static const button = 0.94;

  /// Cartões e linhas tocáveis.
  static const surface = 0.96;
}

typedef TinoPressedBuilder = Widget Function(
  BuildContext context,
  bool pressed,
);

/// M1 · Pressionar. Afunda até [scale] com a mola `toque` e volta passando
/// um pouco de 1. A mola parte do valor e da velocidade atuais, então pode
/// ser interrompida. Se o dedo sai, cancela e volta. Com movimento reduzido,
/// não escala: só o [builder] recebe `pressed` pra trocar a cor.
class TinoPressable extends StatefulWidget {
  const TinoPressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.scale = TinoPressScale.button,
    this.semanticLabel,
    this.selected,
    this.excludeSemantics = false,
  });

  final VoidCallback? onPressed;
  final TinoPressedBuilder builder;
  final double scale;
  final String? semanticLabel;
  final bool? selected;
  final bool excludeSemantics;

  @override
  State<TinoPressable> createState() => _TinoPressableState();
}

class _TinoPressableState extends State<TinoPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _pressed = false;
  bool _disposed = false;

  /// Em cache: o cancelamento do gesto pode chegar com o elemento já
  /// desativado, quando não dá mais pra consultar o MediaQuery.
  bool _reduced = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = TinoMotion.reduced(context);
  }

  void _setPressed(bool pressed) {
    if (_disposed || _pressed == pressed) return;
    setState(() => _pressed = pressed);
    if (_reduced) {
      _scale.value = 1;
      return;
    }
    _scale.animateWith(
      TinoMotion.spring(
        TinoSprings.toque,
        _scale.value,
        pressed ? widget.scale : 1,
        _scale.velocity,
      ),
    );
  }

  @override
  void didUpdateWidget(TinoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _pressed) _setPressed(false);
  }

  @override
  void dispose() {
    _disposed = true;
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeSemantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) =>
                Transform.scale(scale: _scale.value, child: child),
            child: widget.builder(context, _pressed),
          ),
        ),
      ),
    );
  }
}
