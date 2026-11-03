/// Valor monetário em centavos inteiros; nunca usa ponto flutuante.
extension type const Money(int cents) {
  static const zero = Money(0);

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator *(int factor) => Money(cents * factor);
  bool operator >(Money other) => cents > other.cents;

  /// Preço de [grams] gramas a [perKg] por kg, arredondado meio para cima.
  static Money byWeight(Money perKg, int grams) {
    if (perKg.cents < 0 || grams < 0) throw ArgumentError('Valor negativo');
    return Money((perKg.cents * grams + 500) ~/ 1000);
  }

  /// Formato brasileiro: R$ 1.234,56.
  String format() {
    final abs = cents.abs();
    final reais = (abs ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+$)'),
      (_) => '.',
    );
    final centavos = (abs % 100).toString().padLeft(2, '0');
    return '${cents < 0 ? '-' : ''}R\$ $reais,$centavos';
  }
}
