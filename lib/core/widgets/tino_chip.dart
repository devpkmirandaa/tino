import 'package:flutter/widgets.dart';

import '../theme/tino_theme.dart';
import 'tino_pressable.dart';

/// Chip: 40 visíveis em pílula, área de toque 48, borda `border-strong`,
/// ícone 20 + rótulo 14/600. Pressionar M1.
class TinoChip extends StatelessWidget {
  const TinoChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final color = onPressed == null ? c.textSecondary : c.textPrimary;
    return TinoPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, _) => Padding(
        // Completa a área de toque de 48 sem mudar os 40 visíveis.
        padding: const EdgeInsets.symmetric(
          vertical: (TinoSize.touchTarget - _height) / 2,
        ),
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: TinoSpace.s12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(TinoRadius.pill),
            border: Border.all(
              color: c.borderStrong,
              width: TinoSize.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: TinoSize.iconCompact, color: color),
                const SizedBox(width: TinoSpace.s8),
              ],
              Text(label, style: TinoType.label.withColor(color)),
            ],
          ),
        ),
      ),
    );
  }
}
