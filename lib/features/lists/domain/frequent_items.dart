import '../../shopping/domain/product_name.dart';
import 'category_suggester.dart';
import 'list_matcher.dart';
import 'shopping_list.dart';

/// Compra finalizada vista pelos chips "Você costuma levar"
/// (design/specs/lista-v2.md): os produtos do carrinho, com o texto lido
/// na etiqueta, e os itens da lista usada nela.
typedef PastPurchase = ({
  DateTime finishedAt,
  List<({String name, String? tagText})> products,
  List<String> listItems,
});

/// Nome digitado ou corrigido pela pessoa. Sem texto de etiqueta, o item foi
/// digitado; com ele, só conta se o nome não for o que a leitura deu (o
/// texto cru ou o arrumado por [tidyProductName]).
bool typedByPerson(String name, String? tagText) {
  if (tagText == null) return true;
  final key = categoryKey(name);
  return key != categoryKey(tagText) &&
      key != categoryKey(tidyProductName(tagText));
}

/// Itens frequentes que ainda não estão na lista ([current], marcados ou
/// não). Contam os itens das listas usadas e os produtos com nome da pessoa;
/// cada nome conta uma vez por compra. Entra quem aparece em [minPurchases]
/// compras ou mais, do mais frequente ao menos; no empate, o mais recente.
/// O nome mostrado é a grafia mais recente. Com [query] (o que está sendo
/// digitado), só os que contêm o texto, sem diferença de acento e caixa.
List<String> frequentItems(
  Iterable<PastPurchase> purchases,
  Iterable<ListItem> current, {
  String query = '',
  int minPurchases = 2,
  int max = 8,
}) {
  final typed = categoryKey(query);
  final counts = <String, int>{};
  final last = <String, DateTime>{};
  final spelling = <String, String>{};
  for (final p in purchases) {
    final names = [
      ...p.listItems,
      for (final product in p.products)
        if (typedByPerson(product.name, product.tagText)) product.name,
    ];
    final seen = <String>{};
    for (final raw in names) {
      final name = raw.trim();
      final key = categoryKey(name);
      if (key.isEmpty || !seen.add(key)) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      final at = last[key];
      if (at == null || p.finishedAt.isAfter(at)) {
        last[key] = p.finishedAt;
        spelling[key] = name;
      }
    }
  }
  // Na lista, marcado ou não, já não é sugestão.
  final onList = [
    for (final i in current)
      ListItem(
        id: i.id,
        name: i.name,
        category: i.category,
        position: i.position,
        createdAt: i.createdAt,
      ),
  ];
  final keys =
      [
        for (final e in counts.entries)
          if (e.value >= minPurchases &&
              e.key.contains(typed) &&
              bestMatch(spelling[e.key]!, onList) == null)
            e.key,
      ]..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : last[b]!.compareTo(last[a]!);
      });
  return [for (final k in keys.take(max)) spelling[k]!];
}
