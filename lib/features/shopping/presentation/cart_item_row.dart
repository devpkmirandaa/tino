import 'package:flutter/material.dart';

import '../../../core/theme/tino_theme.dart';
import '../domain/cart.dart';
import '../domain/decimal_input.dart';

class CartItemRow extends StatelessWidget {
  const CartItemRow(this.item, {super.key, this.onTap});
  final CartItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = switch (item) {
      UnitItem(:final quantity, :final price) =>
        '$quantity × ${price.format()}',
      WeightItem(:final grams, :final pricePerKg) =>
        '${formatKg(grams)} × ${pricePerKg.format()}/kg',
    };
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TinoSpace.s16,
            vertical: TinoSpace.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: text.bodySmall?.money.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TinoSpace.s12),
              Text(item.total.format(), style: text.bodyLarge?.money),
            ],
          ),
        ),
      ),
    );
  }
}
