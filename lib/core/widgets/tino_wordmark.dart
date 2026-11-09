import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Marca compartilhada, com proporção e cores do SVG original.
class TinoWordmark extends StatelessWidget {
  const TinoWordmark({super.key, this.width = 88});

  /// Largura do desenho por unidade de altura (viewBox 36,03 × 13,92).
  static const aspectRatio = 36.03 / 13.92;

  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/branding/tino-wordmark.svg',
    width: width,
    height: width / aspectRatio,
    fit: BoxFit.contain,
    semanticsLabel: 'Tino',
  );
}
