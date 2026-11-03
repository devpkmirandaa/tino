import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/budget.dart';
import '../domain/cart.dart';
import '../domain/money.dart';

/// Compra em andamento, mantida em memória até a persistência em Drift.
final class ShoppingSession {
  const ShoppingSession({this.cart = const Cart(), this.budget});

  final Cart cart;
  final Money? budget;

  BudgetStatus get status => budgetStatus(cart.total, budget);
}

final shoppingProvider = NotifierProvider<ShoppingController, ShoppingSession>(
  ShoppingController.new,
);

class ShoppingController extends Notifier<ShoppingSession> {
  var _nextId = 0;

  @override
  ShoppingSession build() => const ShoppingSession();

  String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  /// Aplica a adição salvo em conflito de preço, que fica para a interface.
  AddResult add(CartItem item, {bool force = false}) {
    final result = state.cart.add(item, force: force);
    if (result is! PriceConflict) _set(result.cart);
    return result;
  }

  void replace(CartItem item) => _set(state.cart.replace(item));

  void remove(String id) => _set(state.cart.remove(id));

  void setBudget(Money? budget) =>
      state = ShoppingSession(cart: state.cart, budget: budget);

  void _set(Cart cart) =>
      state = ShoppingSession(cart: cart, budget: state.budget);
}
