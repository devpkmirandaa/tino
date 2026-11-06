import 'package:flutter/widgets.dart';

import '../theme/tino_theme.dart';

/// Tela de trás das folhas (M5): escala 1 → 0,94 e cantos 0 → 24
/// (`radius-panel`) junto com o progresso da folha, com `scrim` atrás.
///
/// Envolva o conteúdo da página (não o Navigator): a folha vive no overlay
/// do Navigator e não pode ser escalada junto.
class TinoSheetScope extends StatefulWidget {
  const TinoSheetScope({super.key, required this.child});

  final Widget child;

  /// Escala mínima da tela de trás.
  static const recede = 0.94;

  static TinoSheetBackdrop? maybeProgressOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetScopeData>()?.progress;

  @override
  State<TinoSheetScope> createState() => _TinoSheetScopeState();
}

class _TinoSheetScopeState extends State<TinoSheetScope> {
  final _progress = TinoSheetBackdrop();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return _SheetScopeData(
      progress: _progress,
      child: ColoredBox(
        color: c.scrim,
        child: ValueListenableBuilder<double>(
          valueListenable: _progress,
          child: widget.child,
          builder: (context, value, child) {
            final p = value.clamp(0.0, 1.0);
            // Estrutura fixa: trocar a árvore perderia o estado da página.
            return Transform.scale(
              scale: 1 - (1 - TinoSheetScope.recede) * p,
              child: ClipRRect(
                key: const ValueKey('tino-sheet-scope-clip'),
                clipBehavior: p > 0 ? Clip.antiAlias : Clip.none,
                borderRadius: BorderRadius.circular(TinoRadius.panel * p),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SheetScopeData extends InheritedWidget {
  const _SheetScopeData({required this.progress, required super.child});

  final TinoSheetBackdrop progress;

  @override
  bool updateShouldNotify(_SheetScopeData oldWidget) =>
      progress != oldWidget.progress;
}

/// Progresso da folha aberta (0 a 1), lido pela tela de trás. Ignora
/// atualizações depois de descartado: a página pode sair antes da folha.
class TinoSheetBackdrop extends ValueNotifier<double> {
  TinoSheetBackdrop() : super(0);

  bool _disposed = false;

  void update(double progress) {
    if (!_disposed) value = progress;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
