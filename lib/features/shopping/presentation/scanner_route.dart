import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import 'scanner_page.dart';

/// Retângulo do botão "Escanear preço" (coordenadas da tela), de onde o
/// scanner cresce e pra onde volta (M2). Vale do toque até o scanner fechar.
abstract final class ScannerOrigin {
  static Rect? rect;
}

const _duration = Duration(milliseconds: 650);
final _curve = TinoSpringCurve(TinoSprings.navegacao, _duration);

/// Escala do Comprar com o scanner aberto por cima.
const _backdropScale = 0.90;

/// Escurecimento do Comprar com o scanner aberto por cima.
const _backdropDim = 0.45;

/// Raio do botão de escanear, que vai a 0 na tela cheia.
const _startRadius = TinoRadius.cardCompact;

/// Rota do scanner: sempre no tema escuro (design/specs/telas.md · 03).
CustomTransitionPage<ScanResult> scannerPage(GoRouterState state) =>
    CustomTransitionPage<ScanResult>(
      key: state.pageKey,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      child: Theme(
        data: buildTinoTheme(Brightness.dark),
        child: const AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: ScannerPage(),
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          _ScannerReveal(animation: animation, child: child),
    );

/// M2: o retângulo do botão cresce até a tela cheia (posição, tamanho e raio
/// 16 → 0) com a mola `navegacao`; o Comprar escurece atrás. Fechar faz o
/// caminho inverso. Sem origem ou com movimento reduzido: opacidade 150 ms.
class _ScannerReveal extends StatefulWidget {
  const _ScannerReveal({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  State<_ScannerReveal> createState() => _ScannerRevealState();
}

class _ScannerRevealState extends State<_ScannerReveal> {
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) ScannerOrigin.rect = null;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final origin = ScannerOrigin.rect;
    if (origin == null || TinoMotion.reduced(context)) {
      // 150 ms dos 650 da rota.
      return FadeTransition(
        opacity: widget.animation.drive(
          CurveTween(curve: const Interval(0, 0.23, curve: TinoCurves.easeOut)),
        ),
        child: widget.child,
      );
    }
    final c = context.tino;
    // Cor do botão, que some no começo do crescimento.
    final button = c.action;
    final scrim = c.scrim;
    return AnimatedBuilder(
      animation: widget.animation,
      child: widget.child,
      builder: (context, child) {
        final p = _curve.transform(widget.animation.value);
        final screen = Offset.zero & MediaQuery.sizeOf(context);
        final rect = Rect.lerp(origin, screen, p)!;
        final radius = _startRadius * (1 - p).clamp(0.0, 1.0);
        final tint = (1 - p * 3).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: scrim.withValues(
                    alpha: _backdropDim * p.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                clipper: _RectClipper(
                  RRect.fromRectAndRadius(rect, Radius.circular(radius)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child!,
                    if (tint > 0)
                      IgnorePointer(
                        child: ColoredBox(
                          color: button.withValues(alpha: tint),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RectClipper extends CustomClipper<RRect> {
  const _RectClipper(this.rrect);
  final RRect rrect;

  @override
  RRect getClip(Size size) => rrect;

  @override
  bool shouldReclip(_RectClipper old) => old.rrect != rrect;
}

/// Comprar atrás do scanner: escala 1 → 0,90 acompanhando a mola do M2.
/// Só age quando o scanner abriu a partir do botão.
class ScannerBackdrop extends StatelessWidget {
  const ScannerBackdrop({
    super.key,
    required this.animation,
    required this.child,
  });

  /// Animação da rota que está por cima (secondaryAnimation).
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      if (ScannerOrigin.rect == null ||
          animation.value == 0 ||
          TinoMotion.reduced(context)) {
        return child!;
      }
      final p = _curve.transform(animation.value);
      return Transform.scale(scale: 1 - (1 - _backdropScale) * p, child: child);
    },
  );
}
