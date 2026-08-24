import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/transaction.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm');

/// Recebe a transação já carregada da lista (para exibir instantaneamente,
/// sem loading) e, em paralelo, busca `GET /transactions/:id` para exercitar
/// o endpoint obrigatório e refletir qualquer dado mais recente. Uma falha
/// nessa busca em segundo plano é ignorada silenciosamente: o dado da lista
/// já é suficiente para a tela.
class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Transaction _transaction = widget.transaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final response = await context
          .read<ApiClient>()
          .get('/transactions/${widget.transaction.id}');
      if (!mounted) return;
      setState(() => _transaction = Transaction.fromJson(response));
    } catch (_) {
      // Mantém o dado já exibido; a lista de origem já é confiável.
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? Colors.green.shade700 : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da transação')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCredit ? 'Crédito' : 'Débito',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${isCredit ? '+' : '-'} ${_currencyFormat.format(transaction.amount)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Descrição', value: transaction.description),
            _DetailRow(
              label: 'Data',
              value: _dateFormat.format(transaction.createdAt),
            ),
            _DetailRow(label: 'ID da transação', value: '#${transaction.id}'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
