import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/licenses.dart';
import 'app/tino_app.dart';

void main() {
  registerTinoLicenses();
  runApp(const ProviderScope(child: TinoApp()));
}
