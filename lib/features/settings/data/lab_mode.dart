import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/onboarding_preference.dart';

/// Modo laboratório (opção de desenvolvedor): o scanner também lê o QR de
/// gabarito das etiquetas de teste e registra acertos no log. Fica fora das
/// telas normais; liga e desliga com 7 toques no rodapé de Ajustes.
final labModeProvider = AsyncNotifierProvider<LabModeNotifier, bool>(
  LabModeNotifier.new,
);

class LabModeNotifier extends AsyncNotifier<bool> {
  static const key = 'lab_mode';

  @override
  Future<bool> build() async =>
      await ref.read(preferencesProvider).getBool(key) ?? false;

  Future<bool> toggle() async {
    final next = !(await future);
    await ref.read(preferencesProvider).setBool(key, next);
    state = AsyncData(next);
    return next;
  }
}
