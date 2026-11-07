import 'money.dart';

/// Item do carrinho: por unidade ([quantity]) ou por peso ([grams]).
sealed class CartItem {
  const CartItem(this.id, this.name, this.tagText);

  final String id;
  final String name;

  /// Linha do nome como o scanner leu na etiqueta, antes de arrumar
  /// ("MOLHO DE TOMATE PIZZA QUERO 240G"). Nulo em item digitado.
  final String? tagText;

  Money get total;

  /// Nome normalizado para detectar duplicatas.
  String get key => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

final class UnitItem extends CartItem {
  UnitItem({
    required String id,
    required String name,
    required this.price,
    this.quantity = 1,
    String? tagText,
  }) : super(id, name, tagText) {
    if (price.cents < 0 || quantity < 1) throw ArgumentError('Item inválido');
  }

  final Money price;
  final int quantity;

  @override
  Money get total => price * quantity;

  UnitItem copyWith({Money? price, int? quantity, String? name}) => UnitItem(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    tagText: tagText,
  );
}

final class WeightItem extends CartItem {
  WeightItem({
    required String id,
    required String name,
    required this.pricePerKg,
    required this.grams,
    String? tagText,
  }) : super(id, name, tagText) {
    if (pricePerKg.cents < 0 || grams < 1) throw ArgumentError('Item inválido');
  }

  final Money pricePerKg;
  final int grams;

  @override
  Money get total => Money.byWeight(pricePerKg, grams);

  WeightItem copyWith({Money? pricePerKg, int? grams, String? name}) =>
      WeightItem(
        id: id,
        name: name ?? this.name,
        pricePerKg: pricePerKg ?? this.pricePerKg,
        grams: grams ?? this.grams,
        tagText: tagText,
      );
}

/// Resultado de [Cart.add].
sealed class AddResult {
  const AddResult(this.cart);
  final Cart cart;
}

final class Added extends AddResult {
  const Added(super.cart);
}

/// Mesmo produto e mesmo preço: a quantidade foi somada.
final class Merged extends AddResult {
  const Merged(super.cart);
}

/// Mesmo produto com preço diferente: carrinho inalterado até o usuário
/// decidir (ver [Cart.add] com `force: true` ou [Cart.replace]).
final class PriceConflict extends AddResult {
  const PriceConflict(super.cart, this.existing);
  final UnitItem existing;
}

/// Carrinho imutável; o total é sempre a soma exata dos itens.
final class Cart {
  const Cart([this.items = const []]);

  final List<CartItem> items;

  Money get total => items.fold(Money.zero, (sum, i) => sum + i.total);

  /// Itens por peso nunca são mesclados: cada pesagem é uma embalagem.
  AddResult add(CartItem item, {bool force = false}) {
    if (item is UnitItem && !force) {
      for (final e in items.whereType<UnitItem>()) {
        if (e.key != item.key) continue;
        if (e.price == item.price) {
          return Merged(
            replace(e.copyWith(quantity: e.quantity + item.quantity)),
          );
        }
        return PriceConflict(this, e);
      }
    }
    return Added(Cart([...items, item]));
  }

  /// Substitui o item de mesmo id (correção de preço, peso, nome...).
  Cart replace(CartItem item) =>
      Cart([for (final i in items) i.id == item.id ? item : i]);

  Cart remove(String id) => Cart([...items.where((i) => i.id != id)]);

  /// Desfaz um [remove]: põe [item] de volta na posição [index] (limitada ao
  /// tamanho atual). Se o item já estiver no carrinho, nada muda.
  Cart restore(CartItem item, int index) {
    if (items.any((i) => i.id == item.id)) return this;
    return Cart([...items]..insert(index.clamp(0, items.length), item));
  }
}
