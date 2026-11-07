import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Mock oficial do shared_preferences para testes (vem junto do pacote).
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tino/core/motion/tino_haptics.dart';
import 'package:tino/features/settings/data/settings_preferences.dart';
import 'package:tino/features/shopping/domain/budget.dart';
import 'package:tino/features/shopping/domain/money.dart';

void main() {
  const budget = Money(10000);

  bool reached(int before, int after, {Money? from = budget, Money? to}) =>
      reachedNearBudget(
        before: Money(before),
        after: Money(after),
        budgetBefore: from,
        budgetAfter: to ?? from,
      );

  test('percentual usado arredonda para baixo', () {
    expect(budgetUsedPercent(const Money(13740), const Money(15000)), 91);
    expect(budgetUsedPercent(const Money(8999), budget), 89);
    expect(budgetUsedPercent(const Money(10000), budget), 100);
    expect(budgetUsedPercent(Money.zero, budget), 0);
  });

  test('aviso vibra em dois pulsos com o intervalo do motion.md', () {
    final p = TinoHaptics.warningPattern;
    expect(p.timings, hasLength(p.amplitudes.length));
    expect(p.timings[2], TinoHaptics.warningGap.inMilliseconds);
    expect(p.amplitudes.where((a) => a > 0), hasLength(2));
  });

  group('aviso de 90%', () {
    test('passar de dentro para perto do limite avisa', () {
      expect(reached(8900, 9000), isTrue);
      expect(reached(5000, 9500), isTrue);
    });

    test('já perto, de volta para dentro ou pulando para passou não avisa', () {
      expect(reached(9000, 9500), isFalse);
      expect(reached(9500, 8000), isFalse);
      expect(reached(8000, 10001), isFalse); // fica com o aviso de 100%
    });

    test('mudar o orçamento ou não ter orçamento não avisa', () {
      expect(
        reached(9000, 9000, from: const Money(20000), to: budget),
        isFalse,
      );
      expect(reached(8000, 9500, from: null), isFalse);
    });
  });

  test(
    '"Avisar quando faltar pouco" começa ligado e guarda a escolha',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final first = ProviderContainer();
      addTearDown(first.dispose);
      expect(await first.read(nearBudgetAlertProvider.future), isTrue);
      await first.read(nearBudgetAlertProvider.notifier).set(false);
      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(await second.read(nearBudgetAlertProvider.future), isFalse);
    },
  );
}
