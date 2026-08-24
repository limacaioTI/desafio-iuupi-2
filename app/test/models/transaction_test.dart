import 'package:carteira_digital_escolar/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction.fromJson', () {
    test('mapeia transação de crédito', () {
      final json = {
        'id': 1,
        'type': 'credit',
        'description': 'Recarga de saldo',
        'amount': 50.0,
        'created_at': '2026-08-06T12:00:00-03:00',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 1);
      expect(transaction.type, TransactionType.credit);
      expect(transaction.description, 'Recarga de saldo');
      expect(transaction.amount, 50.0);
      expect(transaction.createdAt, DateTime.parse('2026-08-06T12:00:00-03:00'));
    });

    test('mapeia transação de débito', () {
      final json = {
        'id': 2,
        'type': 'debit',
        'description': 'Lanche',
        'amount': 12.0,
        'created_at': '2026-08-06T12:00:00-03:00',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.type, TransactionType.debit);
    });

    test('amount sempre positivo, tanto para crédito quanto débito', () {
      final debit = Transaction.fromJson({
        'id': 3,
        'type': 'debit',
        'description': 'Almoço',
        'amount': 22.5,
        'created_at': '2026-08-06T12:00:00-03:00',
      });

      // Contrato da API: amount nunca vem negativo; quem decide o sinal
      // exibido é a UI, com base no `type`.
      expect(debit.amount, greaterThan(0));
    });
  });

  group('Transaction.toJson', () {
    test('serializa o type de volta para a string da API', () {
      final transaction = Transaction(
        id: 1,
        type: TransactionType.credit,
        description: 'Recarga via Pix',
        amount: 50,
        createdAt: DateTime.parse('2026-08-06T12:00:00-03:00'),
      );

      final json = transaction.toJson();

      expect(json['type'], 'credit');
      expect(json['description'], 'Recarga via Pix');
    });

    test('round-trip fromJson(toJson()) preserva os dados', () {
      final original = Transaction(
        id: 5,
        type: TransactionType.debit,
        description: 'Saque de saldo',
        amount: 10,
        createdAt: DateTime.parse('2026-08-06T12:00:00-03:00'),
      );

      final roundTripped = Transaction.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.type, original.type);
      expect(roundTripped.amount, original.amount);
      expect(roundTripped.createdAt, original.createdAt);
    });
  });
}
