import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../application/lists_providers.dart';
import '../domain/shopping_list.dart';
import 'lists_sheets.dart';

/// Listas salvas no aparelho; tocar abre a lista.
class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showListNameSheet(
      context,
      title: 'Nova lista',
      action: 'Criar lista',
    );
    if (name == null) return;
    final id = await ref.read(listsActionsProvider).createList(name);
    if (context.mounted) context.go('/listas/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final lists = ref.watch(listsProvider);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TinoSpace.s16,
              TinoSpace.s24,
              TinoSpace.s16,
              TinoSpace.s16,
            ),
            children: [
              Semantics(
                header: true,
                child: Text('Listas', style: text.headlineLarge),
              ),
              const SizedBox(height: TinoSpace.s8),
              Text(
                'Planeje antes de sair: o que levar, por seção do mercado.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: TinoSpace.s24),
              switch (lists) {
                AsyncData(:final value) when value.isEmpty => const _Empty(),
                AsyncData(:final value) => _ListCards(value),
                AsyncError() => const Text('Não deu pra abrir as listas.'),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TinoSpace.s16,
            TinoSpace.s8,
            TinoSpace.s16,
            TinoSpace.s16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('new-list'),
              onPressed: () => _create(context, ref),
              icon: const Icon(LucideIcons.plus, size: 20),
              label: const Text('Nova lista'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: TinoSpace.s32),
        Icon(
          LucideIcons.listChecks,
          size: 48,
          color: context.tino.textSecondary,
        ),
        const SizedBox(height: TinoSpace.s16),
        Text('Nenhuma lista ainda', style: text.titleMedium),
        const SizedBox(height: TinoSpace.s4),
        Text(
          'Crie uma lista para a compra do mês, do churrasco…',
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ListCards extends StatelessWidget {
  const _ListCards(this.lists);
  final List<ShoppingListInfo> lists;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.tino.surface,
        border: Border.all(color: context.tino.border),
        borderRadius: BorderRadius.circular(TinoRadius.card),
      ),
      child: Column(
        children: [
          for (final (i, list) in lists.indexed) ...[
            if (i > 0) const Divider(indent: TinoSpace.s16),
            InkWell(
              onTap: () => context.go('/listas/${list.id}'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TinoSpace.s16,
                    vertical: TinoSpace.s12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(list.name, style: text.titleMedium),
                            Text(_count(list), style: text.bodyMedium),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: context.tino.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _count(ShoppingListInfo l) => switch (l.itemCount) {
    0 => 'Vazia',
    1 => l.doneCount == 1 ? '1 item, marcado' : '1 item',
    final n when l.doneCount == 0 => '$n itens',
    final n => '${l.doneCount} de $n marcados',
  };
}
