import 'package:carteira_digital_escolar/models/transaction.dart';
import 'package:carteira_digital_escolar/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('transação de crédito mostra sinal de + e a descrição', (tester) async {
    final transaction = Transaction(
      id: 1,
      type: TransactionType.credit,
      description: 'Recarga de saldo',
      amount: 50.0,
      createdAt: DateTime(2026, 8, 6, 12, 0),
    );

    await tester.pumpWidget(_wrap(TransactionTile(transaction: transaction)));

    expect(find.text('Recarga de saldo'), findsOneWidget);
    expect(find.textContaining('+'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('transação de débito mostra sinal de - e a descrição', (tester) async {
    final transaction = Transaction(
      id: 2,
      type: TransactionType.debit,
      description: 'Lanche',
      amount: 12.0,
      createdAt: DateTime(2026, 8, 6, 12, 0),
    );

    await tester.pumpWidget(_wrap(TransactionTile(transaction: transaction)));

    expect(find.text('Lanche'), findsOneWidget);
    expect(find.textContaining('-'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('chama onTap ao ser tocado', (tester) async {
    var tapped = false;
    final transaction = Transaction(
      id: 3,
      type: TransactionType.credit,
      description: 'Recarga',
      amount: 10.0,
      createdAt: DateTime(2026, 8, 6, 12, 0),
    );

    await tester.pumpWidget(
      _wrap(TransactionTile(transaction: transaction, onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(TransactionTile));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
