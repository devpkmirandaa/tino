import 'package:flutter/material.dart';

import '../../../core/theme/tino_theme.dart';
import '../domain/cart.dart';
import '../domain/decimal_input.dart';

/// Linha de apoio do item: "2 × R$ 3,99" ou "0,250 kg × R$ 12,00/kg".
String cartItemDetail(CartItem item) => switch (item) {
  UnitItem(:final quantity, :final price) => '$quantity × ${price.format()}',
  WeightItem(:final grams, :final pricePerKg) =>
    '${formatKg(grams)} × ${pricePerKg.format()}/kg',
};

class CartItemRow extends StatelessWidget {
  const CartItemRow(this.item, {super.key, this.onTap});
  final CartItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = cartItemDetail(item);
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
                      style: text.bodyLarge?.weight(FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: text.bodySmall?.money.weight(FontWeight.w500),
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
