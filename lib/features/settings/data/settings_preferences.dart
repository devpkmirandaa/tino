import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/onboarding_preference.dart';

/// Aparência escolhida em Ajustes (design/specs/telas-complementares.md ·
/// Tema). Padrão: Automático, que segue o tema do celular.
enum Appearance {
  system,
  light,
  dark;

  /// Claro ou escuro para o tema do celular [platform].
  Brightness resolve(Brightness platform) => switch (this) {
    Appearance.system => platform,
    Appearance.light => Brightness.light,
    Appearance.dark => Brightness.dark,
  };
}

final appearanceProvider =
    AsyncNotifierProvider<AppearanceNotifier, Appearance>(
      AppearanceNotifier.new,
    );

class AppearanceNotifier extends AsyncNotifier<Appearance> {
  static const key = 'appearance';

  @override
  Future<Appearance> build() async {
    final saved = await ref.read(preferencesProvider).getString(key);
    return Appearance.values.asNameMap()[saved] ?? Appearance.system;
  }

  Future<void> set(Appearance value) async {
    // Troca na hora; gravar no aparelho não segura a tela.
    state = AsyncData(value);
    await ref.read(preferencesProvider).setString(key, value.name);
  }
}

/// Chave liga/desliga guardada no aparelho.
abstract class _SwitchPreference extends AsyncNotifier<bool> {
  String get key;
  bool get fallback => true;

  @override
  Future<bool> build() async =>
      await ref.read(preferencesProvider).getBool(key) ?? fallback;

  Future<void> set(bool value) async {
    state = AsyncData(value);
    await ref.read(preferencesProvider).setBool(key, value);
  }
}

/// "Adicionar ao travar o preço": item por unidade com nome entra sozinho.
/// Desligado, o scanner espera o toque em "Adicionar".
final autoAddProvider = AsyncNotifierProvider<AutoAddNotifier, bool>(
  AutoAddNotifier.new,
);

class AutoAddNotifier extends _SwitchPreference {
  @override
  String get key => 'scan_auto_add';
}

/// "Avisar quando faltar pouco" (folha Orçamento): o aviso de 90% inteiro,
/// faixa "Perto do limite" no Comprar e vibração. Vale para todas as
/// compras. "Passou do orçamento" não depende dela.
final nearBudgetAlertProvider =
    AsyncNotifierProvider<NearBudgetAlertNotifier, bool>(
      NearBudgetAlertNotifier.new,
    );

class NearBudgetAlertNotifier extends _SwitchPreference {
  @override
  String get key => 'budget_near_alert';
}

/// "Vibrar ao ler": vibração quando o item lido entra no carrinho.
final vibrateOnReadProvider =
    AsyncNotifierProvider<VibrateOnReadNotifier, bool>(
      VibrateOnReadNotifier.new,
    );

class VibrateOnReadNotifier extends _SwitchPreference {
  @override
  String get key => 'scan_vibrate';
}
