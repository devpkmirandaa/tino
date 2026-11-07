import 'package:flutter/material.dart';

import '../theme/tino_theme.dart';

/// Switch com os tokens: ligado `action` + bolinha `on-action`; desligado
/// trilho `surface-soft`, borda `border-strong`, bolinha `text-secondary`.
class TinoSwitch extends StatelessWidget {
  const TinoSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: c.action,
      activeThumbColor: c.onAction,
      inactiveTrackColor: c.surfaceSoft,
      inactiveThumbColor: c.textSecondary,
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.action : c.borderStrong,
      ),
    );
  }
}
