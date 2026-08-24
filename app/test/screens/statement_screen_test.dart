import 'package:carteira_digital_escolar/core/api_client.dart';
import 'package:carteira_digital_escolar/core/storage_service.dart';
import 'package:carteira_digital_escolar/models/transaction.dart';
import 'package:carteira_digital_escolar/providers/transactions_provider.dart';
import 'package:carteira_digital_escolar/screens/statement/statement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// A tela chama `load()` assim que monta e `loadMore()` ao rolar. Sobrescrever
/// como no-op (e contar as chamadas de `loadMore`) permite definir o estado
/// diretamente no teste, sem depender de rede real — mesma ideia do
/// `_FakeWalletProvider` do teste do Dashboard.
class _FakeTransactionsProvider extends TransactionsProvider {
  _FakeTransactionsProvider() : super(ApiClient(), StorageService());

  int loadMoreCalls = 0;

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
  }
}

Widget _wrap(TransactionsProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<TransactionsProvider>.value(
      value: provider,
      child: const StatementScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra a lista de transações e a barra de filtros', (tester) async {
    final provider = _FakeTransactionsProvider()
      ..status = TransactionsStatus.success
      ..items = [
        Transaction(
          id: 1,
          type: TransactionType.credit,
          description: 'Recarga',
          amount: 50,
          createdAt: DateTime(2026, 8, 6),
        ),
        Transaction(
          id: 2,
          type: TransactionType.debit,
          description: 'Lanche',
          amount: 12,
          createdAt: DateTime(2026, 8, 5),
        ),
      ];

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.text('Recarga'), findsOneWidget);
    expect(find.text('Lanche'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
    expect(find.text('Débito'), findsOneWidget);
  });

  testWidgets('mostra o estado vazio quando não há transações', (tester) async {
    final provider = _FakeTransactionsProvider()
      ..status = TransactionsStatus.success
      ..items = [];

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.text('Nenhuma transação encontrada.'), findsOneWidget);
  });

  testWidgets('mostra erro com retry quando a primeira página falha', (tester) async {
    final provider = _FakeTransactionsProvider()
      ..status = TransactionsStatus.error
      ..errorMessage = 'Não foi possível carregar o extrato. Tente novamente.';

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(
      find.text('Não foi possível carregar o extrato. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('mostra o banner de offline quando o extrato vem do cache', (tester) async {
    final provider = _FakeTransactionsProvider()
      ..status = TransactionsStatus.offlineWithCache
      ..items = [
        Transaction(
          id: 1,
          type: TransactionType.credit,
          description: 'Recarga',
          amount: 50,
          createdAt: DateTime(2026, 8, 6),
        ),
      ];

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.textContaining('Sem conexão'), findsOneWidget);
  });

  testWidgets(
    'mostra botão de tentar novamente ao fim da lista quando a paginação falha, sem perder os itens já carregados',
    (tester) async {
      final provider = _FakeTransactionsProvider()
        ..status = TransactionsStatus.loadMoreError
        ..errorMessage = 'Não foi possível carregar mais itens.'
        ..items = [
          Transaction(
            id: 1,
            type: TransactionType.credit,
            description: 'Recarga',
            amount: 50,
            createdAt: DateTime(2026, 8, 6),
          ),
        ];

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.text('Recarga'), findsOneWidget);
      expect(find.text('Não foi possível carregar mais itens.'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(provider.loadMoreCalls, greaterThanOrEqualTo(1));
    },
  );
}
