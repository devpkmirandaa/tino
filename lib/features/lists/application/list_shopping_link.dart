import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shopping/application/shopping_controller.dart';
import '../data/lists_repository.dart';
import '../domain/list_matcher.dart';
import 'lists_providers.dart';

/// Aviso para a interface depois de um produto entrar no carrinho.
sealed class ListFeedback {
  const ListFeedback({
    required this.listId,
    required this.itemId,
    required this.itemName,
    required this.productName,
  });
  final int listId;
  final int itemId;
  final String itemName;
  final String productName;
}

/// Riscado sozinho (confiança alta); a interface oferece "Desfazer".
final class AutoChecked extends ListFeedback {
  const AutoChecked({
    required super.listId,
    required super.itemId,
    required super.itemName,
    required super.productName,
  });
}

/// Parecido, mas sem certeza (ou compra sem lista): a interface pergunta.
/// [listName] não nulo: aceitar também liga a lista à compra.
final class SuggestCheck extends ListFeedback {
  const SuggestCheck({
    required super.listId,
    required super.itemId,
    required super.itemName,
    required super.productName,
    this.listName,
  });
  final String? listName;
}

final listFeedbackProvider = NotifierProvider<_Feedback, ListFeedback?>(
  _Feedback.new,
);

class _Feedback extends Notifier<ListFeedback?> {
  @override
  ListFeedback? build() => null;

  void set(ListFeedback? value) => state = value;
}

/// Liga carrinho e lista. Fica ativo enquanto o app estiver aberto
/// (observado na raiz do app).
final listShoppingLinkProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<ShoppingSession>>(shoppingProvider, (prev, next) {
    final before = prev?.value;
    final after = next.value;
    // Carga inicial não conta: só o que entrou no carrinho agora.
    if (before == null || after == null) return;
    final known = {for (final i in before.cart.items) i.id};
    final added = [
      for (final i in after.cart.items)
        if (!known.contains(i.id)) (id: i.id, name: i.name),
    ];
    if (added.isNotEmpty) _check(ref, after.listId, added);
  });
});

/// Item da lista riscado sozinho por uma linha do carrinho.
typedef AutoCheck = ({int listId, int itemId});

/// Riscados sozinhos, pelo id da linha do carrinho que os riscou: desfazer a
/// adição no scanner desmarca o item da lista.
final autoChecksProvider = NotifierProvider<AutoChecks, Map<String, AutoCheck>>(
  AutoChecks.new,
);

class AutoChecks extends Notifier<Map<String, AutoCheck>> {
  @override
  Map<String, AutoCheck> build() => const {};

  void put(String cartItemId, AutoCheck check) =>
      state = {...state, cartItemId: check};

  /// Tira e devolve o riscado da linha, se houver.
  AutoCheck? take(String cartItemId) {
    final check = state[cartItemId];
    if (check != null) state = {...state}..remove(cartItemId);
    return check;
  }
}

Future<void> _check(
  Ref ref,
  int? linked,
  List<({String id, String name})> added,
) async {
  try {
    final repo = ref.read(listsRepositoryProvider);
    final pairs = await ref.read(learnedPairsProvider.future);
    final categories = await ref.read(learnedCategoriesProvider.future);
    for (final (:id, :name) in added) {
      if (linked != null) {
        final items = await repo.items(linked);
        final match = bestMatch(
          name,
          items,
          learnedPairs: pairs,
          learnedCategories: categories,
        );
        _log(name, linked, items.where((i) => !i.done).length, match);
        if (match == null) continue;
        final feedback = (
          listId: linked,
          itemId: match.item.id,
          itemName: match.item.name,
          productName: name,
        );
        if (match.confident) {
          await ref
              .read(listsActionsProvider)
              .setDone(linked, match.item.id, true);
          ref.read(autoChecksProvider.notifier).put(id, (
            listId: linked,
            itemId: match.item.id,
          ));
          ref
              .read(listFeedbackProvider.notifier)
              .set(
                AutoChecked(
                  listId: feedback.listId,
                  itemId: feedback.itemId,
                  itemName: feedback.itemName,
                  productName: feedback.productName,
                ),
              );
        } else {
          ref
              .read(listFeedbackProvider.notifier)
              .set(
                SuggestCheck(
                  listId: feedback.listId,
                  itemId: feedback.itemId,
                  itemName: feedback.itemName,
                  productName: feedback.productName,
                ),
              );
        }
        continue;
      }
      // Compra sem lista: procura nas listas com itens pendentes (a mais
      // recente primeiro) e só pergunta; nunca risca sem lista ligada.
      final lists = await ref.read(listsProvider.future);
      var found = false;
      for (final list in lists) {
        if (list.doneCount >= list.itemCount) continue;
        final items = await repo.items(list.id);
        final match = bestMatch(
          name,
          items,
          learnedPairs: pairs,
          learnedCategories: categories,
        );
        if (match == null) continue;
        _log(
          name,
          null,
          items.where((i) => !i.done).length,
          match,
          list: list.name,
        );
        ref
            .read(listFeedbackProvider.notifier)
            .set(
              SuggestCheck(
                listId: list.id,
                itemId: match.item.id,
                itemName: match.item.name,
                productName: name,
                listName: list.name,
              ),
            );
        found = true;
        break;
      }
      if (!found) _log(name, null, 0, null);
    }
  } on Object catch (e, s) {
    // Riscar é ajuda, não pode atrapalhar a compra.
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: s, library: 'lists'),
    );
  }
}

/// Diagnóstico (logcat): por que o produto casou ou não com a lista.
void _log(
  String product,
  int? linked,
  int pending,
  ListMatch? match, {
  String? list,
}) => debugPrint(
  'tino-lista "$product" | lista ligada=${linked ?? 'nenhuma'}'
  '${list == null ? '' : ' sugerida=$list'} pendentes=$pending | '
  '${match == null ? 'sem item correspondente' : '${match.confident ? 'risca' : 'pergunta'} "${match.item.name}" (${match.reason})'}',
);
