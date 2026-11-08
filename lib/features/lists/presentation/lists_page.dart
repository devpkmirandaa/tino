import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../shopping/application/shopping_controller.dart';
import '../application/lists_providers.dart';
import 'list_card.dart';
import 'lists_sheets.dart';

/// Listas (design/telas/07): um cartão por lista; a em uso mostra o
/// progresso. "Nova lista" no topo.
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
    final c = context.tino;
    final lists = ref.watch(listsProvider);
    final active = ref.watch(shoppingProvider).value?.listId;
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TinoSpace.s16,
        TinoSpace.s16,
        TinoSpace.s16,
        TinoSpace.s24,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Listas',
                  style: TinoType.tela.withColor(c.textPrimary),
                ),
              ),
            ),
            _NewListButton(onPressed: () => _create(context, ref)),
          ],
        ),
        const SizedBox(height: TinoSpace.s16),
        switch (lists) {
          AsyncData(:final value) when value.isEmpty => const _Empty(),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, list) in value.indexed) ...[
                if (i > 0) const SizedBox(height: TinoSpace.s12),
                ListCard(
                  key: ValueKey('list-card-${list.id}'),
                  list: list,
                  inUse: list.id == active,
                  now: now,
                  onPressed: () => context.go('/listas/${list.id}'),
                ),
              ],
              const SizedBox(height: TinoSpace.s16),
              Text(
                'Com uma lista ativa, cada item escaneado sai dela sozinho.',
                textAlign: TextAlign.center,
                style: TinoType.secundario.withColor(c.textSecondary),
              ),
            ],
          ),
          AsyncError() => Text(
            'Não deu pra abrir as listas.',
            style: TinoType.corpo.withColor(c.textPrimary),
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// "Nova lista": pílula `action` de 40 com +, área de toque 48.
class _NewListButton extends StatelessWidget {
  const _NewListButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return TinoPressable(
      key: const ValueKey('new-list'),
      onPressed: onPressed,
      semanticLabel: 'Nova lista',
      excludeSemantics: true,
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.symmetric(vertical: TinoSpace.s4),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(
            left: TinoSpace.s8,
            right: TinoSpace.s12,
          ),
          decoration: BoxDecoration(
            color: pressed ? c.actionPressed : c.action,
            borderRadius: BorderRadius.circular(TinoRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.plus,
                size: TinoSize.iconCompact,
                color: c.onAction,
              ),
              const SizedBox(width: TinoSpace.s4),
              Text('Nova lista', style: TinoType.label.withColor(c.onAction)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  static const _iconBox = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TinoSpace.s32),
      child: Column(
        children: [
          Container(
            width: _iconBox,
            height: _iconBox,
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(TinoRadius.card),
            ),
            child: Icon(
              LucideIcons.listChecks,
              size: TinoSize.icon,
              color: c.action,
            ),
          ),
          const SizedBox(height: TinoSpace.s16),
          Text(
            'Nenhuma lista ainda',
            style: TinoType.subtitulo.withColor(c.textPrimary),
          ),
          const SizedBox(height: TinoSpace.s8),
          Text(
            'Crie uma lista para a compra do mês, do churrasco…',
            textAlign: TextAlign.center,
            style: TinoType.secundario.withColor(c.textSecondary),
          ),
        ],
      ),
    );
  }
}
