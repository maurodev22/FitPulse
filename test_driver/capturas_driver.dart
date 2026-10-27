import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver de las capturas de ficha. Guarda cada PNG en `docs/store_assets/capturas/`.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final archivo = File('docs/store_assets/capturas/$name.png');
      await archivo.parent.create(recursive: true);
      await archivo.writeAsBytes(bytes);
      stdout.writeln('captura: ${archivo.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
