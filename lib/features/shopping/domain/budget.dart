import 'money.dart';

enum BudgetStatus { none, within, near, over }

/// Percentual do orçamento a partir do qual a compra fica "perto do limite".
const nearBudgetPercent = 90;

/// Situação do [total] frente ao [budget] (nulo = sem orçamento).
/// Atingir exatamente o orçamento é "perto", não "estourado".
BudgetStatus budgetStatus(Money total, Money? budget) {
  if (budget == null) return BudgetStatus.none;
  if (budget.cents <= 0) throw ArgumentError("Orçamento deve ser positivo");
  if (total > budget) return BudgetStatus.over;
  if (total.cents * 100 >= budget.cents * nearBudgetPercent) {
    return BudgetStatus.near;
  }
  return BudgetStatus.within;
}
