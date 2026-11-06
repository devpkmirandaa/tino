import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';

import '../motion/tino_springs.dart';
import '../theme/tino_theme.dart';
import 'tino_pressable.dart';

enum _Variant { primary, outlined, text }

/// Altura do botão primário.
enum TinoButtonSize {
  /// 52, raio 12.
  regular,

  /// 64, raio 16. Só para "Escanear preço". Provisório: foge da escala do
  /// manual e aguarda aprovação de marca (design/README.md).
  scan,
}

/// Botões base (design/specs/telas.md · Componentes base) com M1.
class TinoButton extends StatelessWidget {
  /// Fundo `action`, texto `on-action` 16/600; pressionado `action-pressed`.
  const TinoButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = TinoButtonSize.regular,
    this.expand = false,
  }) : _variant = _Variant.primary,
       accent = false;

  /// Altura 48, borda 1 `border-strong`, texto `text-primary` ou `action`.
  const TinoButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.accent = false,
    this.expand = false,
  }) : _variant = _Variant.outlined,
       size = TinoButtonSize.regular;

  /// Altura 48, sem fundo, texto `action` 14/600.
  const TinoButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  }) : _variant = _Variant.text,
       size = TinoButtonSize.regular,
       accent = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TinoButtonSize size;
  final bool expand;

  /// No contornado, texto em `action` em vez de `text-primary`.
  final bool accent;
  final _Variant _variant;

  static const _colorDuration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final enabled = onPressed != null;
    final scan = size == TinoButtonSize.scan;
    final height = switch (_variant) {
      _Variant.primary => scan ? 64.0 : TinoSize.inputHeight,
      _ => TinoSize.touchTarget,
    };
    final radius = scan ? TinoRadius.cardCompact : TinoRadius.control;
    final style = _variant == _Variant.primary
        ? TinoType.corpoForte
        : TinoType.label;

    return TinoPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, pressed) {
        final (Color background, Color foreground) = switch (_variant) {
          _Variant.primary when !enabled => (c.surfaceSoft, c.textSecondary),
          _Variant.primary => (
            pressed ? c.actionPressed : c.action,
            c.onAction,
          ),
          _ when !enabled => (Colors.transparent, c.textSecondary),
          _Variant.outlined => (
            Colors.transparent,
            accent ? c.action : c.textPrimary,
          ),
          _Variant.text => (Colors.transparent, c.action),
        };
        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: scan ? TinoSize.icon : TinoSize.iconCompact,
                color: foreground,
              ),
              const SizedBox(width: TinoSpace.s8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.withColor(foreground),
              ),
            ),
          ],
        );
        return AnimatedContainer(
          duration: _colorDuration,
          curve: TinoCurves.easeOut,
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: TinoSize.touchTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _variant == _Variant.text
                ? TinoSpace.s12
                : TinoSpace.s16,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: _variant == _Variant.outlined
                ? Border.all(
                    color: enabled ? c.borderStrong : c.border,
                    width: TinoSize.borderWidth,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: content,
        );
      },
    );
  }
}

/// Botão só ícone, 48 × 48, sempre com rótulo de acessibilidade.
class TinoIconButton extends StatelessWidget {
  const TinoIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.accent = false,
    this.compact = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Ícone em `action` em vez de `text-primary`.
  final bool accent;

  /// Ícone de 20 em vez de 24; a área de toque continua 48.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final color = onPressed == null
        ? c.textSecondary
        : accent
        ? c.action
        : c.textPrimary;
    return TinoPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, _) => SizedBox.square(
        dimension: TinoSize.touchTarget,
        child: Center(
          child: Icon(
            icon,
            size: compact ? TinoSize.iconCompact : TinoSize.icon,
            color: color,
          ),
        ),
      ),
    );
  }
}
