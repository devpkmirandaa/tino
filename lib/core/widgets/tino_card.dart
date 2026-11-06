import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';
import '../theme/tino_theme.dart';
import 'tino_pressable.dart';

/// Fundo que vai pra `surface-soft` ao pressionar cartões e linhas (M1).
const tinoSurfacePressDuration = Duration(milliseconds: 120);

/// Cartão: raio 20 (ou 16 compacto), padding 16, fundo `surface`, borda 1
/// `border`, sem sombra. Com [onPressed], pressionar M1 (0,96 + fundo
/// `surface-soft`).
class TinoCard extends StatelessWidget {
  const TinoCard({
    super.key,
    required this.child,
    this.onPressed,
    this.compact = false,
    this.padding = const EdgeInsets.all(TinoSpace.s16),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool compact;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    Widget surface(bool pressed) => AnimatedContainer(
      duration: tinoSurfacePressDuration,
      curve: TinoCurves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: pressed ? c.surfaceSoft : c.surface,
        borderRadius: BorderRadius.circular(
          compact ? TinoRadius.cardCompact : TinoRadius.card,
        ),
        border: Border.all(color: c.border, width: TinoSize.borderWidth),
      ),
      child: child,
    );
    if (onPressed == null) return surface(false);
    return TinoPressable(
      onPressed: onPressed,
      scale: TinoPressScale.surface,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => surface(pressed),
    );
  }
}
