import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/storage_service.dart';
import '../models/user.dart';

enum AuthStatus { checking, loggedOut, loggingIn, loggedIn }

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  AuthProvider(this._apiClient, this._storage) {
    _restoreSession();
  }

  AuthStatus status = AuthStatus.checking;
  User? user;
  String? errorMessage;

  void _restoreSession() {
    final token = _storage.token;
    if (token == null) {
      status = AuthStatus.loggedOut;
      notifyListeners();
      return;
    }

    _apiClient.setToken(token);

    final cached = _storage.cachedUser;
    if (cached != null) {
      user = User.fromJson(cached);
    }

    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  Future<bool> login(String cpf, String password) async {
    status = AuthStatus.loggingIn;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/login',
        body: {'cpf': cpf, 'password': password},
      );

      final token = response['access_token'] as String;
      user = User.fromJson(response['user'] as Map<String, dynamic>);

      await _storage.saveToken(token);
      await _storage.cacheUser(response['user'] as Map<String, dynamic>);
      _apiClient.setToken(token);

      status = AuthStatus.loggedIn;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.loggedOut;
      notifyListeners();
      return false;
    } on NetworkException {
      errorMessage = 'Sem conexão com o servidor. Verifique sua internet.';
      status = AuthStatus.loggedOut;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    _apiClient.setToken(null);
    user = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
