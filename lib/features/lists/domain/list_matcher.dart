import 'category_suggester.dart';
import 'shopping_list.dart';

/// Item da lista que corresponde a um produto, com a confiança.
/// [confident]: risca sozinho (com "Desfazer"); senão, pergunta antes.
typedef ListMatch = ({ListItem item, bool confident, String reason});

/// Chave de um par produto → item para aprender a resposta do usuário.
String pairKey(String productName, String itemName) =>
    '${categoryKey(productName)}>${categoryKey(itemName)}';

/// Melhor item pendente para o produto posto no carrinho.
///
/// 1. Par já respondido pelo usuário ([learnedPairs]) decide: confirmado
///    risca, desfeito nunca casa.
/// 2. A palavra principal do item (a primeira: "Tapioca", "Escova")
///    precisa aparecer no produto, com plural, família de palavra,
///    sinônimo e erro de uma letra tolerados.
/// 3. Categoria como conferência: produto e item em categorias diferentes
///    (fora "Outros") não casam: "Leite" não casa com "Sabonete de leite".
/// 4. Todas as palavras do item no produto: confiante. Só a principal:
///    pergunta. Vence quem cobre mais palavras; no empate, o mais antigo.
ListMatch? bestMatch(
  String productName,
  Iterable<ListItem> items, {
  Map<String, bool> learnedPairs = const {},
  Map<String, ItemCategory> learnedCategories = const {},
}) {
  final product = nameWords(productName);
  if (product.isEmpty) return null;
  final productCategory = suggestCategory(
    productName,
    learned: learnedCategories,
  );
  ListMatch? best;
  var bestScore = -1.0;
  for (final item in items) {
    if (item.done) continue;
    switch (learnedPairs[pairKey(productName, item.name)]) {
      case true:
        return (item: item, confident: true, reason: 'par aprendido');
      case false:
        continue;
      case null:
    }
    final wanted = nameWords(item.name);
    if (wanted.isEmpty) continue;
    bool found(String w) => product.any((p) => sameWord(w, p));
    if (!found(wanted.first)) continue;
    if (productCategory != ItemCategory.outros &&
        item.category != ItemCategory.outros &&
        productCategory != item.category) {
      continue;
    }
    final covered = wanted.where(found).length;
    final score = covered / wanted.length + covered * 0.01;
    final better =
        score > bestScore ||
        (score == bestScore &&
            best != null &&
            item.createdAt.isBefore(best.item.createdAt));
    if (better) {
      bestScore = score;
      final all = covered == wanted.length;
      best = (
        item: item,
        confident: all,
        reason: all
            ? 'todas as palavras'
            : 'palavra principal ($covered de ${wanted.length})',
      );
    }
  }
  return best;
}
