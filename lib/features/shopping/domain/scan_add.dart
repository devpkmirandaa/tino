import 'cart.dart';
import 'money.dart';

/// Escolha do usuário quando o produto já está no carrinho com outro preço.
enum ConflictChoice {
  /// "Usar R$ X": a linha existente passa ao preço novo e soma a quantidade.
  useNew,

  /// "Manter R$ Y": o carrinho fica como está e a leitura nova é descartada.
  keepCurrent,

  /// "Somar como outro": entra como linha separada, no preço novo.
  separate,
}

/// Carrinho depois de uma adição do scanner e a linha que ela tocou.
typedef ScanAddResult = ({Cart cart, String lineId, Money unitPrice});

/// Uma adição feita pelo scanner. Guarda o carrinho de antes, então pode ser
/// refeita com outra quantidade ou desfeita sem afetar o resto.
final class ScanAdd {
  const ScanAdd({required this.before, required this.item, this.choice});

  /// Carrinho antes desta adição: desfazer volta a ele.
  final Cart before;
  final UnitItem item;
  final ConflictChoice? choice;

  ScanAdd copyWith({UnitItem? item, ConflictChoice? choice}) => ScanAdd(
    before: before,
    item: item ?? this.item,
    choice: choice ?? this.choice,
  );

  /// Linha do carrinho com o mesmo produto e outro preço, se houver.
  UnitItem? get conflict => switch (before.add(item)) {
    PriceConflict(:final existing) => existing,
    _ => null,
  };

  /// Nulo enquanto houver conflito de preço sem [choice].
  ScanAddResult? apply() {
    switch (before.add(item)) {
      case Added(:final cart):
        return (cart: cart, lineId: item.id, unitPrice: item.price);
      case Merged(:final cart):
        final line = before.items.whereType<UnitItem>().firstWhere(
          (e) => e.key == item.key && e.price == item.price,
        );
        return (cart: cart, lineId: line.id, unitPrice: item.price);
      case PriceConflict(:final existing):
        final quantity = existing.quantity + item.quantity;
        return switch (choice) {
          null => null,
          ConflictChoice.useNew => (
            cart: before.replace(
              existing.copyWith(price: item.price, quantity: quantity),
            ),
            lineId: existing.id,
            unitPrice: item.price,
          ),
          ConflictChoice.keepCurrent => (
            cart: before,
            lineId: existing.id,
            unitPrice: existing.price,
          ),
          ConflictChoice.separate => (
            cart: before.add(item, force: true).cart,
            lineId: item.id,
            unitPrice: item.price,
          ),
        };
    }
  }
}

/// Mesmo produto lido de novo em menos de [window]: não entra outra vez
/// (design/specs/telas.md · 03).
final class RepeatGuard {
  RepeatGuard({this.window = const Duration(seconds: 3)});

  final Duration window;
  ({String key, Money price, DateTime at})? _last;

  /// Mesmo nome normalizado e mesmo preço da última adição, dentro da janela.
  bool blocks(UnitItem item, DateTime now) {
    final last = _last;
    return last != null &&
        last.key == item.key &&
        last.price == item.price &&
        now.difference(last.at) < window;
  }

  void record(UnitItem item, DateTime now) =>
      _last = (key: item.key, price: item.price, at: now);

  /// Desfeito: a mesma etiqueta pode entrar de novo na hora.
  void clear() => _last = null;
}
