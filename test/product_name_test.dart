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

  test('marca ou palavra desconhecida fica como foi lida', () {
    expect(tidyProductName('Detergente Ypê'), 'Detergente Ypê');
    expect(tidyProductName('Chocolate Lacta'), 'Chocolate Lacta');
    expect(tidyProductName('Sabonete Dove'), 'Sabonete Dove');
    expect(tidyProductName('Biscoito Xyzwk'), 'Biscoito Xyzwk');
  });
}
