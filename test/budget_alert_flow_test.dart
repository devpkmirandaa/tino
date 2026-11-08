import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Mock oficial do shared_preferences para testes (vem junto do pacote).
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tino/features/settings/data/settings_preferences.dart';
import 'package:tino/features/shopping/application/budget_alert.dart';
import 'package:tino/features/shopping/application/shopping_controller.dart';
import 'package:tino/features/shopping/domain/cart.dart';
import 'package:tino/features/shopping/domain/money.dart';

import 'support/memory_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('passar de 90% chama o vibrador uma vez', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('tino/vibration'), (
          call,
        ) async {
          calls.add(call);
          return true;
        });

    final c = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(c.dispose);
    c.listen(budgetAlertProvider, (_, _) {});
    await c.read(shoppingProvider.future);
    final shopping = c.read(shoppingProvider.notifier)
      ..setBudget(const Money(10000))
      ..add(UnitItem(id: 'a', name: 'Arroz', price: const Money(8000)));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(calls, isEmpty);

    shopping.add(UnitItem(id: 'b', name: 'Café', price: const Money(1500)));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(calls, hasLength(1));
    await shopping.flush();
  });

  test('com "Avisar quando faltar pouco" desligado não vibra', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('tino/vibration'), (
          call,
        ) async {
          calls.add(call);
          return true;
        });

    final c = ProviderContainer(overrides: [memoryDatabase]);
    addTearDown(c.dispose);
    c.listen(budgetAlertProvider, (_, _) {});
    await c.read(nearBudgetAlertProvider.notifier).set(false);
    await c.read(shoppingProvider.future);
    final shopping = c.read(shoppingProvider.notifier)
      ..setBudget(const Money(10000))
      ..add(UnitItem(id: 'a', name: 'Arroz', price: const Money(9500)));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(calls, isEmpty);
    await shopping.flush();
  });
}
