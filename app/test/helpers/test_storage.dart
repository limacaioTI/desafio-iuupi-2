import 'dart:io';

import 'package:carteira_digital_escolar/core/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cria um [StorageService] isolado para testes: usa `Hive.init` com um
/// diretório temporário (não depende do path_provider, que exige um binding
/// de plataforma real) e um sufixo único de box por chamada, para que testes
/// em paralelo não colidam nos mesmos dados.
Future<StorageService> createTestStorageService() async {
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);

  final suffix = '_${DateTime.now().microsecondsSinceEpoch}';
  final storage = StorageService(boxSuffix: suffix);
  await storage.init(useFlutterInit: false);
  return storage;
}
