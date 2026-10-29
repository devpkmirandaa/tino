import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final onboardingPreferenceProvider = Provider<OnboardingPreference>(
  (ref) => OnboardingPreference(ref.watch(preferencesProvider)),
);

// Lido uma vez por abertura. Concluir não recria o roteador durante a navegação.
final initialAccessProvider = FutureProvider<bool>(
  (ref) => ref.watch(onboardingPreferenceProvider).hasSeen(),
);

class OnboardingPreference {
  OnboardingPreference(this._preferences);

  final SharedPreferencesAsync _preferences;
  // Não vincular à versão do app: atualizações comuns preservam a escolha.
  static const seenKey = 'onboarding_seen';

  Future<bool> hasSeen() async => await _preferences.getBool(seenKey) ?? false;

  Future<void> markSeen() => _preferences.setBool(seenKey, true);
}
