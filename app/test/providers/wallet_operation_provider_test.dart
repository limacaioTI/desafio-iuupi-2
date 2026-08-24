import 'dart:convert';

import 'package:carteira_digital_escolar/core/api_client.dart';
import 'package:carteira_digital_escolar/models/transaction.dart';
import 'package:carteira_digital_escolar/models/user.dart';
import 'package:carteira_digital_escolar/providers/transactions_provider.dart';
import 'package:carteira_digital_escolar/providers/wallet_operation_provider.dart';
import 'package:carteira_digital_escolar/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/test_storage.dart';

const _initialUser = User(
  id: 1,
  name: 'João da Silva',
  cpf: '12345678900',
  school: 'Escola Exemplo',
  registration: '20260001',
  balance: 58.4,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('submit com sucesso atualiza o saldo do WalletProvider', () async {
    final storage = await createTestStorageService();
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'transaction': {
              'id': 26,
              'type': 'credit',
              'description': 'Recarga via Pix',
              'amount': 50.0,
              'created_at': '2026-08-06T12:05:00-03:00',
            },
            'balance': 108.4,
          }),
          201,
        );
      }),
    );

    final wallet = WalletProvider(apiClient, storage)..user = _initialUser;
    final transactions = TransactionsProvider(apiClient, storage);
    final operation = WalletOperationProvider(apiClient, wallet, transactions);

    final ok = await operation.submit(
      type: TransactionType.credit,
      amount: 50.0,
      description: 'Recarga via Pix',
    );

    expect(ok, isTrue);
    expect(operation.status, OperationStatus.success);
    expect(operation.resultingBalance, 108.4);
    expect(wallet.user!.balance, 108.4);
  });

  test('nova transação aparece no início do extrato', () async {
    final storage = await createTestStorageService();
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'transaction': {
              'id': 27,
              'type': 'debit',
              'description': 'Saque de saldo',
              'amount': 10.0,
              'created_at': '2026-08-06T12:05:00-03:00',
            },
            'balance': 48.4,
          }),
          201,
        );
      }),
    );

    final wallet = WalletProvider(apiClient, storage)..user = _initialUser;
    final transactions = TransactionsProvider(apiClient, storage)
      ..items = [
        Transaction(
          id: 1,
          type: TransactionType.credit,
          description: 'Recarga antiga',
          amount: 20,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
    final operation = WalletOperationProvider(apiClient, wallet, transactions);

    await operation.submit(type: TransactionType.debit, amount: 10.0);

    expect(transactions.items, hasLength(2));
    expect(transactions.items.first.description, 'Saque de saldo');
  });

  test('saldo insuficiente resulta em status de erro com mensagem específica', () async {
    final storage = await createTestStorageService();
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'insufficient_balance',
            'message': 'Saldo insuficiente para realizar o saque',
          }),
          422,
        );
      }),
    );

    final wallet = WalletProvider(apiClient, storage)..user = _initialUser;
    final transactions = TransactionsProvider(apiClient, storage);
    final operation = WalletOperationProvider(apiClient, wallet, transactions);

    final ok = await operation.submit(type: TransactionType.debit, amount: 1000);

    expect(ok, isFalse);
    expect(operation.status, OperationStatus.error);
    expect(operation.errorMessage, contains('insuficiente'));
    // O saldo não deve ter sido alterado numa operação que falhou.
    expect(wallet.user!.balance, 58.4);
  });

  test('falha de rede resulta em status de erro sem alterar o saldo', () async {
    final storage = await createTestStorageService();
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        throw Exception('falha de rede simulada');
      }),
    );

    final wallet = WalletProvider(apiClient, storage)..user = _initialUser;
    final transactions = TransactionsProvider(apiClient, storage);
    final operation = WalletOperationProvider(apiClient, wallet, transactions);

    final ok = await operation.submit(type: TransactionType.credit, amount: 10);

    expect(ok, isFalse);
    expect(operation.status, OperationStatus.error);
    expect(wallet.user!.balance, 58.4);
  });
}
