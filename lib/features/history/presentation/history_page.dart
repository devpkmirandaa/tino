import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/area_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => const AreaPage(
    title: 'Histórico',
    description: 'Um espaço para olhar suas compras com calma.',
    icon: LucideIcons.history,
    message: 'Suas compras terão memória',
    detail: 'O registro e a consulta de compras finalizadas ainda não estão disponíveis.',
  );
}
