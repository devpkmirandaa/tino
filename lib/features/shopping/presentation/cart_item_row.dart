import '../domain/cart.dart';
import '../domain/decimal_input.dart';

/// Textos da linha de item (`TinoItemRow`) no Comprar e no Resumo da compra.

/// Nome para mostrar: item digitado sem nome aparece como "Sem nome", em
/// `text-secondary` (ver [CartItem.unnamed]).
String cartItemName(CartItem item) => item.unnamed ? 'Sem nome' : item.name;

/// Linha de apoio do item: "2 × R$ 3,99" ou "0,250 kg × R$ 12,00/kg".
String cartItemDetail(CartItem item) => switch (item) {
  UnitItem(:final quantity, :final price) => '$quantity × ${price.format()}',
  WeightItem(:final grams, :final pricePerKg) =>
    '${formatKg(grams)} × ${pricePerKg.format()}/kg',
};
