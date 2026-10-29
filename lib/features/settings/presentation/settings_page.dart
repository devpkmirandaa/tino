import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/area_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => AreaPage(
    title: 'Ajustes',
    description: 'O Tino do seu jeito, com escolhas transparentes.',
    icon: LucideIcons.settings2,
    message: 'Uma experiência mais leve',
    detail:
        'O Tino usa o tema claro. Preferências de aparência, permissões e '
        'gerenciamento de dados ainda não estão disponíveis.',
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push('/apresentacao?rever=true'),
          icon: const Icon(LucideIcons.info, size: 24),
          label: const Text('Sobre o Tino'),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tino — Comprar bem começa antes.\nGratuito, de código aberto e sem anúncios.',
        ),
      ],
    ),
  );
}
