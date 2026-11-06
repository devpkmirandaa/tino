import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/area_page.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../data/lab_mode.dart';

/// Ajustes fora das abas: abre pela engrenagem do Comprar e volta para ele.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TinoSpace.s4,
              TinoSpace.s4,
              TinoSpace.s4,
              0,
            ),
            child: TinoIconButton(
              key: const ValueKey('settings-back'),
              icon: LucideIcons.arrowLeft,
              semanticLabel: 'Voltar',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
          ),
          const Expanded(child: SettingsPage()),
        ],
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => AreaPage(
    title: 'Ajustes',
    description: 'O Tino do seu jeito, com escolhas transparentes.',
    icon: LucideIcons.settings2,
    message: 'Uma experiência mais leve',
    detail:
        'O Tino segue o tema claro ou escuro do aparelho. Escolher a '
        'aparência, permissões e gerenciamento de dados ainda não estão '
        'disponíveis.',
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push('/apresentacao?rever=true'),
          icon: const Icon(LucideIcons.info, size: 24),
          label: const Text('Sobre o Tino'),
        ),
        const SizedBox(height: 20),
        const _DeveloperTaps(
          child: Text(
            'Tino — Comprar bem começa antes.\nGratuito, de código aberto e sem anúncios.',
          ),
        ),
      ],
    ),
  );
}

/// Opção de desenvolvedor escondida: 7 toques seguidos no rodapé ligam ou
/// desligam o modo laboratório do scanner.
class _DeveloperTaps extends ConsumerStatefulWidget {
  const _DeveloperTaps({required this.child});
  final Widget child;

  @override
  ConsumerState<_DeveloperTaps> createState() => _DeveloperTapsState();
}

class _DeveloperTapsState extends ConsumerState<_DeveloperTaps> {
  var _taps = 0;
  var _last = DateTime(0);

  Future<void> _tap() async {
    final now = DateTime.now();
    _taps = now.difference(_last) < const Duration(seconds: 1) ? _taps + 1 : 1;
    _last = now;
    if (_taps < 7) return;
    _taps = 0;
    final on = await ref.read(labModeProvider.notifier).toggle();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          on ? 'Modo laboratório ligado.' : 'Modo laboratório desligado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _tap,
    child: widget.child,
  );
}
