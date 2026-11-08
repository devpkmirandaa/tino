/// Tempo sem nenhum preço no scanner, para "Não deu pra ler o preço. Quer
/// digitar?" (design/telas/03c). Recomeça ao abrir a câmera, quando aparece
/// qualquer preço (provisório ou travado), quando um item entra, no
/// Desfazer e no "Continuar tentando".
class NoReadClock {
  NoReadClock({this.after = const Duration(seconds: 8)});

  final Duration after;
  DateTime? _since;

  /// Começa (ou recomeça) a contar agora.
  void restart(DateTime now) => _since = now;

  /// Para de contar (câmera fechada).
  void stop() => _since = null;

  /// Passou [after] desde o último recomeço.
  bool isDue(DateTime now) {
    final since = _since;
    return since != null && now.difference(since) >= after;
  }
}
