import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tino/core/database/tino_database.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/item_edit.dart';
import 'package:tino/features/shopping/domain/money.dart';
import 'package:tino/features/shopping/domain/tag_reader.dart';
import 'package:tino/features/shopping/presentation/cart_removal.dart';

OcrLine _l(String text, double top, double height, {double left = 0}) => (
  text: text,
  left: left,
  top: top,
  width: 300,
  height: height,
  glyphs: const [],
);

void main() {
  final molho = UnitItem(
    id: 'm',
    name: 'Molho de tomate',
    price: Money(300),
    tagText: 'MOLHO DE TOMATE PIZZA QUERO 240G',
  );

  group('Detalhe do item', () {
    test('abre com os valores do item, por unidade e por quilo', () {
      expect(editOf(molho), (
        name: 'Molho de tomate',
        byWeight: false,
        price: '3,00',
        quantity: 1,
        weight: '',
      ));
      final tomate = WeightItem(
        id: 't',
        name: 'Tomate',
        pricePerKg: Money(899),
        grams: 350,
      );
      expect(editOf(tomate).weight, '0,350');
      expect(editOf(tomate).price, '8,99');
    });

    test('corrige preço, quantidade e nome mantendo id e etiqueta', () {
      final edit = editOf(molho);
      final saved = applyEdit(molho, (
        name: ' Molho Quero ',
        byWeight: false,
        price: '3,49',
        quantity: 2,
        weight: edit.weight,
      )) as UnitItem;
      expect(saved.id, 'm');
      expect(saved.name, 'Molho Quero');
      expect(saved.total, Money(698));
      expect(saved.tagText, 'MOLHO DE TOMATE PIZZA QUERO 240G');
    });

    test('trocar para por quilo usa o preço como preço/kg e pede o peso', () {
      final base = (
        name: 'Queijo',
        byWeight: true,
        price: '45,90',
        quantity: 1,
        weight: '',
      );
      expect(applyEdit(molho, base), isNull);
      final saved = applyEdit(molho, (
        name: base.name,
        byWeight: true,
        price: base.price,
        quantity: 1,
        weight: '0,250',
      )) as WeightItem;
      expect(saved.grams, 250);
      expect(saved.total, Money(1148)); // 45,90 × 0,250 = 11,475 → 11,48
      expect(saved.tagText, molho.tagText);
    });

    test('sem nome ou preço inválido não salva', () {
      final edit = editOf(molho);
      expect(
        applyEdit(molho, (
          name: '  ',
          byWeight: false,
          price: edit.price,
          quantity: 1,
          weight: '',
        )),
        isNull,
      );
      expect(
        applyEdit(molho, (
          name: edit.name,
          byWeight: false,
          price: 'abc',
          quantity: 1,
          weight: '',
        )),
        isNull,
      );
    });
  });

  test('restaurar devolve o item à posição de antes', () {
    final a = UnitItem(id: 'a', name: 'A', price: Money(100));
    final b = UnitItem(id: 'b', name: 'B', price: Money(200));
    final c = UnitItem(id: 'c', name: 'C', price: Money(300));
    final cart = Cart([a, b, c]).remove('b');
    expect(cart.restore(b, 1).items.map((i) => i.id), ['a', 'b', 'c']);
    // Posição além do fim vai para o fim; item já presente não duplica.
    expect(cart.restore(b, 9).items.map((i) => i.id), ['a', 'c', 'b']);
    expect(cart.restore(a, 0).items.length, 2);
  });

  group('texto da etiqueta', () {
    test('o leitor guarda a linha crua do nome', () {
      final r = readTag([
        _l('MOLHO DE TOMATE PIZZA QUERO 240G', 0, 40),
        _l(r'R$ 3,00', 60, 80),
      ]);
      expect(r.name, isNot(r.tagText));
      expect(r.tagText, 'MOLHO DE TOMATE PIZZA QUERO 240G');
    });

    test('a votação leva o texto cru junto com o nome', () {
      const frame = TagReading(
        name: 'Molho de tomate',
        tagText: 'MOLHO DE TOMATE',
        price: Money(300),
        strength: 2,
      );
      final s = ReadingConsensus()
        ..add(frame)
        ..add(frame);
      expect(s.stable!.tagText, 'MOLHO DE TOMATE');
    });
  });

  group('com banco', () {
    late TinoDatabase db;
    setUp(() => db = TinoDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('texto da etiqueta sobrevive a reabrir o app', () async {
      final first = container();
      await first.read(shoppingProvider.future);
      final ctrl = first.read(shoppingProvider.notifier)..add(molho);
      await ctrl.flush();
      final reopened = await container().read(shoppingProvider.future);
      expect(reopened.cart.items.single.tagText, molho.tagText);
    });

    test('tirar do carrinho e desfazer volta ao mesmo lugar', () async {
      final c = container();
      await c.read(shoppingProvider.future);
      c.read(shoppingProvider.notifier)
        ..add(UnitItem(id: 'a', name: 'Arroz', price: Money(100)))
        ..add(molho)
        ..add(UnitItem(id: 'c', name: 'Café', price: Money(200)));
      final removal = c.read(cartRemovalProvider.notifier)..remove('m');
      expect(c.read(shoppingProvider).value!.cart.total, Money(300));
      expect(c.read(cartRemovalProvider).undo?.index, 1);
      expect(c.read(cartRemovalProvider).leaving, hasLength(1));

      removal.undo();
      final items = c.read(shoppingProvider).value!.cart.items;
      expect(items.map((i) => i.id), ['a', 'm', 'c']);
      expect(c.read(cartRemovalProvider).undo, isNull);
      expect(c.read(cartRemovalProvider).leaving, isEmpty);
      await c.read(shoppingProvider.notifier).flush();
    });
  });
}
