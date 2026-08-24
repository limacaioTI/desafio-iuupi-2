import 'package:carteira_digital_escolar/core/api_client.dart';
import 'package:carteira_digital_escolar/core/storage_service.dart';
import 'package:carteira_digital_escolar/models/transaction.dart';
import 'package:carteira_digital_escolar/models/user.dart';
import 'package:carteira_digital_escolar/providers/wallet_provider.dart';
import 'package:carteira_digital_escolar/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _user = User(
  id: 1,
  name: 'João da Silva',
  cpf: '12345678900',
  school: 'Escola Exemplo',
  registration: '20260001',
  balance: 58.4,
);

/// A tela chama `load()` assim que monta. Sobrescrever como no-op permite
/// definir o estado do provider diretamente no teste, sem depender de rede
/// ou do Hive real (que exigiria `runAsync`, como nos testes de login).
class _FakeWalletProvider extends WalletProvider {
  _FakeWalletProvider() : super(ApiClient(), StorageService());

  @override
  Future<void> load() async {}
}

Widget _wrap(WalletProvider wallet) {
  return MaterialApp(
    home: ChangeNotifierProvider<WalletProvider>.value(
      value: wallet,
      child: const DashboardScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra nome, saldo e as últimas transações', (tester) async {
    final wallet = _FakeWalletProvider()
      ..status = WalletStatus.success
      ..user = _user
      ..recentTransactions = [
        Transaction(
          id: 1,
          type: TransactionType.credit,
          description: 'Recarga de saldo',
          amount: 50.0,
          createdAt: DateTime(2026, 8, 6, 12, 0),
        ),
      ];

    await tester.pumpWidget(_wrap(wallet));
    await tester.pump();

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.textContaining('58,40'), findsOneWidget);
    expect(find.text('Recarga de saldo'), findsOneWidget);
    expect(find.text('Recarga'), findsOneWidget);
    expect(find.text('Saque'), findsOneWidget);
  });

  testWidgets('mostra o estado vazio quando não há movimentações', (tester) async {
    final wallet = _FakeWalletProvider()
      ..status = WalletStatus.success
      ..user = _user
      ..recentTransactions = [];

    await tester.pumpWidget(_wrap(wallet));
    await tester.pump();

    expect(find.text('Nenhuma movimentação ainda.'), findsOneWidget);
  });

  testWidgets('mostra o banner de offline quando os dados vêm do cache', (tester) async {
    final wallet = _FakeWalletProvider()
      ..status = WalletStatus.offlineWithCache
      ..user = _user;

    await tester.pumpWidget(_wrap(wallet));
    await tester.pump();

    expect(find.textContaining('Sem conexão'), findsOneWidget);
  });

  testWidgets('mostra a tela de erro com botão de tentar novamente', (tester) async {
    final wallet = _FakeWalletProvider()
      ..status = WalletStatus.error
      ..errorMessage = 'Sem conexão com o servidor. Verifique sua internet.';

    await tester.pumpWidget(_wrap(wallet));
    await tester.pump();

    expect(
      find.text('Sem conexão com o servidor. Verifique sua internet.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
