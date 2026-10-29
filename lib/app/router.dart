import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/lists/presentation/lists_page.dart';
import '../features/onboarding/data/onboarding_preference.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/settings/presentation/settings_page.dart';
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
      StatefulShellRoute(
        pageBuilder: (context, state, shell) =>
            _fadePage(state, TinoShell(navigationShell: shell)),
        navigatorContainerBuilder: (context, shell, children) =>
            AreaContent(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomePage(),
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/comprar',
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
                path: '/historico',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HistoryPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ajustes',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SettingsPage(),
                ),
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
