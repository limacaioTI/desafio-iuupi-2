import 'package:flutter/material.dart';

import '../core/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;

  ThemeProvider(this._storage) : themeMode = _readSavedMode(_storage);

  ThemeMode themeMode;

  static ThemeMode _readSavedMode(StorageService storage) {
    return storage.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _storage.saveThemeMode(mode.name);
  }

  static const _cycleOrder = [ThemeMode.light, ThemeMode.dark];

  Future<void> cycleThemeMode() async {
    final nextIndex = (_cycleOrder.indexOf(themeMode) + 1) % _cycleOrder.length;
    await setThemeMode(_cycleOrder[nextIndex]);
  }
}
