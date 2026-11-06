import 'dart:async';

import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';
import '../theme/tino_theme.dart';
import 'tino_sheet_scope.dart';

/// Regras do M5 (design/motion/motion.md).
abstract final class TinoSheetMotion {
  /// Opacidade máxima do `scrim`.
  static const scrimOpacity = 0.5;

  /// Fecha ao soltar depois de descer mais que esta fração da altura...
  static const dismissFraction = 0.3;

  /// ...ou com velocidade pra baixo acima desta (px/s).
  static const dismissVelocity = 800.0;

  /// Arrastar pra cima: deslocamento × 0,3.
  static const upResistance = 0.3;

  /// Cascata do conteúdo: cada bloco sobe deste deslocamento (px).
  static const blockOffset = 24.0;
}

/// Abre uma folha (M5): sobe com a mola `folha`, `scrim` a 0,5, tela de trás
/// recua se houver um [TinoSheetScope] acima de [context], e os [blocks]
/// entram em cascata (y 24 → 0 + opacidade, 60 ms, mola `cartao`).
Future<T?> showTinoSheet<T>(
  BuildContext context, {
  required List<Widget> blocks,
  String barrierLabel = 'Fechar',
}) {
  final navigator = Navigator.of(context);
  return navigator.push(
    _TinoSheetRoute<T>(
      blocks: blocks,
      backdrop: TinoSheetScope.maybeProgressOf(context),
      barrierLabel: barrierLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    ),
  );
}

class _TinoSheetRoute<T> extends PopupRoute<T> {
  _TinoSheetRoute({
    required this.blocks,
    required this.backdrop,
    required this.barrierLabel,
    required this.themes,
  });

  final List<Widget> blocks;
  final TinoSheetBackdrop? backdrop;
  final CapturedThemes themes;

  @override
  final String barrierLabel;

  /// Velocidade do dedo ao soltar, em fração da altura por segundo.
  double _releaseVelocity = 0;

  /// Deslocamento extra pra cima (px), com resistência.
  AnimationController get lift => _lift!;
  AnimationController? _lift;

  bool get reduced =>
      MediaQuery.maybeDisableAnimationsOf(navigator!.context) ?? false;

  @override
  Color? get barrierColor => null; // O scrim acompanha a folha, ver build.

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => TinoMotion.reducedFade;

  @override
  Simulation? createSimulation({required bool forward}) {
    if (reduced) return null;
    final value = controller!.value;
    final velocity = _releaseVelocity;
    _releaseVelocity = 0;
    return TinoMotion.spring(
      TinoSprings.folha,
      value,
      forward ? 1 : 0,
      velocity,
    );
  }

  @override
  void install() {
    super.install();
    _lift = AnimationController.unbounded(vsync: navigator!);
    animation!.addListener(_syncBackdrop);
  }

  void _syncBackdrop() {
    if (!reduced) backdrop?.update(animation!.value);
  }

  @override
  void dispose() {
    animation?.removeListener(_syncBackdrop);
    backdrop?.update(0);
    _lift?.dispose();
    super.dispose();
  }

  void dragUpdate(double deltaPx, double height) {
    if (!isCurrent || height <= 0) return;
    final c = controller!;
    if ((deltaPx < 0 && c.value >= 1) || lift.value > 0) {
      lift.value = (lift.value - deltaPx * TinoSheetMotion.upResistance).clamp(
        0.0,
        double.infinity,
      );
      return;
    }
    c.value = (c.value - deltaPx / height).clamp(0.0, 1.0);
  }

  void dragEnd(double velocityPx, double height) {
    if (!isCurrent || height <= 0) return;
    lift.animateWith(TinoMotion.spring(TinoSprings.folha, lift.value, 0, 0));
    final c = controller!;
    final travelled = 1 - c.value;
    if (travelled > TinoSheetMotion.dismissFraction ||
        velocityPx > TinoSheetMotion.dismissVelocity) {
      _releaseVelocity = -velocityPx / height;
      navigator!.pop();
      return;
    }
    c.animateWith(
      TinoMotion.spring(TinoSprings.folha, c.value, 1, -velocityPx / height),
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(_TinoSheetFrame(route: this));
}

class _TinoSheetFrame extends StatefulWidget {
  const _TinoSheetFrame({required this.route});

  final _TinoSheetRoute<dynamic> route;

  @override
  State<_TinoSheetFrame> createState() => _TinoSheetFrameState();
}

class _TinoSheetFrameState extends State<_TinoSheetFrame> {
  final _sheet = GlobalKey();

  double get _height => _sheet.currentContext?.size?.height ?? 0;

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final animation = route.animation!;
    final c = context.tino;
    final media = MediaQuery.of(context);
    final reduced = route.reduced;

    final sheet = Container(
      key: _sheet,
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TinoRadius.panel),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: TinoSpace.s12,
                bottom: TinoSpace.s8,
              ),
              child: Center(
                child: Container(
                  key: const ValueKey('tino-sheet-handle'),
                  width: 40,
                  height: TinoSpace.s4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(TinoRadius.pill),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  TinoSpace.s16,
                  TinoSpace.s8,
                  TinoSpace.s16,
                  TinoSpace.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < route.blocks.length; i++) ...[
                      if (i > 0) const SizedBox(height: TinoSpace.s16),
                      _CascadeBlock(
                        index: i,
                        reduced: reduced,
                        child: route.blocks[i],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final draggable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => route.dragUpdate(d.delta.dy, _height),
      onVerticalDragEnd: (d) =>
          route.dragEnd(d.velocity.pixelsPerSecond.dy, _height),
      onVerticalDragCancel: () => route.dragEnd(0, _height),
      child: sheet,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => ColoredBox(
                color: c.scrim.withValues(
                  alpha:
                      TinoSheetMotion.scrimOpacity *
                      animation.value.clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            // Teclado: a folha acompanha o inset do sistema quadro a quadro.
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: RepaintBoundary(
              child: reduced
                  ? FadeTransition(opacity: animation, child: draggable)
                  : AnimatedBuilder(
                      animation: Listenable.merge([animation, route.lift]),
                      child: draggable,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -route.lift.value),
                        child: FractionalTranslation(
                          translation: Offset(0, 1 - animation.value),
                          child: child,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bloco da cascata: y 24 → 0 com `cartao` e opacidade com ease-out,
/// começando [index] × 60 ms depois. Movimento reduzido: só opacidade 150 ms.
class _CascadeBlock extends StatefulWidget {
  const _CascadeBlock({
    required this.index,
    required this.reduced,
    required this.child,
  });

  final int index;
  final bool reduced;
  final Widget child;

  @override
  State<_CascadeBlock> createState() => _CascadeBlockState();
}

class _CascadeBlockState extends State<_CascadeBlock>
    with TickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 200);

  late final _rise = AnimationController.unbounded(vsync: this, value: 0);
  late final _fade = AnimationController(
    vsync: this,
    duration: widget.reduced ? TinoMotion.reducedFade : _fadeDuration,
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(TinoMotion.stagger * widget.index, () {
      _fade.forward();
      if (widget.reduced) {
        _rise.value = 1;
      } else {
        _rise.animateWith(TinoMotion.spring(TinoSprings.cartao, 0, 1, 0));
      }
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _rise.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: _fade, curve: TinoCurves.easeOut),
    child: AnimatedBuilder(
      animation: _rise,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, TinoSheetMotion.blockOffset * (1 - _rise.value)),
        child: child,
      ),
    ),
  );
}
