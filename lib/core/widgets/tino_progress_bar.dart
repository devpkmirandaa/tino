import 'package:flutter/widgets.dart';

import '../motion/tino_haptics.dart';
import '../motion/tino_springs.dart';
import '../theme/tino_theme.dart';

/// Barra de progresso (M9): pílula de 8 (6 em [compact]), trilho
/// `surface-soft`, preenchimento `action`.
///
/// A largura anima com a mola `cartao` quando [value] muda, nunca na
/// primeira montagem. Quando [over] passa a verdadeiro, treme uma vez
/// (x 0 → 6 → −6 → 0 com `toque`), dispara o háptico de aviso (se
/// [haptics]) e mostra [overLabel] ("Passou R$ X", formatado pela tela).
class TinoProgressBar extends StatefulWidget {
  const TinoProgressBar({
    super.key,
    required this.value,
    this.over = false,
    this.overLabel,
    this.compact = false,
    this.haptics = true,
    this.semanticLabel,
  });

  /// De 0 a 1.
  final double value;
  final bool over;
  final String? overLabel;
  final bool compact;
  final bool haptics;
  final String? semanticLabel;

  /// Deslocamentos do tremor, em px.
  static const shake = [6.0, -6.0, 0.0];

  @override
  State<TinoProgressBar> createState() => _TinoProgressBarState();
}

class _TinoProgressBarState extends State<TinoProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController.unbounded(
    vsync: this,
    value: _clamped(widget.value),
  );
  late final AnimationController _shake = AnimationController.unbounded(
    vsync: this,
  );

  static double _clamped(double v) => v.clamp(0.0, 1.0);

  @override
  void didUpdateWidget(TinoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduced = TinoMotion.reduced(context);
    final target = _clamped(widget.value);
    if (target != _clamped(oldWidget.value)) {
      if (reduced) {
        _fill.value = target;
      } else {
        _fill.animateWith(
          TinoMotion.spring(
            TinoSprings.cartao,
            _fill.value,
            target,
            _fill.velocity,
          ),
        );
      }
    }
    if (widget.over && !oldWidget.over) {
      if (widget.haptics) TinoHaptics.warning();
      if (!reduced) _runShake();
    }
  }

  Future<void> _runShake() async {
    try {
      for (final x in TinoProgressBar.shake) {
        await _shake
            .animateWith(
              TinoMotion.spring(TinoSprings.toque, _shake.value, x, 0),
            )
            .orCancel;
      }
    } on TickerCanceled {
      // Desmontado no meio do tremor.
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final height = widget.compact ? 6.0 : TinoSpace.s8;
    final label = widget.overLabel;
    final bar = AnimatedBuilder(
      animation: Listenable.merge([_fill, _shake]),
      builder: (context, _) => Transform.translate(
        offset: Offset(_shake.value, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TinoRadius.pill),
          child: Container(
            height: height,
            color: c.surfaceSoft,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              key: const ValueKey('tino-progress-fill'),
              // A mola passa um pouco do ponto; o trilho recorta.
              widthFactor: _fill.value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.action,
                  borderRadius: BorderRadius.circular(TinoRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      value: '${(_clamped(widget.value) * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(child: bar),
          if (widget.over && label != null) ...[
            const SizedBox(height: TinoSpace.s8),
            Text(label, style: TinoType.label.withColor(c.textPrimary)),
          ],
        ],
      ),
    );
  }
}
