import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ícones só do Lucide (contorno, traço 2). Material e Cupertino trazem
/// versões preenchidas e não seguem o manual.
void main() {
  test('Nenhum ícone fora do Lucide em lib/', () {
    final forbidden = RegExp(r'\b(Icons|CupertinoIcons)\.\w+');
    final hits = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) hits.add('${file.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
