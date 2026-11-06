import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tino_theme.dart';
import 'tino_button.dart';

/// Contador de quantidade: 48 de altura, botões 48 × 48, número 16/700
/// tabular. Respeita [min] e [max].
class TinoQuantityStepper extends StatelessWidget {
  const TinoQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 999,
    this.semanticLabel = 'Quantidade',
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final change = onChanged;
    return Container(
      height: TinoSize.touchTarget,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TinoRadius.control),
        border: Border.all(color: c.borderStrong, width: TinoSize.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TinoIconButton(
            icon: LucideIcons.minus,
            semanticLabel: 'Diminuir',
            compact: true,
            onPressed: change == null || value <= min
                ? null
                : () => change(value - 1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: TinoSpace.s32),
            child: Semantics(
              label: semanticLabel,
              value: '$value',
              excludeSemantics: true,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TinoType.corpo.withColor(c.textPrimary).money,
              ),
            ),
          ),
          TinoIconButton(
            icon: LucideIcons.plus,
            semanticLabel: 'Aumentar',
            compact: true,
            onPressed: change == null || value >= max
                ? null
                : () => change(value + 1),
          ),
        ],
      ),
    );
  }
}
