import 'package:flutter_test/flutter_test.dart';
import 'package:tino/features/shopping/domain/product_name.dart';

void main() {
  test('maiúsculas viram "Leite integral UHT" com siglas e unidades', () {
    expect(tidyProductName('LEITE INTEGRAL UHT'), 'Leite integral UHT');
    expect(tidyProductName('ÓLEO DE SOJA 900ML'), 'Óleo de soja 900ML');
    expect(tidyProductName('ARROZ TIPO 1 5KG'), 'Arroz tipo 1 5KG');
    expect(tidyProductName('REFRIGERANTE 2 L'), 'Refrigerante 2 L');
  });

  test('corrige palavra quase igual e devolve acentos', () {
    expect(tidyProductName('LEITE INTEGRAI UHT'), 'Leite integral UHT');
    expect(tidyProductName('ACUCAR REFINADO'), 'Açúcar refinado');
    expect(tidyProductName('Detergnete Ypê'), 'Detergente Ypê');
  });

  test('0 e 1 entre letras viram O e I', () {
    expect(tidyProductName('I0GURTE NATURAL'), 'Iogurte natural');
    expect(tidyProductName('ÓLEO DE S0JA'), 'Óleo de soja');
    expect(tidyProductName('LE1TE'), 'Leite');
    expect(tidyProductName('ARROZ TIPO 1 5KG'), 'Arroz tipo 1 5KG');
  });

  test('marca ou palavra desconhecida fica como foi lida', () {
    expect(tidyProductName('Detergente Ypê'), 'Detergente Ypê');
    expect(tidyProductName('Chocolate Lacta'), 'Chocolate Lacta');
    expect(tidyProductName('Sabonete Dove'), 'Sabonete Dove');
    expect(tidyProductName('Biscoito Xyzwk'), 'Biscoito Xyzwk');
  });
}
