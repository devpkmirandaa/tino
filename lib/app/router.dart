import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/lists/presentation/lists_page.dart';
import '../features/onboarding/data/onboarding_preference.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shopping/presentation/shopping_page.dart';
import 'tino_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.watch(initialAccessProvider).requireValue
        ? '/'
        : '/apresentacao',
    overridePlatformDefaultLocation: true,
    routes: [
      GoRoute(
        path: '/apresentacao',
        builder: (context, state) => OnboardingPage(
          review: state.uri.queryParameters['rever'] == 'true',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            TinoShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
            // Voltar retorna ao Início antes de sair do aplicativo.
            routes: [
              GoRoute(
                path: 'listas',
                builder: (context, state) => const ListsPage(),
              ),
              GoRoute(
                path: 'comprar',
                builder: (context, state) => const ShoppingPage(),
              ),
              GoRoute(
                path: 'historico',
                builder: (context, state) => const HistoryPage(),
              ),
              GoRoute(
                path: 'ajustes',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
