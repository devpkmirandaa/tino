import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tino_theme.dart';

/// Três abas (design/specs/telas.md · Navegação): Comprar (inicial), Listas
/// e Histórico. Ajustes fica na engrenagem do Comprar.
class TinoShell extends StatelessWidget {
  const TinoShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (label: 'Comprar', icon: LucideIcons.scanLine),
    (label: 'Listas', icon: LucideIcons.listChecks),
    (label: 'Histórico', icon: LucideIcons.history),
  ];

  /// Altura da barra, incluindo a área segura de baixo.
  static const barHeight = 76.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: SafeArea(bottom: false, child: navigationShell),
        bottomNavigationBar: Container(
          constraints: BoxConstraints(
            minHeight:
                barHeight - TinoSpace.s16 + _max(bottomInset, TinoSpace.s16),
          ),
          padding: EdgeInsets.fromLTRB(
            TinoSpace.s8,
            TinoSpace.s8,
            TinoSpace.s8,
            _max(bottomInset, TinoSpace.s16),
          ),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(
              top: BorderSide(color: c.border, width: TinoSize.borderWidth),
            ),
          ),
          child: Semantics(
            container: true,
            label: 'Navegação principal',
            child: Row(
              children: [
                for (var index = 0; index < _destinations.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      label: _destinations[index].label,
                      icon: _destinations[index].icon,
                      selected: navigationShell.currentIndex == index,
                      onTap: () => navigationShell.goBranch(
                        index,
                        initialLocation: index == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _max(double a, double b) => a > b ? a : b;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final color = selected ? c.action : c.textSecondary;
    // Ativo: rótulo 600; inativo: 500. O ícone nunca preenche.
    final weight = selected ? FontWeight.w600 : FontWeight.w500;
    return Semantics(
      key: ValueKey('destination-$label'),
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: GestureDetector(
        key: ValueKey('nav-$label'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          // Só a cor muda (e interpola); o ícone nunca preenche.
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: color, end: color),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            // Área de toque ocupa a faixa da barra (76 − 8 − 16 = 52) e
            // cresce com texto ampliado; o conteúdo fica centralizado.
            builder: (context, animated, _) => ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TinoShell.barHeight - TinoSpace.s8 - TinoSpace.s16,
              ),
              child: Center(
                heightFactor: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: TinoSize.icon, color: animated),
                    const SizedBox(height: TinoSpace.s4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TinoType.caption
                          .withColor(animated ?? color)
                          .weight(weight),
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
