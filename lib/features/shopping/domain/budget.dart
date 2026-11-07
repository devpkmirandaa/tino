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

/// Percentual do orçamento já usado, arredondado para baixo (nunca mostra
/// mais do que foi gasto): 137,40 de 150,00 → 91.
int budgetUsedPercent(Money total, Money budget) {
  if (budget.cents <= 0) throw ArgumentError("Orçamento deve ser positivo");
  return total.cents * 100 ~/ budget.cents;
}

/// A compra acabou de passar de 90% do orçamento por gasto: o total subiu,
/// com o mesmo orçamento, de "dentro" para "perto". Mudar o orçamento não
/// conta, e pular direto para "passou" fica com o aviso de 100%.
bool reachedNearBudget({
  required Money before,
  required Money after,
  required Money? budgetBefore,
  required Money? budgetAfter,
}) =>
    budgetAfter != null &&
    budgetBefore == budgetAfter &&
    budgetStatus(before, budgetAfter) == BudgetStatus.within &&
    budgetStatus(after, budgetAfter) == BudgetStatus.near;
