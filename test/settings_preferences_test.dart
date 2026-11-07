import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Mock oficial do shared_preferences para testes (vem junto do pacote).
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tino/features/settings/data/settings_preferences.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('aparência resolve claro ou escuro a partir do celular', () {
    for (final platform in Brightness.values) {
      expect(Appearance.system.resolve(platform), platform);
      expect(Appearance.light.resolve(platform), Brightness.light);
      expect(Appearance.dark.resolve(platform), Brightness.dark);
    }
  });

  test('padrão é Automático e a escolha fica guardada', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    expect(await first.read(appearanceProvider.future), Appearance.system);
    await first.read(appearanceProvider.notifier).set(Appearance.dark);
    expect(first.read(appearanceProvider).value, Appearance.dark);

    // Nova abertura do app lê o que foi gravado.
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(await second.read(appearanceProvider.future), Appearance.dark);
  });

  test('chaves da compra começam ligadas e guardam o desligado', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    expect(await first.read(autoAddProvider.future), isTrue);
    expect(await first.read(vibrateOnReadProvider.future), isTrue);
    await first.read(autoAddProvider.notifier).set(false);

    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(await second.read(autoAddProvider.future), isFalse);
    expect(await second.read(vibrateOnReadProvider.future), isTrue);
  });
}
