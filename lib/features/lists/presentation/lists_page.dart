import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/area_page.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context) => const AreaPage(
    title: 'Listas',
    description: 'Um lugar para organizar o que você precisa levar.',
    icon: LucideIcons.listChecks,
    message: 'Planeje antes de sair',
    detail: 'A criação e a edição de listas ainda não estão disponíveis.',
  );
}
