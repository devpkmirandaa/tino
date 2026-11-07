import 'cart.dart';
import 'decimal_input.dart';
import 'money.dart';

/// Campos da folha Detalhe do item (design/specs/telas.md · 05).
typedef ItemEdit = ({
  String name,
  bool byWeight,
  String price,
  int quantity,
  String weight,
});

/// Valores iniciais da folha a partir do item do carrinho.
ItemEdit editOf(CartItem item) => switch (item) {
  UnitItem(:final price, :final quantity) => (
    name: item.name,
    byWeight: false,
    price: plainScaled(price.cents, 2),
    quantity: quantity,
    weight: '',
  ),
  WeightItem(:final pricePerKg, :final grams) => (
    name: item.name,
    byWeight: true,
    price: plainScaled(pricePerKg.cents, 2),
    quantity: 1,
    weight: plainScaled(grams, 3),
  ),
};

/// Item corrigido, mesmo id e texto da etiqueta (ver [buildItem]).
CartItem? applyEdit(CartItem original, ItemEdit edit) =>
    buildItem(original.id, edit, tagText: original.tagText);

/// Item a partir dos campos das folhas; nulo se faltar preço ou peso. Nome é
/// opcional: vazio fica gravado vazio ("Sem nome" na tela). Por quilo, o
/// preço digitado é o preço/kg.
CartItem? buildItem(String id, ItemEdit edit, {String? tagText}) {
  final name = edit.name.trim();
  final price = parseScaled(edit.price, 2);
  if (price == null) return null;
  if (!edit.byWeight) {
    if (edit.quantity < 1) return null;
    return UnitItem(
      id: id,
      name: name,
      price: Money(price),
      quantity: edit.quantity,
      tagText: tagText,
    );
  }
  final grams = parseScaled(edit.weight, 3);
  if (grams == null || grams < 1) return null;
  return WeightItem(
    id: id,
    name: name,
    pricePerKg: Money(price),
    grams: grams,
    tagText: tagText,
  );
}
