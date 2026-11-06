import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';
import '../theme/tino_theme.dart';
import 'tino_pressable.dart';

typedef TinoSegment<T> = ({T value, String label});

/// Controle segmentado (M6): trilho 48 `surface-soft` raio 12, segmento 40
/// raio 8. O fundo `surface` desliza com a mola `selecao` e estica até +12%
/// na direção do movimento no meio do caminho. Texto troca de cor em 150 ms.
class TinoSegmented<T> extends StatefulWidget {
  const TinoSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  }) : assert(segments.length >= 2);

  final List<TinoSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  /// Quanto o fundo estica no meio do caminho.
  static const stretch = 0.12;

  @override
  State<TinoSegmented<T>> createState() => _TinoSegmentedState<T>();
}

class _TinoSegmentedState<T> extends State<TinoSegmented<T>>
    with SingleTickerProviderStateMixin {
  static const _inset = (TinoSize.touchTarget - 40) / 2;

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );
  late double _from = _position.value;
  late double _to = _position.value;

  int get _index =>
      widget.segments.indexWhere((s) => s.value == widget.selected);

  @override
  void didUpdateWidget(TinoSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _index.toDouble();
    if (target == _to) return;
    _from = _position.value;
    _to = target;
    if (TinoMotion.reduced(context)) {
      _position.value = target;
      return;
    }
    _position.animateWith(
      TinoMotion.spring(
        TinoSprings.selecao,
        _position.value,
        target,
        _position.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final count = widget.segments.length;
    return Container(
      height: TinoSize.touchTarget,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(TinoRadius.control),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final track = constraints.maxWidth;
          final segment = track / count;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _position,
                builder: (context, _) {
                  final p = _position.value;
                  final distance = _to - _from;
                  final t = distance == 0
                      ? 1.0
                      : ((p - _from) / distance).clamp(0.0, 1.0);
                  final extra =
                      segment * TinoSegmented.stretch * math.sin(math.pi * t);
                  final width = segment + extra;
                  final left = (p * segment - (distance < 0 ? extra : 0)).clamp(
                    0.0,
                    track - width,
                  );
                  return Positioned(
                    key: const ValueKey('tino-segmented-indicator'),
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(TinoRadius.chip),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (final s in widget.segments)
                    Expanded(child: _segment(context, s)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(BuildContext context, TinoSegment<T> s) {
    final c = context.tino;
    final selected = s.value == widget.selected;
    final onChanged = widget.onChanged;
    return TinoPressable(
      onPressed: onChanged == null
          ? null
          : () {
              if (!selected) onChanged(s.value);
            },
      selected: selected,
      semanticLabel: s.label,
      excludeSemantics: true,
      builder: (context, _) => Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          curve: TinoCurves.easeOut,
          style: TinoType.label.withColor(
            selected ? c.textPrimary : c.textSecondary,
          ),
          child: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
