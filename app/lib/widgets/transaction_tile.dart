import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final sign = isCredit ? '+' : '-';
    final color = isCredit ? Colors.green.shade700 : Colors.red.shade700;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          semanticLabel: isCredit ? 'Crédito' : 'Débito',
        ),
      ),
      title: Text(transaction.description),
      subtitle: Text(_dateFormat.format(transaction.createdAt)),
      trailing: Text(
        '$sign ${_currencyFormat.format(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
