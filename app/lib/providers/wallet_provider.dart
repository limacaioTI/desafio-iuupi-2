import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/storage_service.dart';
import '../models/transaction.dart';
import '../models/user.dart';

enum WalletStatus { loading, success, error, offlineWithCache }

class WalletProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  WalletProvider(this._apiClient, this._storage);

  WalletStatus status = WalletStatus.loading;
  User? user;
  List<Transaction> recentTransactions = [];
  String? errorMessage;
  DateTime? cacheTimestamp;

  Future<void> load() async {
    status = WalletStatus.loading;
    notifyListeners();

    try {
      final meResponse = await _apiClient.get('/me');
      final transactionsResponse = await _apiClient.get(
        '/transactions',
        query: {'per_page': '5'},
      );

      user = User.fromJson(meResponse);
      recentTransactions = (transactionsResponse['data'] as List)
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList();

      await _storage.cacheUser(meResponse);
      await _storage.cacheTransactions(
        (transactionsResponse['data'] as List).cast<Map<String, dynamic>>(),
      );

      status = WalletStatus.success;
    } on ApiException catch (e) {
      _loadFromCache(fallbackMessage: e.message);
    } on NetworkException catch (e) {
      _loadFromCache(
        fallbackMessage: e.kind == NetworkErrorKind.timeout
            ? 'A conexão demorou demais para responder. Tente novamente.'
            : 'Sem conexão com o servidor. Verifique sua internet.',
      );
    }

    notifyListeners();
  }

  void _loadFromCache({required String fallbackMessage}) {
    final cachedUser = _storage.cachedUser;
    final cachedTransactions = _storage.cachedTransactions;

    if (cachedUser == null) {
      status = WalletStatus.error;
      errorMessage = fallbackMessage;
      return;
    }

    user = User.fromJson(cachedUser);
    recentTransactions = (cachedTransactions ?? [])
        .take(5)
        .map(Transaction.fromJson)
        .toList();
    cacheTimestamp = _storage.cachedAt;
    status = WalletStatus.offlineWithCache;
  }

  /// Chamado após recarga/saque para refletir o novo saldo sem novo GET.
  void applyBalanceUpdate(double newBalance, Transaction newTransaction) {
    if (user == null) return;
    user = User(
      id: user!.id,
      name: user!.name,
      cpf: user!.cpf,
      school: user!.school,
      registration: user!.registration,
      balance: newBalance,
      avatarUrl: user!.avatarUrl,
    );
    recentTransactions = [newTransaction, ...recentTransactions].take(5).toList();
    notifyListeners();
  }
}
