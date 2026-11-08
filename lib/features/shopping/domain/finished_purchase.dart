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
    this.place,
  });

  final int id;
  final DateTime finishedAt;
  final Cart cart;
  final Money? budget;

  /// "Onde foi a compra?", se a pessoa disse.
  final String? place;

  BudgetStatus get status => budgetStatus(cart.total, budget);
}

/// Mercado digitado ao finalizar: sem espaços nas pontas; vazio vira nulo.
String? cleanPlace(String? text) {
  final t = text?.trim().replaceAll(RegExp(r'\s+'), ' ');
  return t == null || t.isEmpty ? null : t;
}

/// Selo do Finalizar: quanto sobrou ou passou do orçamento (nulo sem
/// orçamento). [over] pede o selo invertido.
({String text, bool over})? budgetSeal(Money total, Money? budget) {
  if (budget == null) return null;
  if (total > budget) {
    return (
      text: 'Passou ${(total - budget).format()} do orçamento',
      over: true,
    );
  }
  return (
    text: 'Sobraram ${(budget - total).format()} do orçamento',
    over: false,
  );
}
