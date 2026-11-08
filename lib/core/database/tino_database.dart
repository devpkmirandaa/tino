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

  /// Lista usada nesta compra, se houver (itens lidos são riscados nela).
  IntColumn get listId => integer().nullable()();

  /// "Onde foi a compra?", digitado ao finalizar (opcional).
  TextColumn get place => text().nullable()();
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

  /// Nome como lido na etiqueta (só itens do scanner).
  TextColumn get tagText => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lista de compras. [sortMode]: `category`, `added` ou `manual`.
/// [categoryOrder]: categorias separadas por vírgula, para o modo manual.
@DataClassName('ShoppingListRow')
class ShoppingLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get sortMode => text().withDefault(const Constant('category'))();
  TextColumn get categoryOrder => text().nullable()();
}

/// Item da lista. [unit] guarda a unidade (`un` por enquanto; peso depois
/// sem mudar o banco). [position] é a ordem manual dentro da categoria.
@DataClassName('ListItemRow')
class ListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('un'))();
  TextColumn get category => text()();
  IntColumn get position => integer()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Categoria escolhida pelo usuário para um nome de produto ([key] é o nome
/// normalizado ou `#primeira-palavra`). Vira a sugestão das próximas vezes.
@DataClassName('CategoryHintRow')
class CategoryHints extends Table {
  TextColumn get key => text()();
  TextColumn get category => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Par produto → item de lista confirmado (true) ou desfeito (false) pelo
/// usuário; [key] é `produto>item`, nomes normalizados.
@DataClassName('ListPairRow')
class ListPairs extends Table {
  TextColumn get key => text()();
  BoolColumn get matches => boolean()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Purchases,
    PurchaseItems,
    ShoppingLists,
    ListItems,
    CategoryHints,
    ListPairs,
  ],
)
class TinoDatabase extends _$TinoDatabase {
  TinoDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tino'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(shoppingLists);
        await m.createTable(listItems);
      }
      if (from < 3) await m.createTable(categoryHints);
      if (from < 4) await m.addColumn(purchases, purchases.listId);
      if (from < 5) await m.createTable(listPairs);
      if (from < 6) {
        await m.addColumn(purchaseItems, purchaseItems.tagText);
      }
      if (from < 7) await m.addColumn(purchases, purchases.place);
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

final databaseProvider = Provider<TinoDatabase>((ref) {
  final db = TinoDatabase();
  ref.onDispose(db.close);
  return db;
});
