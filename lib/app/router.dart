import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_page.dart';
import '../features/history/presentation/purchase_detail_page.dart';
import '../features/lists/presentation/list_detail_page.dart';
import '../features/lists/presentation/lists_page.dart';
import '../features/onboarding/data/onboarding_preference.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shopping/presentation/scanner_route.dart';
import '../features/shopping/presentation/shopping_page.dart';
import 'area_content.dart';
import 'tino_shell.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          MediaQuery.disableAnimationsOf(context)
          ? child
          : FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
              child: child,
            ),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.watch(initialAccessProvider).requireValue
        ? '/'
        : '/apresentacao',
    overridePlatformDefaultLocation: true,
    routes: [
      GoRoute(
        path: '/apresentacao',
        pageBuilder: (context, state) => _fadePage(
          state,
          OnboardingPage(review: state.uri.queryParameters['rever'] == 'true'),
        ),
      ),
      GoRoute(
        path: '/escanear',
        pageBuilder: (context, state) => scannerPage(state),
      ),
      GoRoute(
        path: '/ajustes',
        pageBuilder: (context, state) =>
            _fadePage(state, const SettingsScreen()),
      ),
      // Endereço antigo da aba Comprar, que agora é a inicial.
      GoRoute(path: '/comprar', redirect: (context, state) => '/'),
      StatefulShellRoute(
        pageBuilder: (context, state, shell) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          child: TinoShell(navigationShell: shell),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              ScannerBackdrop(
                animation: secondaryAnimation,
                child: MediaQuery.disableAnimationsOf(context)
                    ? child
                    : FadeTransition(
                        opacity: animation.drive(
                          CurveTween(curve: Curves.easeOutCubic),
                        ),
                        child: child,
                      ),
              ),
        ),
        navigatorContainerBuilder: (context, shell, children) =>
            AreaContent(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ShoppingPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/listas',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ListsPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: ListDetailPage(
                        id: int.tryParse(state.pathParameters['id']!) ?? -1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/historico',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HistoryPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: PurchaseDetailPage(
                        id: int.tryParse(state.pathParameters['id']!) ?? -1,
                      ),
                    ),
                  ),
                ],
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
