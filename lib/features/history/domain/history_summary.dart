import '../../shopping/domain/finished_purchase.dart';
import '../../shopping/domain/money.dart';

/// Textos e contas do Histórico (design/telas/09) e do Resumo da compra
/// (design/telas/16).

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const _weekdays = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String _capitalized(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

/// "Novembro".
String monthName(int month) => _capitalized(_months[month - 1]);

/// Total e número de compras de um mês.
typedef MonthTotal = ({int year, int month, Money total, int count});

/// Mês atual e o anterior (janeiro compara com dezembro do ano anterior).
({MonthTotal current, MonthTotal previous}) monthComparison(
  Iterable<FinishedPurchase> purchases,
  DateTime now,
) {
  MonthTotal sum(int year, int month) {
    var total = Money.zero;
    var count = 0;
    for (final p in purchases) {
      if (p.finishedAt.year == year && p.finishedAt.month == month) {
        total += p.cart.total;
        count++;
      }
    }
    return (year: year, month: month, total: total, count: count);
  }

  final previous = DateTime(now.year, now.month - 1);
  return (
    current: sum(now.year, now.month),
    previous: sum(previous.year, previous.month),
  );
}

/// "Nenhuma compra", "1 compra", "3 compras".
String purchaseCount(int n) => switch (n) {
  0 => 'Nenhuma compra',
  1 => '1 compra',
  _ => '$n compras',
};

/// "1 item", "18 itens".
String itemCount(int n) => n == 1 ? '1 item' : '$n itens';

/// Bloco de um mês na lista do Histórico.
typedef MonthGroup = ({String label, List<FinishedPurchase> purchases});

/// Compras por mês, da mais recente para a mais antiga. Mês de outro ano
/// leva o ano: "Outubro de 2025".
List<MonthGroup> groupByMonth(
  Iterable<FinishedPurchase> purchases,
  DateTime now,
) {
  final sorted = [...purchases]
    ..sort((a, b) {
      final c = b.finishedAt.compareTo(a.finishedAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
  final groups = <MonthGroup>[];
  (int, int)? key;
  for (final p in sorted) {
    final at = p.finishedAt;
    if (key != (at.year, at.month)) {
      key = (at.year, at.month);
      final label = at.year == now.year
          ? monthName(at.month)
          : '${monthName(at.month)} de ${at.year}';
      groups.add((label: label, purchases: []));
    }
    groups.last.purchases.add(p);
  }
  return groups;
}

/// "4 de novembro", com o ano quando não é o atual.
String dayMonth(DateTime at, DateTime now) {
  final base = '${at.day} de ${_months[at.month - 1]}';
  return at.year == now.year ? base : '$base de ${at.year}';
}

/// Data da linha: "Hoje", "Ontem" ou "28 de outubro" (dias de calendário).
String purchaseDay(DateTime at, DateTime now) {
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Hoje';
  if (day == DateTime(now.year, now.month, now.day - 1)) return 'Ontem';
  return dayMonth(at, now);
}

/// Apoio da linha: "N itens · lista"; sem lista, o orçamento ("dentro do
/// orçamento" ou "passou do orçamento"); sem os dois, só "N itens".
String purchaseLine(FinishedPurchase p) {
  final count = itemCount(p.cart.items.length);
  final context = switch ((p.listName, p.budget)) {
    (final name?, _) => name,
    (null, final budget?) =>
      p.cart.total > budget ? 'passou do orçamento' : 'dentro do orçamento',
    _ => null,
  };
  return context == null ? count : '$count · $context';
}

/// Subtítulo do Resumo: "Terça · 18 itens · Lista do mês".
String summarySubtitle(FinishedPurchase p) => [
  _weekdays[p.finishedAt.weekday - 1],
  itemCount(p.cart.items.length),
  ?p.listName,
].join(' · ');
