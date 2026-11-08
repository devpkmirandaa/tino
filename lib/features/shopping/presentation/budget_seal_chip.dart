import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';

/// Selo do orçamento (Finalizar e Resumo da compra): "Sobraram R$ X" em
/// `surface-soft` com check `action`; "Passou R$ X" invertido, com alerta.
class BudgetSealChip extends StatelessWidget {
  const BudgetSealChip({
    super.key,
    required this.seal,
    this.icon = LucideIcons.check,
  });
  final ({String text, bool over}) seal;

  /// Ícone de quando sobrou (o Resumo usa o check em círculo).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final fg = seal.over ? c.canvas : c.action;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TinoSpace.s12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: seal.over ? c.textPrimary : c.surfaceSoft,
        borderRadius: BorderRadius.circular(TinoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            seal.over ? LucideIcons.triangleAlert : icon,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: TinoSpace.s4),
          Flexible(
            child: Text(
              seal.text,
              style: TinoType.caption
                  .withColor(fg)
                  .weight(FontWeight.w600)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }
}
