import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/money.dart';
import 'package:tino/features/shopping/domain/scan_add.dart';

UnitItem unit(String id, String name, int cents, [int qty = 1]) =>
    UnitItem(id: id, name: name, price: Money(cents), quantity: qty);

void main() {
  final molho = unit('a', 'Molho de tomate', 300, 2);
  final before = Cart([molho, unit('b', 'Arroz', 2500)]);

  group('ScanAdd', () {
    test('produto novo entra como linha nova', () {
      final r = ScanAdd(
        before: before,
        item: unit('n', 'Feijão', 800),
      ).apply()!;
      expect(r.cart.items.length, 3);
      expect(r.lineId, 'n');
      expect(r.cart.total, Money(300 * 2 + 2500 + 800));
    });

    test('mesmo produto e preço soma na linha existente', () {
      final r = ScanAdd(
        before: before,
        item: unit('n', ' molho  de TOMATE', 300),
      ).apply()!;
      expect(r.lineId, 'a');
      expect((r.cart.items.first as UnitItem).quantity, 3);
    });

    test('outro preço sem escolha fica pendente', () {
      final add = ScanAdd(
        before: before,
        item: unit('n', 'Molho de tomate', 350),
      );
      expect(add.apply(), isNull);
      expect(add.conflict?.id, 'a');
    });

    test('usar o preço novo atualiza a linha e soma', () {
      final r = ScanAdd(
        before: before,
        item: unit('n', 'Molho de tomate', 350),
        choice: ConflictChoice.useNew,
      ).apply()!;
      final line = r.cart.items.first as UnitItem;
      expect((line.id, line.price, line.quantity), ('a', Money(350), 3));
      expect(r.unitPrice, Money(350));
      expect(r.cart.items.length, 2);
    });

    test('manter o preço atual só soma a quantidade', () {
      final r = ScanAdd(
        before: before,
        item: unit('n', 'Molho de tomate', 350),
        choice: ConflictChoice.keepCurrent,
      ).apply()!;
      final line = r.cart.items.first as UnitItem;
      expect((line.price, line.quantity), (Money(300), 3));
      expect(r.unitPrice, Money(300));
    });

    test('somar como outro cria linha separada', () {
      final r = ScanAdd(
        before: before,
        item: unit('n', 'Molho de tomate', 350),
        choice: ConflictChoice.separate,
      ).apply()!;
      expect(r.cart.items.length, 3);
      expect(r.lineId, 'n');
      expect(r.cart.total, Money(600 + 2500 + 350));
    });

    test('refazer com outra quantidade parte do carrinho de antes', () {
      final add = ScanAdd(
        before: before,
        item: unit('n', 'Molho de tomate', 300),
      );
      final r = add.copyWith(item: add.item.copyWith(quantity: 4)).apply()!;
      expect((r.cart.items.first as UnitItem).quantity, 6);
    });

    test('desfazer é voltar ao carrinho de antes', () {
      final add = ScanAdd(before: before, item: unit('n', 'Feijão', 800));
      add.apply();
      expect(add.before.total, before.total);
    });
  });

  group('RepeatGuard', () {
    final t0 = DateTime(2026, 11, 6, 10);
    final item = unit('x', 'Molho de tomate', 300);

    test('bloqueia o mesmo produto e preço por 3 s', () {
      final g = RepeatGuard()..record(item, t0);
      expect(
        g.blocks(
          unit('y', 'molho de tomate', 300),
          t0.add(const Duration(milliseconds: 2999)),
        ),
        isTrue,
      );
      expect(g.blocks(item, t0.add(const Duration(seconds: 3))), isFalse);
    });

    test('outro preço ou outro produto passam', () {
      final g = RepeatGuard()..record(item, t0);
      expect(g.blocks(unit('y', 'Molho de tomate', 350), t0), isFalse);
      expect(g.blocks(unit('y', 'Arroz', 300), t0), isFalse);
    });

    test('depois de desfazer não bloqueia', () {
      final g = RepeatGuard()..record(item, t0);
      g.clear();
      expect(g.blocks(item, t0), isFalse);
    });
  });
}
