import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../domain/shopping_list.dart';

/// Cartão de lista (design/telas/07): nome 18/600, "N itens · contexto" e,
/// na lista em uso, barra de 6 + "2 de 6 no carrinho" (M9). Usado em Listas
/// e no seletor "Usar uma lista" do Comprar.
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.list,
    required this.inUse,
    required this.now,
    required this.onPressed,
  });

  final ShoppingListInfo list;
  final bool inUse;
  final DateTime now;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final summary = listSummary(list, inUse: inUse, now: now);
    final progress = inUse && list.itemCount > 0;
    final count = '${list.doneCount} de ${list.itemCount} no carrinho';
    return TinoCard(
      onPressed: onPressed,
      semanticLabel: '${list.name}. $summary${progress ? '. $count' : ''}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: TinoType.subtitulo.withColor(c.textPrimary),
                      ),
                      Text(
                        summary,
                        style: TinoType.secundario.withColor(c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TinoSpace.s12),
                Icon(
                  LucideIcons.chevronRight,
                  size: TinoSize.iconCompact,
                  color: c.textSecondary,
                ),
              ],
            ),
            if (progress) ...[
              const SizedBox(height: TinoSpace.s12),
              TinoProgressBar(
                value: list.doneCount / list.itemCount,
                compact: true,
                haptics: false,
              ),
              const SizedBox(height: TinoSpace.s4),
              Text(count, style: TinoType.caption.withColor(c.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
