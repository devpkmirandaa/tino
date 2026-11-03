import 'budget.dart';
import 'cart.dart';
import 'money.dart';

/// Compra finalizada, somente leitura.
final class FinishedPurchase {
  const FinishedPurchase({
    required this.id,
    required this.finishedAt,
    required this.cart,
    this.budget,
  });

  final int id;
  final DateTime finishedAt;
  final Cart cart;
  final Money? budget;

  BudgetStatus get status => budgetStatus(cart.total, budget);
}
