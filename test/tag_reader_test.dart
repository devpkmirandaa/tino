import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/money.dart';
import 'package:tino/features/shopping/domain/tag_reader.dart';

OcrLine l(
  String text,
  double top,
  double height, {
  double left = 0,
  double width = 300,
  List<({double top, double bottom})> glyphs = const [],
}) => (
  text: text,
  left: left,
  top: top,
  width: width,
  height: height,
  glyphs: glyphs,
);

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

    group('linha do atacado não vira nome', () {
      // Duas colunas; a linha do atacado é mais alta que o nome do produto.
      TagReading twoColumns(String bulkLine, {double nameTop = 40}) => readTag([
        l('MOLHO DE TOMATE QUERO', nameTop, 26, width: 380),
        l(bulkLine, 150, 34, left: 420, width: 300),
        l(r'R$ 3,49', 220, 90, left: 40, width: 230),
        l(r'R$ 2,99', 220, 90, left: 420, width: 230),
      ]);

      test('"A PARTIR DE 10 UN"', () {
        final r = twoColumns('A PARTIR DE 10 UN');
        expect(r.name, 'Molho de tomate quero');
        expect(r.tagText, 'MOLHO DE TOMATE QUERO');
        expect(r.price, Money(349));
        expect(r.bulkPrice, Money(299));
        expect(r.bulkMin, 10);
      });

      test('"PARTIR DE 10 UN", com o "A" perdido pelo OCR', () {
        final r = twoColumns('PARTIR DE 10 UN');
        expect(r.name, 'Molho de tomate quero');
        expect(r.price, Money(349));
        expect(r.bulkPrice, Money(299));
      });

      test('nome abaixo da linha do atacado', () {
        final r = twoColumns('10 UN A PARTIR DE', nameTop: 190);
        expect(r.name, 'Molho de tomate quero');
        expect(r.price, Money(349));
      });
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

  group('região do preço', () {
    test('cobre preço e atacado com margem, dentro da moldura', () {
      final r = readTag([
        l('ARROZ', 0, 30, width: 200),
        l(r'R$ 6,49', 100, 60, left: 20, width: 200),
        l('ATACADO', 60, 20, left: 400, width: 150),
        l(r'R$ 5,99', 100, 60, left: 400, width: 200),
      ]);
      final box = priceRegion(r, 700, 300)!;
      expect(box.left, 0); // 20 - (60 + 72) passa da borda
      expect(box.top, 70); // 100 - 30
      expect(box.left + box.width, 700);
      expect(box.top + box.height, 190); // 160 + 30
    });

    test(
      'sem segundo preço numa etiqueta de atacado, lê a moldura inteira',
      () {
        final r = readTag([
          l('ATACADO', 60, 20, left: 400, width: 150),
          l(r'R$ 5,99', 100, 60, left: 400, width: 200),
        ]);
        expect(priceRegion(r, 700, 300), isNull);
        expect(priceRegion(const TagReading(), 700, 300), isNull);
      },
    );

    test('no recorte, número sem vírgula vale como voto de repetição', () {
      final r = readTag([l('3511', 30, 70)], region: true);
      expect(r.price, Money(3511));
      expect(r.glued, isTrue);
      expect(r.partial, isTrue);
    });
  });

  test('hortifrúti real: sujeira antes do preço e parte inteira com ":"', () {
    expect(readTag([l('-26:74', 102, 59)]).price, Money(2674));
    expect(readTag([l('„26.74', 93, 61)]).price, Money(2674));
    expect(readTag([l('-27.57', 47, 91)]).price, Money(2757));
    final split = readTag([
      l('BANANA', 0, 25, left: 87),
      l('I KG', 95, 24, left: 444, width: 40),
      l('57', 54, 55, left: 241, width: 60),
      l('.27:', 59, 78, left: 88, width: 140),
    ]);
    expect(split.price, Money(2757));
    expect(split.kgOnPrice, isTrue);
  });

  test('R1D8IS: "VAREJO" escrito marca cara de atacado', () {
    final r = readTag([
      l('VAREJO I UN', 40, 22, left: 73, width: 150),
      l('5.02', 63, 49, left: 119, width: 120),
      l(r'R$', 98, 15, left: 76, width: 30),
    ]);
    expect(r.price, Money(502));
    expect(r.bulkHint, isTrue);
  });

  test('"ATACADO" escrito com um preço só marca cara de atacado', () {
    final r = readTag([
      l('ATACADO', 60, 20, left: 400, width: 150),
      l(r'R$ 5,99', 100, 60, left: 400, width: 200),
    ]);
    expect(r.price, Money(599));
    expect(r.bulkHint, isTrue);
    expect(r.where, (x: 500.0, y: 130.0, h: 60.0));
    expect(readTag([l(r'R$ 5,99', 100, 60)]).bulkHint, isFalse);
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
    expect(r.name, 'Leite integral UHT');
  });

  test('hortifrúti real: tomate R\$ 35,11/kg', () {
    final r = readTag([
      l('HORTIFRUTI', 94, 28, left: 96, width: 200),
      l('TOMATE SALADA', 132, 34, left: 94, width: 260),
      l('Fresco a granel', 169, 19, left: 96, width: 150),
      l('I', 253, 20, left: 472, width: 8),
      l('KG', 252, 20, left: 488, width: 30),
      l('35,11', 203, 73, left: 161, width: 220),
      l(r'R$', 261, 17, left: 105, width: 30),
      l('PREÇO POR QUILO', 300, 19, left: 104, width: 200),
    ]);
    expect(r.price, Money(3511));
    expect(r.perKg, isTrue);
    expect(r.name, 'Tomate salada');
  });

  test('"35 11" em elementos separados é leitura firme', () {
    final spaced = readTag([l('35 11', 0, 70)]);
    expect(spaced.price, Money(3511));
    expect(spaced.weak, isFalse);
  });

  test('"3511" sozinho na linha do preço é voto fraco de repetição', () {
    final withCurrency = readTag([
      l('3511', 200, 73, left: 160, width: 220),
      l(r'R$', 258, 17, left: 105, width: 30),
    ]);
    expect(withCurrency.price, Money(3511));
    expect(withCurrency.weak, isTrue);
    expect(withCurrency.glued, isTrue);
    // Log real: ".3511" sem R$, mas é a linha de maior destaque.
    final dominant = readTag([
      l('TOMATE SALADA', 112, 30, left: 136),
      l('Frescoa granel', 144, 17, left: 136),
      l('.3511', 141, 74, left: 130),
      l('PREÇO POR QUILO', 229, 19, left: 131),
    ]);
    expect(dominant.price, Money(3511));
    expect(dominant.glued, isTrue);
    expect(readTag([l('3511', 200, 73)]).price, isNull);
    expect(readTag([l('.35.11', 200, 73)]).price, Money(3511));
  });

  ({double top, double bottom}) g(double top, double bottom) =>
      (top: top, bottom: bottom);

  test('centavos sobrescritos: menores ou com a base mais alta', () {
    final shorter = readTag([
      l('TOMATE SALADA', 121, 26, left: 98),
      l(
        '3511',
        185,
        68,
        left: 151,
        width: 220,
        glyphs: [g(185, 253), g(185, 251), g(185, 219), g(185, 218)],
      ),
      l('PREÇO POR QUILO', 275, 16, left: 99),
    ]);
    expect(shorter.price, Money(3511));
    expect(shorter.weak, isFalse);
    expect(shorter.strength, 2);
    // Mesma altura, mas topo alinhado e base bem mais alta.
    final raised = readTag([
      l(
        '3511',
        185,
        68,
        glyphs: [g(185, 253), g(185, 253), g(185, 235), g(186, 236)],
      ),
    ]);
    expect(raised.price, Money(3511));
    // Tudo na mesma linha de base: não prova centavos.
    final even = readTag([
      l(
        '3511',
        185,
        68,
        glyphs: [g(185, 253), g(185, 253), g(186, 252), g(185, 253)],
      ),
    ]);
    expect(even.price, isNull);
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

    test('quadros sem preço não ocupam a janela de votos', () {
      final s = ReadingConsensus();
      for (final c in [3511, null, null, 3511, null, null, null, 3511]) {
        s.add(t(c));
      }
      expect(s.stable!.price, Money(3511));
    });

    test('mesmo número sem vírgula em 3 quadros trava por repetição', () {
      TagReading glued() =>
          TagReading(price: Money(3511), weak: true, glued: true);
      final s = ReadingConsensus()
        ..add(glued())
        ..add(glued());
      expect(s.stable, isNull);
      s.add(glued());
      expect(s.stable!.price, Money(3511));
      expect(s.rule, LockRule.repeated);
    });

    test('vírgula torta repetida igual em 3 quadros trava', () {
      final torta = readTag([l('7.63', 0, 60)]);
      expect(torta.weak, isTrue);
      expect(torta.glued, isTrue);
      final s = ReadingConsensus()
        ..add(torta)
        ..add(torta);
      expect(s.stable, isNull);
      s.add(torta);
      expect(s.stable!.price, Money(763));
      expect(s.rule, LockRule.repeated);
    });

    TagReading at(int c, double x, {int? bulk, bool hint = false}) =>
        TagReading(
          price: Money(c),
          bulkPrice: bulk == null ? null : Money(bulk),
          strength: 2,
          where: (x: x, y: 100, h: 50),
          bulkHint: hint,
        );

    test('troca de etiqueta: corte na imagem + 2 quadros com preço novo', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 5; i++) {
        s.add(at(2872, 200));
      }
      s.add(at(1608, 200), cut: true);
      expect(s.stable!.price, Money(2872));
      expect(s.switched, isFalse);
      s.add(at(1608, 200));
      expect(s.switched, isTrue);
      expect(s.stable!.price, Money(1608));
    });

    test('sem corte, o preço novo não derruba o travado tão cedo', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 5; i++) {
        s.add(at(2872, 200));
      }
      s
        ..add(at(1608, 200))
        ..add(at(1608, 200));
      expect(s.switched, isFalse);
      expect(s.stable!.price, Money(2872));
    });

    test('preço pulando de lugar também conta como troca', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 5; i++) {
        s.add(at(2872, 100));
      }
      s
        ..add(at(1608, 400))
        ..add(at(1608, 400));
      expect(s.switched, isTrue);
      expect(s.stable!.price, Money(1608));
    });

    test('o atacado da mesma etiqueta não é troca', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 3; i++) {
        s.add(at(649, 100, bulk: 599));
      }
      s
        ..add(at(599, 400), cut: true)
        ..add(at(599, 400));
      expect(s.switched, isFalse);
      expect(s.stable!.price, Money(649));
    });

    test('cara de atacado com um preço só espera o segundo preço', () {
      final s = ReadingConsensus()
        ..add(at(599, 400, hint: true))
        ..add(at(599, 400, hint: true));
      expect(s.stable, isNull);
      s
        ..add(at(649, 100, bulk: 599, hint: true))
        ..add(at(649, 100, bulk: 599, hint: true));
      expect(s.stable!.price, Money(649));
      expect(s.stable!.bulkPrice, Money(599));
    });

    test('sem segundo preço, aceita o único depois de alguns quadros', () {
      final s = ReadingConsensus();
      for (var i = 0; i < 1 + ReadingConsensus.hintFrames; i++) {
        s.add(at(599, 400, hint: true));
      }
      expect(s.stable, isNull);
      s.add(at(599, 400, hint: true));
      expect(s.stable!.price, Money(599));
    });

    test('kg: 2 quadros, ou 1 se estava na linha do preço', () {
      final once = ReadingConsensus()
        ..add(TagReading(price: Money(3156), perKg: true, strength: 2))
        ..add(TagReading(price: Money(3156), strength: 2, partial: true));
      expect(once.stable!.perKg, isFalse);
      final onLine = ReadingConsensus()
        ..add(
          TagReading(
            price: Money(3511),
            perKg: true,
            kgOnPrice: true,
            strength: 2,
          ),
        )
        ..add(TagReading(price: Money(3511), strength: 2, partial: true));
      expect(onLine.stable!.perKg, isTrue);
    });

    test('nome vence por votos entre quadros', () {
      final s = ReadingConsensus()
        ..add(t(500, n: 'Leite integral', s: 2))
        ..add(t(500, n: 'Leito integral', s: 2))
        ..add(t(500, n: 'Leite integral', s: 2));
      expect(s.stable!.name, 'Leite integral');
    });

    test('dígito verificador trava com uma leitura', () {
      final s = ReadingConsensus()
        ..add(TagReading(price: Money(2490), checked: true));
      expect(s.stable!.price, Money(2490));
      expect(s.rule, LockRule.checkDigit);
    });

    test('duas leituras firmes comuns seguidas travam pelo atalho', () {
      final s = ReadingConsensus()..add(t(649));
      expect(s.stable, isNull);
      s
        ..add(t(null))
        ..add(t(649));
      expect(s.stable!.price, Money(649));
      expect(s.rule, LockRule.shortcut);
    });

    test('leitura errada isolada não trava', () {
      final s = ReadingConsensus()
        ..add(t(649))
        ..add(t(9635))
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
      // Leitura errada isolada no meio não libera o preço já usado.
      s
        ..add(t(9635))
        ..add(t(500, s: 2))
        ..add(t(500, s: 2));
      expect(s.stable, isNull);
      // Poucos quadros sem preço também não: a etiqueta não saiu.
      for (var i = 0; i < 4; i++) {
        s.add(t(null));
      }
      s
        ..add(t(500, s: 2))
        ..add(t(500, s: 2));
      expect(s.stable, isNull);
      expect(s.ignores(Money(500)), isTrue);
      // Saiu da câmera (8 quadros sem preço): volta a valer.
      for (var i = 0; i < 8; i++) {
        s.add(t(null));
      }
      s
        ..add(t(500, s: 2))
        ..add(t(500, s: 2));
      expect(s.stable!.price, Money(500));
    });

    test('após usar, troca de etiqueta libera o preço usado', () {
      final s = ReadingConsensus()
        ..add(t(500, s: 2))
        ..add(t(500, s: 2))
        ..accept()
        ..add(t(700, s: 2), cut: true)
        ..add(t(700, s: 2));
      expect(s.stable!.price, Money(700));
    });
  });
}
