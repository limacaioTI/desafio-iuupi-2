import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(App(storageService: storageService));
}
