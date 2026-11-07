import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/tino_haptics.dart';
import '../../settings/data/settings_preferences.dart';
import '../domain/budget.dart';
import 'shopping_controller.dart';

/// Atraso do aviso de 90%: dá pra sentir separado da vibração de "item
/// adicionado" do scanner, que cai no mesmo instante.
const nearBudgetAlertDelay = Duration(milliseconds: 300);

/// Vibra uma vez quando a compra passa de 90% do orçamento, se "Avisar
/// quando faltar pouco" estiver ligado. Fica no app (como o vínculo com a
/// lista), então vale com o scanner aberto. O texto "Perto do limite" e o
/// aviso de 100% não dependem desta chave.
final budgetAlertProvider = Provider<void>((ref) {
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  // Carrega a chave já na abertura; o valor é lido na hora do aviso.
  ref.watch(nearBudgetAlertProvider);
  ref.listen<AsyncValue<ShoppingSession>>(shoppingProvider, (prev, next) {
    final before = prev?.value;
    final after = next.value;
    if (before == null || after == null) return;
    final crossed = reachedNearBudget(
      before: before.cart.total,
      after: after.cart.total,
      budgetBefore: before.budget,
      budgetAfter: after.budget,
    );
    if (!crossed || !(ref.read(nearBudgetAlertProvider).value ?? true)) return;
    timer?.cancel();
    timer = Timer(nearBudgetAlertDelay, TinoHaptics.warning);
  });
});
