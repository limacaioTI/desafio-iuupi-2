import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/wallet_operation_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/responsive_container.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Tela de recarga ou saque, conforme [type]. Recebe/valida um valor
/// monetário positivo, permite confirmar ou cancelar, e mostra loading,
/// sucesso e erro (incluindo saldo insuficiente, no caso do saque).
class WalletOperationScreen extends StatelessWidget {
  final TransactionType type;

  const WalletOperationScreen({super.key, required this.type});

  bool get _isRecarga => type == TransactionType.credit;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WalletOperationProvider(
        context.read<ApiClient>(),
        context.read<WalletProvider>(),
        context.read<TransactionsProvider>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(_isRecarga ? 'Recarga' : 'Saque')),
        body: ResponsiveContainer(
          maxWidth: 480,
          child: _OperationForm(type: type),
        ),
      ),
    );
  }
}

class _OperationForm extends StatefulWidget {
  final TransactionType type;

  const _OperationForm({required this.type});

  @override
  State<_OperationForm> createState() => _OperationFormState();
}

class _OperationFormState extends State<_OperationForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get _isRecarga => widget.type == TransactionType.credit;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe um valor';

    final normalized = value.trim().replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null) return 'Valor inválido';
    if (amount <= 0) return 'O valor deve ser positivo';

    final decimals = RegExp(r'\.(\d+)$').firstMatch(normalized)?.group(1);
    if (decimals != null && decimals.length > 2) {
      return 'Use no máximo duas casas decimais';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim().replaceAll(',', '.'));
    final provider = context.read<WalletOperationProvider>();

    await provider.submit(
      type: widget.type,
      amount: amount,
      description: _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final operation = context.watch<WalletOperationProvider>();

    if (operation.status == OperationStatus.success) {
      return _SuccessView(
        isRecarga: _isRecarga,
        newBalance: operation.resultingBalance!,
      );
    }

    final isLoading = operation.status == OperationStatus.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isRecarga ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 56,
              color: _isRecarga ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              _isRecarga
                  ? 'Informe o valor que deseja adicionar ao saldo.'
                  : 'Informe o valor que deseja sacar do saldo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              enabled: !isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !isLoading,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: _isRecarga ? 'Recarga de saldo' : 'Saque de saldo',
                border: const OutlineInputBorder(),
              ),
            ),
            if (operation.status == OperationStatus.error) ...[
              const SizedBox(height: 8),
              Text(
                operation.errorMessage ?? 'Não foi possível concluir a operação.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isRecarga ? 'Confirmar recarga' : 'Confirmar saque'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final bool isRecarga;
  final double newBalance;

  const _SuccessView({required this.isRecarga, required this.newBalance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
          const SizedBox(height: 16),
          Text(
            isRecarga ? 'Recarga concluída!' : 'Saque concluído!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Novo saldo: ${_currencyFormat.format(newBalance)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    );
  }
}
