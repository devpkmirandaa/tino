import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shopping/application/shopping_controller.dart';
import '../application/list_shopping_link.dart';
import '../application/lists_providers.dart';

/// Mostra, em qualquer tela (inclusive no scanner), o aviso de item riscado
/// com "Desfazer" ou a pergunta "Riscar?". A resposta ensina o Tino.
class ListFeedbackListener extends ConsumerWidget {
  const ListFeedbackListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(listFeedbackProvider, (_, feedback) {
      if (feedback == null) return;
      ref.read(listFeedbackProvider.notifier).set(null);
      final actions = ref.read(listsActionsProvider);
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      switch (feedback) {
        case AutoChecked():
          messenger.showSnackBar(
            SnackBar(
              content: Text('Riscado na lista: ${feedback.itemName}'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () async {
                  await actions.setDone(
                    feedback.listId,
                    feedback.itemId,
                    false,
                  );
                  await actions.learnPair(
                    feedback.productName,
                    feedback.itemName,
                    false,
                  );
                },
              ),
            ),
          );
        case SuggestCheck(:final listName):
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 6),
              content: Text(
                listName == null
                    ? 'Riscar "${feedback.itemName}" da lista?'
                    : 'Riscar "${feedback.itemName}" da lista $listName?',
              ),
              action: SnackBarAction(
                label: 'Riscar',
                onPressed: () async {
                  if (listName != null) {
                    // Aceitar também liga a lista a esta compra.
                    ref
                        .read(shoppingProvider.notifier)
                        .setList(feedback.listId);
                  }
                  await actions.setDone(feedback.listId, feedback.itemId, true);
                  await actions.learnPair(
                    feedback.productName,
                    feedback.itemName,
                    true,
                  );
                },
              ),
            ),
          );
      }
    });
    return child;
  }
}
