import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/lab_answer.dart';
import 'package:tino/features/shopping/domain/money.dart';
import 'package:tino/features/shopping/domain/tag_reader.dart';

void main() {
  test('lê o QR de gabarito com e sem atacado', () {
    final a = LabAnswer.parse('TINO1|id=7|p=19,11|a=16,24|m=3|kg=0|c=atacado')!;
    expect(a.id, '7');
    expect(a.price, Money(1911));
    expect(a.bulkPrice, Money(1624));
    expect(a.bulkMin, 3);
    expect(a.perKg, isFalse);
    expect(a.scenario, 'atacado');

    final kg = LabAnswer.parse('TINO1|id=8|p=35.11|a=|m=|kg=1|c=hortifruti')!;
    expect(kg.price, Money(3511));
    expect(kg.bulkPrice, isNull);
    expect(kg.bulkMin, isNull);
    expect(kg.perKg, isTrue);

    expect(LabAnswer.parse('https://exemplo.com'), isNull);
    expect(LabAnswer.parse('TINO1|id=9|p=|c=x'), isNull);
  });

  test('compara campo a campo', () {
    final a = LabAnswer.parse('TINO1|id=7|p=19,11|a=16,24|m=3|kg=0|c=atacado')!;
    final c = a.check(
      TagReading(price: Money(1911), bulkPrice: Money(1624), bulkMin: 6),
    );
    expect(c.price, isTrue);
    expect(c.bulk, isTrue);
    expect(c.min, isFalse);
    expect(c.kg, isTrue);
  });

  test('resumo traz erro, cobertura e mediana por cenário', () {
    final r = LabReport();
    final a = LabAnswer.parse('TINO1|id=1|p=1,00|a=|m=|kg=0|c=simples')!;
    final b = LabAnswer.parse('TINO1|id=2|p=2,00|a=|m=|kg=0|c=simples')!;
    final c = LabAnswer.parse('TINO1|id=3|p=3,00|a=|m=|kg=1|c=kg')!;
    r
      ..saw(c)
      ..lock(a, TagReading(price: Money(100)), 300)
      ..lock(b, TagReading(price: Money(201)), 900)
      ..lock(a, TagReading(price: Money(100)), 500);
    expect(r.summary(), [
      'kg: erro - (0/0) | cobertura 0% (0/1) | mediana -',
      'simples: erro 33.3% (1/3) | cobertura 100% (2/2) | mediana 500ms',
      'TOTAL: erro 33.3% (1/3) | cobertura 67% (2/3) | mediana 500ms',
    ]);
  });
}
