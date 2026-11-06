import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shopping_repository.dart';
import '../domain/budget.dart';
import '../domain/cart.dart';
import '../domain/finished_purchase.dart';
import '../domain/money.dart';

/// Compra em andamento.
final class ShoppingSession {
  const ShoppingSession({this.cart = const Cart(), this.budget, this.listId});

  final Cart cart;
  final Money? budget;

  /// Lista usada nesta compra: itens adicionados são riscados nela.
  final int? listId;

  BudgetStatus get status => budgetStatus(cart.total, budget);
}

const _keep = Object();

final shoppingProvider =
    AsyncNotifierProvider<ShoppingController, ShoppingSession>(
      ShoppingController.new,
    );

/// Compras finalizadas; recarregado ao finalizar uma compra.
final historyProvider = FutureProvider<List<FinishedPurchase>>(
  (ref) => ref.watch(shoppingRepositoryProvider).history(),
);

/// Carrega a compra ativa do banco; cada alteração aparece na hora e é
/// gravada em seguida, em ordem.
class ShoppingController extends AsyncNotifier<ShoppingSession> {
  var _nextId = 0;
  Future<void> _saving = Future.value();

  @override
  Future<ShoppingSession> build() =>
      ref.watch(shoppingRepositoryProvider).loadActive();

  ShoppingSession get _session => state.requireValue;

  String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  /// Aplica a adição salvo em conflito de preço, que fica para a interface.
  AddResult add(CartItem item, {bool force = false}) {
    final result = _session.cart.add(item, force: force);
    if (result is! PriceConflict) _set(result.cart, _session.budget);
    return result;
  }

  void replace(CartItem item) =>
      _set(_session.cart.replace(item), _session.budget);

  void remove(String id) => _set(_session.cart.remove(id), _session.budget);

  void setBudget(Money? budget) => _set(_session.cart, budget);

  /// Esvazia o carrinho da compra ativa; o orçamento continua.
  void clear() => _set(const Cart(), _session.budget);

  /// Liga (ou desliga, com nulo) uma lista à compra ativa.
  void setList(int? listId) =>
      _set(_session.cart, _session.budget, listId: listId);

  /// Grava o que falta, finaliza a compra ativa e começa uma nova, vazia.
  Future<void> finish() async {
    await _saving;
    await ref.read(shoppingRepositoryProvider).finishActive();
    state = const AsyncData(ShoppingSession());
    ref.invalidate(historyProvider);
  }

  /// Aguarda as gravações pendentes (usado em testes).
  Future<void> flush() => _saving;

  void _set(Cart cart, Money? budget, {Object? listId = _keep}) {
    final session = ShoppingSession(
      cart: cart,
      budget: budget,
      listId: identical(listId, _keep) ? _session.listId : listId as int?,
    );
    state = AsyncData(session);
    final repository = ref.read(shoppingRepositoryProvider);
    _saving = _saving
        .then((_) => repository.saveActive(session))
        .catchError(
          (Object e, StackTrace s) => FlutterError.reportError(
            FlutterErrorDetails(exception: e, stack: s, library: 'shopping'),
          ),
        );
  }
}
