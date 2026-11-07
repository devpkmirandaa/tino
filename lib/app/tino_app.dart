import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tino_theme.dart';
import '../features/lists/application/list_shopping_link.dart';
import '../features/lists/presentation/list_feedback_listener.dart';
import '../features/onboarding/data/onboarding_preference.dart';
import '../features/settings/data/settings_preferences.dart';
import 'router.dart';

class TinoApp extends ConsumerWidget {
  const TinoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(initialAccessProvider);
    final appearance = ref.watch(appearanceProvider);
    final themeMode = _themeMode(appearance.value ?? Appearance.system);
    // Risca na lista o que entra no carrinho de uma compra com lista.
    ref.watch(listShoppingLinkProvider);
    // Espera a aparência para não piscar o tema do celular antes da escolha.
    if (!access.hasValue || appearance.isLoading) {
      return MaterialApp(
        title: 'Tino',
        debugShowCheckedModeBanner: false,
        theme: buildTinoLightTheme(),
        darkTheme: buildTinoTheme(Brightness.dark),
        themeMode: themeMode,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: access.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Não foi possível abrir o Tino. Tente novamente.',
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () =>
                                ref.invalidate(initialAccessProvider),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        semanticsLabel: 'Abrindo o Tino',
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Tino',
      debugShowCheckedModeBanner: false,
      theme: buildTinoLightTheme(),
      darkTheme: buildTinoTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          ListFeedbackListener(child: child ?? const SizedBox.shrink()),
    );
  }

  static ThemeMode _themeMode(Appearance appearance) => switch (appearance) {
    Appearance.system => ThemeMode.system,
    Appearance.light => ThemeMode.light,
    Appearance.dark => ThemeMode.dark,
  };
}
