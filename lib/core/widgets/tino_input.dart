import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tino_theme.dart';

/// Input: rótulo 14/600 acima, campo de 52 com raio 12 e borda
/// `border-strong`; no foco, borda `action` de 2.
class TinoInput extends StatelessWidget {
  const TinoInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.money = false,
    this.valueStyle,
  });

  /// Estilo do valor digitado no lugar do corpo 16 (ex.: preço 18/700).
  final TinoTypeStyle? valueStyle;

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// Texto curto à direita, como "kg" ou "R$".
  final String? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Valor em dinheiro: 700 e numerais tabulares.
  final bool money;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(TinoRadius.control),
      borderSide: BorderSide(color: color, width: width),
    );
    final type = valueStyle ?? TinoType.corpo;
    final text = type.withColor(c.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TinoType.label.withColor(c.textPrimary)),
        const SizedBox(height: TinoSpace.s8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: c.action,
          style: money ? text.money : text,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.surface,
            hintText: hint,
            hintStyle: TinoType.corpo.withColor(c.textSecondary),
            suffixText: suffix,
            suffixStyle: TinoType.secundario.withColor(c.textSecondary),
            constraints: const BoxConstraints(minHeight: TinoSize.inputHeight),
            // Centraliza a linha do texto na altura de 52 (14 para 24 px).
            contentPadding: EdgeInsets.symmetric(
              horizontal: TinoSpace.s16,
              vertical: (TinoSize.inputHeight - type.lineHeight) / 2,
            ),
            border: border(c.borderStrong, TinoSize.borderWidth),
            enabledBorder: border(c.borderStrong, TinoSize.borderWidth),
            focusedBorder: border(c.action, 2),
          ),
        ),
      ],
    );
  }
}
