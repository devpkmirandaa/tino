import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Marca compartilhada, com proporção e cores do SVG original.
class TinoWordmark extends StatelessWidget {
  const TinoWordmark({super.key, this.width = 88});

  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/branding/tino-wordmark.svg',
    width: width,
    height: width * 13.92 / 36.03,
    fit: BoxFit.contain,
    semanticsLabel: 'Tino',
  );
}
