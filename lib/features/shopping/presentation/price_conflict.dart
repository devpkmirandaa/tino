import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../domain/money.dart';

/// Mesmo produto no carrinho com outro preço: nome e os dois preços lado a
/// lado ("No carrinho" × [nextLabel]). Usado na folha do scanner e na folha
/// Digitar preço; as ações (Atualizar · Manter) ficam com quem usa.
/// [reveal] anima cada parte em sequência (índice 0 e 1).
class PriceConflictBlock extends StatelessWidget {
  const PriceConflictBlock({
    super.key,
    required this.name,
    required this.current,
    required this.next,
    required this.nextLabel,
    this.reveal,
  });

  final String name;
  final Money current;
  final Money next;
  final String nextLabel;
  final Widget Function(int index, Widget child)? reveal;

  static const _edge = 2.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    Widget wrap(int i, Widget child) => reveal?.call(i, child) ?? child;
    Widget block(String label, Money price, {required bool fresh}) => Container(
      padding: const EdgeInsets.all(TinoSpace.s12 - _edge),
      decoration: BoxDecoration(
        color: fresh ? c.surface : c.surfaceSoft,
        borderRadius: BorderRadius.circular(TinoRadius.control),
        // Borda transparente no outro bloco: os dois ficam do mesmo tamanho.
        border: Border.all(
          color: fresh ? c.action : c.surfaceSoft,
          width: _edge,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: fresh
                ? TinoType.caption.withColor(c.action).weight(FontWeight.w600)
                : TinoType.caption.withColor(c.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            price.format(),
            maxLines: 1,
            style: TinoType.secao.withColor(c.textPrimary).money,
          ),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          wrap(
            0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: c.textSecondary),
                    const SizedBox(width: TinoSpace.s4),
                    Flexible(
                      child: Text(
                        'Já está no carrinho com outro preço',
                        style: TinoType.caption
                            .withColor(c.textSecondary)
                            .weight(FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TinoSpace.s4),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TinoType.secao.withColor(c.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: TinoSpace.s16),
          wrap(
            1,
            Row(
              children: [
                Expanded(child: block('No carrinho', current, fresh: false)),
                const SizedBox(width: TinoSpace.s8),
                Expanded(child: block(nextLabel, next, fresh: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
