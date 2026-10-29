import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Simula apenas a fronteira do plugin. A preferência e as rotas são reais.
// Controles mutáveis permitem testar falhas e gravações pendentes do plugin.
// ignore: must_be_immutable
class MemoryPreferences implements SharedPreferencesAsync {
  MemoryPreferences([Map<String, bool>? disk]) : disk = disk ?? {};
  final Map<String, bool> disk;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;
  Completer<void>? pendingWrite;

  @override
  Future<bool?> getBool(String key) async {
    if (failRead) throw StateError('read failed');
    return disk[key];
  }

  @override
  Future<void> setBool(String key, bool value) async {
    writes++;
    await pendingWrite?.future;
    if (failWrite) throw StateError('write failed');
    disk[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
