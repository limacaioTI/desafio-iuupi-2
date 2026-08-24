import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  final String _boxSuffix;

  StorageService({String boxSuffix = ''}) : _boxSuffix = boxSuffix;

  String get _sessionBoxName => 'session$_boxSuffix';
  String get _cacheBoxName => 'cache$_boxSuffix';
  String get _settingsBoxName => 'settings$_boxSuffix';

  static const _tokenKey = 'token';
  static const _userKey = 'user';
  static const _transactionsKey = 'transactions';
  static const _cachedAtKey = 'cached_at';
  static const _themeModeKey = 'theme_mode';

  late final Box _sessionBox;
  late final Box _cacheBox;
  late final Box _settingsBox;

  Future<void> init({bool useFlutterInit = true}) async {
    if (useFlutterInit) {
      await Hive.initFlutter();
    }
    _sessionBox = await Hive.openBox(_sessionBoxName);
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  String? get themeMode => _settingsBox.get(_themeModeKey) as String?;

  Future<void> saveThemeMode(String mode) =>
      _settingsBox.put(_themeModeKey, mode);

  String? get token => _sessionBox.get(_tokenKey) as String?;

  Future<void> saveToken(String token) => _sessionBox.put(_tokenKey, token);

  Future<void> clearSession() async {
    await _sessionBox.clear();
    await _cacheBox.clear();
  }

  Future<void> cacheUser(Map<String, dynamic> userJson) async {
    await _cacheBox.put(_userKey, jsonEncode(userJson));
    await _cacheBox.put(_cachedAtKey, DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? get cachedUser {
    final raw = _cacheBox.get(_userKey) as String?;
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  DateTime? get cachedAt {
    final raw = _cacheBox.get(_cachedAtKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> cacheTransactions(List<Map<String, dynamic>> items) {
    return _cacheBox.put(_transactionsKey, jsonEncode(items));
  }

  List<Map<String, dynamic>>? get cachedTransactions {
    final raw = _cacheBox.get(_transactionsKey) as String?;
    return raw == null ? null : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }
}
