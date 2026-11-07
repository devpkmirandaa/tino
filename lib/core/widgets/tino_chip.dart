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
    this.selected = false,
    this.accent = false,
  });

  /// Ícone e rótulo em `action` (ex.: "Mudar" do orçamento no Comprar).
  final bool accent;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Escolhido (ex.: atalho de valor): borda 2 `action`, mesmas medidas.
  final bool selected;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final color = onPressed == null
        ? c.textSecondary
        : accent
        ? c.action
        : c.textPrimary;
    return TinoPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      excludeSemantics: true,
      builder: (context, _) => Padding(
        // Completa a área de toque de 48 sem mudar os 40 visíveis.
        padding: const EdgeInsets.symmetric(
          vertical: (TinoSize.touchTarget - _height) / 2,
        ),
        child: Container(
          height: _height,
          // Borda de 2 tira 1 px do respiro: o chip não muda de largura.
          padding: EdgeInsets.symmetric(
            horizontal: TinoSpace.s12 - (selected ? 1 : 0),
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(TinoRadius.pill),
            border: Border.all(
              color: selected ? c.action : c.borderStrong,
              width: selected ? 2 : TinoSize.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: TinoSize.iconCompact, color: color),
                const SizedBox(width: TinoSpace.s8),
              ],
              // Último recurso: quem quebra linha é o Wrap de fora; o rótulo
              // só encurta se nem sozinho na linha o chip couber.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TinoType.label.withColor(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
