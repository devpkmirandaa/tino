import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lists_repository.dart';
import '../domain/shopping_list.dart';

/// Todas as listas, mais recente primeiro.
final listsProvider = FutureProvider<List<ShoppingListInfo>>(
  (ref) => ref.watch(listsRepositoryProvider).lists(),
);

/// Uma lista (nula se foi apagada), a partir de [listsProvider].
final listProvider = Provider.family<AsyncValue<ShoppingListInfo?>, int>(
  (ref, id) => ref
      .watch(listsProvider)
      .whenData((all) => all.where((l) => l.id == id).firstOrNull),
);

/// Itens de uma lista, sem ordem definida (a tela arruma).
final listItemsProvider = FutureProvider.family<List<ListItem>, int>(
  (ref, id) => ref.watch(listsRepositoryProvider).items(id),
);

/// Categorias aprendidas com as trocas do usuário (nome → categoria).
final learnedCategoriesProvider = FutureProvider<Map<String, ItemCategory>>(
  (ref) => ref.watch(listsRepositoryProvider).learnedCategories(),
);

final listsActionsProvider = Provider<ListsActions>(ListsActions.new);

/// Alterações nas listas: gravam no banco e recarregam o que mudou.
class ListsActions {
  ListsActions(this._ref);
  final Ref _ref;

  ListsRepository get _repo => _ref.read(listsRepositoryProvider);

  Future<T> _then<T>(Future<T> change, [int? listId]) async {
    final result = await change;
    _ref.invalidate(listsProvider);
    if (listId != null) _ref.invalidate(listItemsProvider(listId));
    return result;
  }

  Future<int> createList(String name) => _then(_repo.createList(name));

  Future<void> renameList(int id, String name) =>
      _then(_repo.renameList(id, name));

  Future<void> setOrder(int id, ListOrder order) =>
      _then(_repo.setOrder(id, order));

  Future<void> deleteList(int id) => _then(_repo.deleteList(id), id);

  Future<int> addItem(
    int listId, {
    required String name,
    required ItemCategory category,
    int quantity = 1,
  }) => _then(
    _repo.addItem(listId, name: name, category: category, quantity: quantity),
    listId,
  );

  Future<void> updateItem(
    int listId,
    int id, {
    required String name,
    required ItemCategory category,
    required int quantity,
  }) => _then(
    _repo.updateItem(
      listId,
      id,
      name: name,
      category: category,
      quantity: quantity,
    ),
    listId,
  );

  Future<void> learnCategory(String name, ItemCategory category) async {
    await _repo.learnCategory(name, category);
    _ref.invalidate(learnedCategoriesProvider);
  }

  Future<void> setDone(int listId, int id, bool done) =>
      _then(_repo.setDone(listId, id, done), listId);

  Future<void> deleteItem(int listId, int id) =>
      _then(_repo.deleteItem(listId, id), listId);
}
