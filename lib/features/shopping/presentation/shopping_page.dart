import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/area_page.dart';

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) => const AreaPage(
    title: 'Comprar',
    description: 'Mais tranquilidade para acompanhar cada escolha.',
    icon: LucideIcons.scanLine,
    message: 'Tudo começa por uma compra',
    detail:
        'Iniciar uma compra, definir orçamento, escanear etiquetas e '
        'adicionar produtos ao carrinho ainda não estão disponíveis.',
  );
}
