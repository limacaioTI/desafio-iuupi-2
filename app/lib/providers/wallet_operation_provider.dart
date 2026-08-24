import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/transaction.dart';
import 'transactions_provider.dart';
import 'wallet_provider.dart';

enum OperationStatus { idle, loading, success, error }

/// Orquestra uma recarga ou saque: chama a API e, em caso de sucesso,
/// propaga o novo saldo e a transação para o WalletProvider (Dashboard) e o
/// TransactionsProvider (Extrato), que já expunham exatamente os métodos
/// necessários para isso (`applyBalanceUpdate` e `prependTransaction`).
class WalletOperationProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final WalletProvider _wallet;
  final TransactionsProvider _transactions;

  WalletOperationProvider(this._apiClient, this._wallet, this._transactions);

  OperationStatus status = OperationStatus.idle;
  String? errorMessage;
  double? resultingBalance;

  Future<bool> submit({
    required TransactionType type,
    required double amount,
    String? description,
  }) async {
    status = OperationStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'type': type == TransactionType.credit ? 'credit' : 'debit',
        'amount': amount,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      };

      final response = await _apiClient.post('/transactions', body: body);
      final transaction = Transaction.fromJson(
        response['transaction'] as Map<String, dynamic>,
      );
      final newBalance = (response['balance'] as num).toDouble();

      _wallet.applyBalanceUpdate(newBalance, transaction);
      _transactions.prependTransaction(transaction);

      resultingBalance = newBalance;
      status = OperationStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.isInsufficientBalance
          ? 'Saldo insuficiente para concluir essa operação.'
          : e.message;
      status = OperationStatus.error;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      errorMessage = e.kind == NetworkErrorKind.timeout
          ? 'A operação demorou demais para responder. Tente novamente.'
          : 'Sem conexão com o servidor. Verifique sua internet.';
      status = OperationStatus.error;
      notifyListeners();
      return false;
    }
  }
}
