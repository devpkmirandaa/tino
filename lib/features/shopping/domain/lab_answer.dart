import 'decimal_input.dart';
import 'money.dart';
import 'tag_reader.dart';

/// Gabarito de uma etiqueta do laboratório, lido do QR:
/// `TINO1|id=<id>|p=<preço>|a=<atacado>|m=<mínimo>|kg=<0|1>|c=<cenário>`.
final class LabAnswer {
  const LabAnswer({
    required this.id,
    required this.price,
    required this.scenario,
    this.bulkPrice,
    this.bulkMin,
    this.perKg = false,
  });

  final String id;
  final Money price;
  final Money? bulkPrice;
  final int? bulkMin;
  final bool perKg;
  final String scenario;

  static LabAnswer? parse(String raw) {
    final parts = raw.trim().split('|');
    if (parts.isEmpty || parts.first != 'TINO1') return null;
    final f = {
      for (final p in parts.skip(1))
        if (p.indexOf('=') case final i when i > 0)
          p.substring(0, i): p.substring(i + 1),
    };
    final id = f['id'];
    final price = parseScaled(f['p'] ?? '', 2);
    if (id == null || id.isEmpty || price == null) return null;
    final bulk = parseScaled(f['a'] ?? '', 2);
    return LabAnswer(
      id: id,
      price: Money(price),
      bulkPrice: bulk == null ? null : Money(bulk),
      bulkMin: int.tryParse(f['m'] ?? ''),
      perKg: f['kg'] == '1',
      scenario: (f['c'] ?? '').isEmpty ? 'sem-cenário' : f['c']!,
    );
  }

  /// Campo a campo: `true` = acertou.
  ({bool price, bool bulk, bool min, bool kg}) check(TagReading r) => (
    price: r.price == price,
    bulk: r.bulkPrice == bulkPrice,
    min: r.bulkMin == bulkMin,
    kg: r.perKg == perKg,
  );
}

/// Acumula os resultados de uma sessão do modo laboratório.
final class LabReport {
  final _seen = <String, String>{}; // id → cenário
  final _locks = <({String id, String scenario, bool ok, int ms})>[];

  void saw(LabAnswer a) => _seen[a.id] = a.scenario;

  /// Registra um travamento comparado com o gabarito; retorna se acertou
  /// todos os campos.
  bool lock(LabAnswer a, TagReading r, int ms) {
    saw(a);
    final c = a.check(r);
    final ok = c.price && c.bulk && c.min && c.kg;
    _locks.add((id: a.id, scenario: a.scenario, ok: ok, ms: ms));
    return ok;
  }

  bool get isEmpty => _seen.isEmpty;

  /// Por cenário: taxa de erro (travamentos com algum campo errado),
  /// cobertura (etiquetas vistas no QR que travaram) e mediana do tempo.
  List<String> summary() {
    final scenarios = {..._seen.values}.toList()..sort();
    return [
      for (final s in [...scenarios, 'TOTAL'])
        _line(
          s,
          s == 'TOTAL' ? _locks : _locks.where((l) => l.scenario == s).toList(),
          s == 'TOTAL'
              ? _seen.length
              : _seen.values.where((v) => v == s).length,
        ),
    ];
  }

  String _line(
    String scenario,
    List<({String id, String scenario, bool ok, int ms})> locks,
    int seen,
  ) {
    final errors = locks.where((l) => !l.ok).length;
    final covered = {for (final l in locks) l.id}.length;
    final times = [for (final l in locks) l.ms]..sort();
    final median = times.isEmpty ? '-' : '${times[times.length ~/ 2]}ms';
    final errorRate = locks.isEmpty
        ? '-'
        : '${(errors * 100 / locks.length).toStringAsFixed(1)}%';
    final coverage = seen == 0
        ? '-'
        : '${(covered * 100 / seen).toStringAsFixed(0)}%';
    return '$scenario: erro $errorRate ($errors/${locks.length}) | '
        'cobertura $coverage ($covered/$seen) | mediana $median';
  }
}
