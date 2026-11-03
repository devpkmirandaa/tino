import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/budget.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/money.dart';

UnitItem unit(String id, String name, int cents, [int qty = 1]) =>
    UnitItem(id: id, name: name, price: Money(cents), quantity: qty);

void main() {
  group('Money', () {
    test('formata em reais', () {
      expect(Money(0).format(), r'R$ 0,00');
      expect(Money(5).format(), r'R$ 0,05');
      expect(Money(123456789).format(), r'R$ 1.234.567,89');
      expect(Money(-1990).format(), r'-R$ 19,90');
    });

    test('preço por peso arredonda meio para cima', () {
      expect(Money.byWeight(Money(3990), 347), Money(1385)); // 13,8453
      expect(Money.byWeight(Money(1000), 5), Money(5)); // 0,05 exato
      expect(Money.byWeight(Money(1), 500), Money(1)); // 0,005 → 0,01
      expect(Money.byWeight(Money(1), 499), Money(0)); // 0,00499 → 0,00
      expect(Money.byWeight(Money(2499), 1000), Money(2499));
      expect(() => Money.byWeight(Money(-1), 10), throwsArgumentError);
    });
  });

  group('Cart', () {
    test('total soma unidades e pesos', () {
      final cart = const Cart()
          .add(unit('a', 'Arroz', 2490, 2))
          .cart
          .add(
            WeightItem(
              id: 'b',
              name: 'Tomate',
              pricePerKg: Money(899),
              grams: 1250,
            ),
          )
          .cart;
      expect(cart.total, Money(4980 + 1124)); // 11,2375 → 11,24
    });

    test('duplicata com mesmo preço soma quantidade', () {
      final r = const Cart()
          .add(unit('a', 'Leite  Integral', 549))
          .cart
          .add(unit('b', ' leite integral', 549, 2));
      expect(r, isA<Merged>());
      expect(r.cart.items, hasLength(1));
      expect((r.cart.items.single as UnitItem).quantity, 3);
      expect(r.cart.total, Money(1647));
    });

    test('duplicata com preço diferente pede decisão', () {
      final cart = const Cart().add(unit('a', 'Café', 1890)).cart;
      final r = cart.add(unit('b', 'café', 1790));
      expect(r, isA<PriceConflict>());
      expect(r.cart, same(cart));
      expect((r as PriceConflict).existing.id, 'a');

      final forced = cart.add(unit('b', 'café', 1790), force: true).cart;
      expect(forced.items, hasLength(2));
      final fixed = cart.replace(r.existing.copyWith(price: Money(1790)));
      expect(fixed.total, Money(1790));
    });

    test('itens por peso não são mesclados', () {
      WeightItem w(String id) => WeightItem(
        id: id,
        name: 'Banana',
        pricePerKg: Money(599),
        grams: 1000,
      );
      final r = const Cart().add(w('a')).cart.add(w('b'));
      expect(r, isA<Added>());
      expect(r.cart.items, hasLength(2));
    });

    test('correção e remoção atualizam o total', () {
      var cart = const Cart().add(unit('a', 'Pão', 100, 3)).cart;
      cart = cart.replace(
        (cart.items.single as UnitItem).copyWith(price: Money(150)),
      );
      expect(cart.total, Money(450));
      expect(cart.remove('a').total, Money.zero);
    });

    test('rejeita itens inválidos', () {
      expect(() => unit('a', 'X', -1), throwsArgumentError);
      expect(() => unit('a', 'X', 100, 0), throwsArgumentError);
      expect(
        () => WeightItem(id: 'a', name: 'X', pricePerKg: Money(1), grams: 0),
        throwsArgumentError,
      );
    });
  });

  group('budgetStatus', () {
    test('transições', () {
      final b = Money(10000);
      expect(budgetStatus(Money(9999), null), BudgetStatus.none);
      expect(budgetStatus(Money.zero, b), BudgetStatus.within);
      expect(budgetStatus(Money(8999), b), BudgetStatus.within);
      expect(budgetStatus(Money(9000), b), BudgetStatus.near);
      expect(budgetStatus(Money(10000), b), BudgetStatus.near);
      expect(budgetStatus(Money(10001), b), BudgetStatus.over);
      expect(() => budgetStatus(Money.zero, Money.zero), throwsArgumentError);
    });
  });
}
