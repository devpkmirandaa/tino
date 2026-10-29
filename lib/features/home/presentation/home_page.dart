import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'tino',
                style: text.headlineMedium?.copyWith(color: TinoColors.jade),
              ),
              const SizedBox(height: 36),
              Text('ANTES DO CAIXA', style: text.labelLarge),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  'Comprar bem\ncomeça antes.',
                  style: text.headlineLarge,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mais clareza para suas escolhas no mercado.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TinoColors.glacialBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.shoppingBasket),
                    const SizedBox(height: 20),
                    Text('Sua compra, com mais tino.', style: text.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Conheça o espaço onde você poderá acompanhar sua compra. '
                      'O registro de produtos ainda não está disponível.',
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => context.go('/comprar'),
                      child: const Text('Ir para Comprar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Antes de começar', style: text.titleLarge),
              const SizedBox(height: 12),
              Text(
                'O resumo do orçamento e da compra em andamento ficará aqui '
                'quando o registro de compras estiver disponível.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.go('/listas'),
                icon: const Icon(LucideIcons.listChecks, size: 24),
                label: const Text('Ir para Listas'),
              ),
              const SizedBox(height: 32),
              Text(
                'Gratuito. Sem anúncios. Feito para comprar com calma.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
