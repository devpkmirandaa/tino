import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/money.dart';
import 'package:tino/features/shopping/domain/tag_reader.dart';

OcrLine l(
  String text,
  double top,
  double height, {
  double left = 0,
  double width = 300,
}) => (text: text, left: left, top: top, width: width, height: height);

void main() {
  group('readTag', () {
    test('etiqueta simples com centavos pequenos ao lado', () {
      final r = readTag([
        l('ARROZ BRANCO TIPO 1', 60, 40, width: 480),
        l('Tio João • 1 kg', 125, 24, width: 190),
        l(r'R$', 330, 26, left: 50, width: 40),
        l('6', 250, 120, left: 115, width: 90),
        l(',49', 250, 60, left: 215, width: 120),
        l('/UN', 325, 30, left: 835, width: 60),
        l('REF. 001234', 425, 18, left: 680, width: 130),
      ]);
      expect(r.price, Money(649));
      expect(r.name, 'Arroz branco tipo 1');
      expect(r.perKg, isFalse);
    });

    test('ignora faixa de oferta e preço antigo', () {
      final r = readTag([
        l('OFERTA DA SEMANA', 30, 50, width: 580),
        l('ARROZ BRANCO TIPO 1', 130, 36, width: 460),
        l('Tio João • 1 kg', 180, 22, width: 170),
        l(r'DE R$ 8,99', 235, 26, width: 170),
        l('POR', 285, 20, width: 50),
        l('6', 340, 120, left: 105, width: 90),
        l(',49', 340, 60, left: 205, width: 140),
        l(r'R$', 425, 24, left: 40, width: 40),
      ]);
      expect(r.price, Money(649));
      expect(r.name, 'Arroz branco tipo 1');
    });

    test('hortifrúti: preço por quilo e nome abaixo da faixa', () {
      final r = readTag([
        l('HORTIFRUTI', 35, 40, width: 290),
        l('ARROZ BRANCO TIPO 1', 125, 40, width: 560),
        l('Tio João • 1 kg', 190, 24, width: 190),
        l(r'R$ 6,49', 285, 120, left: 45, width: 320),
        l('/ KG', 375, 38, left: 820, width: 90),
        l('PREÇO POR QUILO', 470, 22, width: 240),
      ]);
      expect(r.price, Money(649));
      expect(r.perKg, isTrue);
      expect(r.name, 'Arroz branco tipo 1');
    });

    test('atacado: varejo como preço e atacado com mínimo', () {
      final r = readTag([
        l('ECONOMIZE NA QUANTIDADE', 35, 36, width: 600),
        l('ARROZ BRANCO TIPO 1', 115, 34, width: 440),
        l('Tio João • 1 kg', 165, 22, width: 170),
        l('VAREJO / UN', 238, 22, left: 50, width: 160),
        l(r'R$ 6,49', 305, 90, left: 50, width: 230),
        l('1 unidade', 412, 22, left: 50, width: 110),
        l('ATACADO / UN', 238, 22, left: 520, width: 180),
        l(r'R$ 5,99', 305, 90, left: 520, width: 230),
        l('A partir de 6 unidades', 412, 22, left: 520, width: 260),
      ]);
      expect(r.price, Money(649));
      expect(r.bulkPrice, Money(599));
      expect(r.bulkMin, 6);
      expect(r.priceFor(5), Money(649));
      expect(r.priceFor(6), Money(599));
      expect(r.name, 'Arroz branco tipo 1');
    });

    test('mantém nomes que começam como palavras de faixa', () {
      final r = readTag([l('Detergente Ypê', 0, 30), l(r'R$ 2,99', 40, 60)]);
      expect(r.name, 'Detergente Ypê');
    });

    test('aceita milhar e ignora códigos e datas', () {
      expect(readTag([l(r'R$ 1.299,00', 0, 40)]).price, Money(129900));
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
  });

  test('kg isolado ou "por quilo" marca peso; "1 kg" de embalagem não', () {
    final pack = readTag([
      l('Arroz Tio João 1 kg', 0, 30),
      l(r'R$ 6,49', 40, 60),
    ]);
    expect(pack.perKg, isFalse);
    final quilo = readTag([l(r'R$ 6,49', 0, 60), l('PREÇO POR QUILO', 80, 20)]);
    expect(quilo.perKg, isTrue);
    expect(readTag([l('6,49 /KG', 0, 60)]).perKg, isTrue);
  });

  test('atacado sem quantidade mínima fica disponível para escolha', () {
    final r = readTag([
      l(r'R$ 6,49', 100, 60, left: 0, width: 200),
      l('ATACADO', 60, 20, left: 400, width: 150),
      l(r'R$ 5,99', 100, 60, left: 400, width: 200),
    ]);
    expect(r.price, Money(649));
    expect(r.bulkPrice, Money(599));
    expect(r.bulkMin, isNull);
    expect(r.priceFor(10), Money(649));
  });

  // Linhas reais do Moto G54 (log tino-ocr), com a vírgula mal lida.
  test('leite: "10:77" e "9:15" viram varejo e atacado', () {
    final r = readTag([
      l('ECONOMIA NO ATACADO', 88, 28, left: 72, width: 300),
      l('LEITE INTEGRAL UHT', 126, 29, left: 73, width: 280),
      l('Piracanjuba1L', 158, 18, left: 67, width: 160),
      l('A PARTIR DE 3 UNIDADES', 198, 18, left: 322, width: 260),
      l('PREÇO UNITÁRIO', 193, 19, left: 75, width: 180),
      l('9:15', 233, 41, left: 367, width: 110),
      l('RS', 259, 17, left: 317, width: 30),
      l('10.77', 228, 52, left: 117, width: 150),
      l('RS', 257, 18, left: 78, width: 30),
    ]);
    expect(r.price, Money(1077));
    expect(r.bulkPrice, Money(915));
    expect(r.bulkMin, 3);
    expect(r.name, 'Leite integral uht');
  });

  test('"RS 915" sem vírgula ainda é preço; código não é', () {
    expect(readTag([l('RS 915', 0, 43)]).price, Money(915));
    expect(readTag([l('7891000', 0, 43)]).price, isNull);
  });

  test('vírgula torta é voto fraco', () {
    expect(readTag([l('10:77', 0, 50)]).weak, isTrue);
    expect(readTag([l(r'R$ 10,77', 0, 50)]).weak, isFalse);
  });

  test('dígito verificador: preço por kg × embalagem fecha', () {
    final ok = readTag([
      l('ARROZ TIPO 1 5KG', 0, 24),
      l(r'R$ 24,90', 40, 70),
      l(r'Preço por kg R$ 4,98', 120, 14),
    ]);
    expect(ok.checked, isTrue);
    final half = readTag([
      l('CAFÉ 500g', 0, 24),
      l(r'R$ 18,90', 40, 70),
      l(r'R$ 37,80/kg', 120, 14),
    ]);
    expect(half.checked, isTrue);
    final wrong = readTag([
      l('ARROZ TIPO 1 5KG', 0, 24),
      l(r'R$ 21,90', 40, 70),
      l(r'Preço por kg R$ 4,98', 120, 14),
    ]);
    expect(wrong.checked, isFalse);
  });

  test('preço de referência por kg não é preço nem marca peso', () {
    final r = readTag([
      l('ARROZ TIPO 1 5KG', 0, 24),
      l(r'R$ 24,90', 40, 70),
      l(r'Preço por kg R$ 4,98', 120, 14),
    ]);
    expect(r.price, Money(2490));
    expect(r.perKg, isFalse);
  });

  test('etiqueta dupla sem rótulo: o mais barato é o atacado', () {
    final r = readTag([
      l('IOGURTE NATURAL', 0, 24, width: 300),
      l(r'R$ 32,10', 60, 50, left: 420, width: 180),
      l(r'R$ 37,77', 62, 50, left: 20, width: 180),
    ]);
    expect(r.price, Money(3777));
    expect(r.bulkPrice, Money(3210));
  });

  group('ReadingConsensus', () {
    TagReading t(
      int? c, {
      String? n,
      int? bulk,
      bool kg = false,
      double s = 1,
    }) => TagReading(
      price: c == null ? null : Money(c),
      name: n,
      perKg: kg,
      bulkPrice: bulk == null ? null : Money(bulk),
      strength: s,
    );

    test('duas leituras fortes iguais já decidem', () {
      final s = ReadingConsensus()..add(t(649, s: 2));
      expect(s.stable, isNull);
      expect(s.add(t(649, s: 2)), isTrue);
      expect(s.stable!.price, Money(649));
    });

    test('votos de vírgula torta não travam sozinhos', () {
      TagReading w() => TagReading(price: Money(1077), weak: true);
      final s = ReadingConsensus();
      for (var i = 0; i < 5; i++) {
        s.add(w());
      }
      expect(s.stable, isNull);
      expect(s.provisional!.price, Money(1077));
      s.add(t(1077));
      expect(s.stable!.price, Money(1077));
      expect(s.rule, LockRule.votes);
    });

    test('dígito verificador trava com uma leitura', () {
      final s = ReadingConsensus()
        ..add(TagReading(price: Money(2490), checked: true));
      expect(s.stable!.price, Money(2490));
      expect(s.rule, LockRule.checkDigit);
    });

    test('leituras fracas travam com 3 de 5', () {
      final s = ReadingConsensus()
        ..add(t(649))
        ..add(t(null))
        ..add(t(649));
      expect(s.stable, isNull);
      s.add(t(649));
      expect(s.stable!.price, Money(649));
    });

    test('alternância solta não troca o preço confirmado', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 3; i++) {
        s.add(t(3777, s: 2));
      }
      for (final c in [3210, 3777, 3210, 3777, 3210]) {
        s.add(t(c, s: 1.5));
      }
      expect(s.stable!.price, Money(3777));
    });

    test('quadros sem atacado, nome ou kg não apagam o que foi visto', () {
      final s = ReadingConsensus()
        ..add(t(3777, n: 'Iogurte', bulk: 3210, kg: true, s: 2))
        ..add(t(3777, n: 'Iogurte', bulk: 3210, kg: true, s: 2));
      for (var i = 0; i < 10; i++) {
        s.add(t(3777, s: 2));
      }
      expect(s.stable!.bulkPrice, Money(3210));
      expect(s.stable!.name, 'Iogurte');
      expect(s.stable!.perKg, isTrue);
    });

    test('o cartão resiste a falhas curtas e some após várias', () {
      final s = ReadingConsensus()
        ..add(t(500, s: 2))
        ..add(t(500, s: 2));
      for (var i = 0; i < 7; i++) {
        s.add(t(null));
      }
      expect(s.stable, isNotNull);
      expect(s.add(t(null)), isTrue);
      expect(s.stable, isNull);
    });

    test('trocar de etiqueta leva poucos quadros', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 12; i++) {
        s.add(t(649, s: 2));
      }
      for (var i = 0; i < 5; i++) {
        s.add(t(899, s: 2));
      }
      expect(s.stable!.price, Money(899));
    });

    test('após usar, ignora o mesmo preço até a etiqueta sair', () {
      final s = ReadingConsensus()
        ..add(t(500, s: 2))
        ..add(t(500, s: 2))
        ..accept();
      for (var i = 0; i < 5; i++) {
        s.add(t(500, s: 2));
      }
      expect(s.stable, isNull);
      for (var i = 0; i < 4; i++) {
        s.add(t(null));
      }
      s
        ..add(t(500, s: 2))
        ..add(t(500, s: 2));
      expect(s.stable!.price, Money(500));
    });
  });
}
