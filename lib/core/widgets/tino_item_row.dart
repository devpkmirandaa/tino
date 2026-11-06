import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';
import '../theme/tino_theme.dart';
import 'tino_card.dart';
import 'tino_pressable.dart';

/// Linha de item: altura mín. 64, padding 12/16, nome 16/600, apoio 12/500
/// `text-secondary`, preço 16/700 tabular à direita. Com [onPressed],
/// pressionar M1 (0,96 + fundo `surface-soft`).
class TinoItemRow extends StatelessWidget {
  const TinoItemRow({
    super.key,
    required this.title,
    this.subtitle,
    this.price,
    this.leading,
    this.onPressed,
  });

  final String title;
  final String? subtitle;

  /// Já formatado (ex.: "R$ 7,98"). A formatação é regra do domínio.
  final String? price;
  final Widget? leading;
  final VoidCallback? onPressed;

  static const minHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    Widget row(bool pressed) => AnimatedContainer(
      duration: tinoSurfacePressDuration,
      curve: TinoCurves.easeOut,
      constraints: const BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: TinoSpace.s16,
        vertical: TinoSpace.s12,
      ),
      color: pressed ? c.surfaceSoft : c.surface,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: TinoSpace.s12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TinoType.corpoForte.withColor(c.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: TinoSpace.s4),
                  Text(
                    subtitle!,
                    style: TinoType.caption.withColor(c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (price != null) ...[
            const SizedBox(width: TinoSpace.s12),
            Text(
              price!,
              textAlign: TextAlign.right,
              style: TinoType.corpo.withColor(c.textPrimary).money,
            ),
          ],
        ],
      ),
    );
    if (onPressed == null) return Semantics(container: true, child: row(false));
    return TinoPressable(
      onPressed: onPressed,
      scale: TinoPressScale.surface,
      builder: (context, pressed) => row(pressed),
    );
  }
}
