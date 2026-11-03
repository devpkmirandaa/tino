import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'tino_database.g.dart';

/// Compra: ativa enquanto [finishedAt] for nulo (no máximo uma).
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get budgetCents => integer().nullable()();
}

/// Item: [kind] 0 = unidade (preço, quantidade), 1 = peso (preço/kg, gramas).
class PurchaseItems extends Table {
  TextColumn get id => text()();
  IntColumn get purchaseId =>
      integer().references(Purchases, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  IntColumn get kind => integer()();
  IntColumn get priceCents => integer()();
  IntColumn get amount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Purchases, PurchaseItems])
class TinoDatabase extends _$TinoDatabase {
  TinoDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tino'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

final databaseProvider = Provider<TinoDatabase>((ref) {
  final db = TinoDatabase();
  ref.onDispose(db.close);
  return db;
});
