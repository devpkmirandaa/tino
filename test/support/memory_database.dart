import 'package:drift/native.dart';
import 'package:tino/core/database/tino_database.dart';

/// Banco SQLite em memória, isolado por teste.
final memoryDatabase = databaseProvider.overrideWith((ref) {
  final db = TinoDatabase(NativeDatabase.memory());
  ref.onDispose(db.close);
  return db;
});
