import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tino_theme.dart';

/// Input: rótulo 14/600 acima, campo de 52 com raio 12 e borda
/// `border-strong`; no foco, borda `action` de 2.
class TinoInput extends StatelessWidget {
  const TinoInput({
    super.key,
    this.label,
    this.leading,
    this.trailing,
    this.textCapitalization = TextCapitalization.none,
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
    this.height = TinoSize.inputHeight,
    this.focusNode,
  });

  /// Altura do campo: 52 no padrão, 56 no preço da folha Digitar preço.
  final double height;
  final FocusNode? focusNode;

  /// Estilo do valor digitado no lugar do corpo 16 (ex.: preço 18/700).
  final TinoTypeStyle? valueStyle;

  /// Rótulo acima (14/600). Sem rótulo, a dica ([hint]) faz o papel dele,
  /// também para o leitor de tela (ex.: "Adicionar item" da Lista).
  final String? label;

  /// Ícone dentro do campo, à esquerda (ex.: + do "Adicionar item").
  final Widget? leading;

  /// Botão dentro do campo, à direita.
  final Widget? trailing;
  final TextCapitalization textCapitalization;
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
        if (label case final label?) ...[
          Text(label, style: TinoType.label.withColor(c.textPrimary)),
          const SizedBox(height: TinoSpace.s8),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
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
            prefixIcon: leading,
            prefixIconConstraints: const BoxConstraints(
              minWidth: TinoSize.touchTarget,
              minHeight: TinoSize.touchTarget,
            ),
            suffixIcon: trailing,
            suffixIconConstraints: const BoxConstraints(
              minWidth: TinoSize.touchTarget,
              minHeight: TinoSize.touchTarget,
            ),
            constraints: BoxConstraints(minHeight: height),
            // Centraliza a linha do texto na altura (14 para 24 px em 52).
            contentPadding: EdgeInsets.symmetric(
              horizontal: TinoSpace.s16,
              vertical: (height - type.lineHeight) / 2,
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
