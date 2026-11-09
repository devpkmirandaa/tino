import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_cascade_block.dart';

/// Ilustração funcional da boas-vindas (design/telas/01): cantos do visor,
/// etiqueta "Molho de tomate R$ 3,00" e selo "No carrinho". Decorativa: o
/// leitor de tela pula. O selo entra por último no M10 ([sealIndex]).
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({
    super.key,
    required this.sealIndex,
    required this.reduced,
  });

  final int sealIndex;
  final bool reduced;

  static const _height = 248.0;
  static const _viewfinder = Size(200, 136);
  static const _tagWidth = 160.0;

  /// Preço da etiqueta como na tela 01 (28/36/700). Fora da escala do
  /// manual; só nesta ilustração.
  static const _tagPrice = TinoTypeStyle(28, 36, FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return ExcludeSemantics(
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: c.surfaceSoft,
          borderRadius: BorderRadius.circular(TinoRadius.panel),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.fromSize(
              size: _viewfinder,
              child: CustomPaint(
                painter: _CornersPainter(c.action),
                child: Center(
                  child: Container(
                    width: _tagWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TinoSpace.s16,
                      vertical: TinoSpace.s12,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(TinoRadius.control),
                      border: Border.all(
                        color: c.border,
                        width: TinoSize.borderWidth,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Molho de tomate',
                          style: TinoType.caption.withColor(c.textSecondary),
                        ),
                        const SizedBox(height: TinoSpace.s4),
                        Text(
                          'R\$ 3,00',
                          style: _tagPrice.withColor(c.textPrimary).money,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: TinoSpace.s16,
              child: TinoCascadeBlock(
                index: sealIndex,
                reduced: reduced,
                offset: 0,
                fromScale: 0.5,
                spring: TinoSprings.confirmacao,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TinoSpace.s12,
                    vertical: TinoSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: c.action,
                    borderRadius: BorderRadius.circular(TinoRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check, size: 14, color: c.onAction),
                      const SizedBox(width: TinoSpace.s4),
                      Text(
                        'No carrinho',
                        style: TinoType.caption
                            .withColor(c.onAction)
                            .weight(FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quatro cantos do visor, traço 3 e raio 12 (desenho da tela 01).
class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);

  final Color color;

  static const _stroke = 3.0;
  static const _arm = 24.0;
  static const _radius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    const i = _stroke / 2;
    final r = Radius.circular(_radius);
    final w = size.width;
    final h = size.height;
    final path = Path()
      // Superior esquerdo.
      ..moveTo(i, i + _arm)
      ..lineTo(i, i + _radius)
      ..arcToPoint(Offset(i + _radius, i), radius: r)
      ..lineTo(i + _arm, i)
      // Superior direito.
      ..moveTo(w - i - _arm, i)
      ..lineTo(w - i - _radius, i)
      ..arcToPoint(Offset(w - i, i + _radius), radius: r)
      ..lineTo(w - i, i + _arm)
      // Inferior direito.
      ..moveTo(w - i, h - i - _arm)
      ..lineTo(w - i, h - i - _radius)
      ..arcToPoint(Offset(w - i - _radius, h - i), radius: r)
      ..lineTo(w - i - _arm, h - i)
      // Inferior esquerdo.
      ..moveTo(i + _arm, h - i)
      ..lineTo(i + _radius, h - i)
      ..arcToPoint(Offset(i, h - i - _radius), radius: r)
      ..lineTo(i, h - i - _arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}
