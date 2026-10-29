import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tino_theme.dart';

class TinoShell extends StatelessWidget {
  const TinoShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (path: '/', label: 'Início', icon: LucideIcons.house),
    (path: '/listas', label: 'Listas', icon: LucideIcons.listChecks),
    (path: '/comprar', label: 'Comprar', icon: LucideIcons.scanLine),
    (path: '/historico', label: 'Histórico', icon: LucideIcons.history),
    (path: '/ajustes', label: 'Ajustes', icon: LucideIcons.settings2),
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: navigationShell.currentIndex == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && navigationShell.currentIndex != 0) {
        navigationShell.goBranch(0);
      }
    },
    child: Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: TinoColors.offWhite,
          border: Border(top: BorderSide(color: TinoColors.lightJade)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _destinations.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      label: _destinations[index].label,
                      icon: _destinations[index].icon,
                      selected: navigationShell.currentIndex == index,
                      central: index == 2,
                      onTap: () => navigationShell.goBranch(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.central,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final bool central;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? TinoColors.jade : TinoColors.ink;
    return Semantics(
      key: ValueKey('destination-$label'),
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: color, end: color),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, animatedColor, child) => Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('nav-$label'),
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(16),
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: central
                            ? Border.all(color: TinoColors.jade)
                            : null,
                      ),
                      child: Icon(icon, size: 24, color: animatedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: animatedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
