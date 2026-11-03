import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/money.dart';
import 'package:tino/features/shopping/domain/tag_reader.dart';

OcrLine l(String text, double top, double height) =>
    (text: text, top: top, height: height);

void main() {
  test('escolhe o preço de maior destaque e o nome acima', () {
    final r = readTag([
      l('ARROZ TIPO 1 CAMIL 5KG', 10, 20),
      l('R\$ 24,90', 40, 60),
      l('Preço por kg R\$ 4,98', 110, 14),
      l('7896006716112', 130, 12),
    ]);
    expect(r.price, Money(2490));
    expect(r.name, 'ARROZ TIPO 1 CAMIL 5KG');
    expect(r.perKg, isFalse);
  });

  test('detecta preço por quilo', () {
    final r = readTag([l('Tomate', 0, 20), l('R\$ 8,99 /kg', 30, 50)]);
    expect(r.price, Money(899));
    expect(r.perKg, isTrue);
  });

  test('com alturas parecidas, "R\$" desempata', () {
    final r = readTag([l('12,50', 0, 30), l('R\$ 9,99', 40, 30)]);
    expect(r.price, Money(999));
  });

  test('aceita milhar e ignora códigos e datas', () {
    expect(readTag([l('R\$ 1.299,00', 0, 40)]).price, Money(129900));
    final r = readTag([
      l('Validade 12.11.2026', 0, 20),
      l('7891000100103', 30, 20),
    ]);
    expect(r.price, isNull);
    expect(r.name, isNull);
  });

  test('sem texto não inventa nada', () {
    final r = readTag(const []);
    expect(r.price, isNull);
    expect(r.name, isNull);
  });

  test("estabilizador exige o mesmo preço em quadros seguidos", () {
    final s = ReadingStabilizer();
    TagReading t(int? c, [String? n]) =>
        TagReading(price: c == null ? null : Money(c), name: n);
    expect(s.add(t(1290)), isFalse);
    expect(s.add(t(1990)), isFalse);
    expect(s.add(t(null)), isFalse);
    expect(s.add(t(1990, "Café")), isTrue);
    expect(s.stable!.price, Money(1990));
    expect(s.stable!.name, "Café");
    expect(s.add(t(1990)), isFalse);
    expect(s.stable!.name, "Café");
    expect(s.add(t(899)), isFalse);
    expect(s.add(t(899)), isTrue);
    expect(s.stable!.price, Money(899));
  });
}
