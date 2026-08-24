import 'package:carteira_digital_escolar/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('começa em ThemeMode.light quando não há preferência salva', () async {
    final storage = await createTestStorageService();
    final provider = ThemeProvider(storage);

    expect(provider.themeMode, ThemeMode.light);
  });

  test('cycleThemeMode alterna entre claro e escuro', () async {
    final storage = await createTestStorageService();
    final provider = ThemeProvider(storage);

    expect(provider.themeMode, ThemeMode.light);

    await provider.cycleThemeMode();
    expect(provider.themeMode, ThemeMode.dark);

    await provider.cycleThemeMode();
    expect(provider.themeMode, ThemeMode.light);
  });

  test('notifica os listeners a cada mudança de tema', () async {
    final storage = await createTestStorageService();
    final provider = ThemeProvider(storage);

    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.cycleThemeMode();

    expect(notifications, 1);
  });

  test('persiste a escolha: uma nova instância lê o valor salvo', () async {
    final storage = await createTestStorageService();
    final provider = ThemeProvider(storage);

    await provider.setThemeMode(ThemeMode.dark);

    final reloaded = ThemeProvider(storage);
    expect(reloaded.themeMode, ThemeMode.dark);
  });
}
