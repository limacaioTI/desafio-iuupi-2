import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transactions_provider.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/state_views.dart';
import '../../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().load();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionsProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Extrato')),
      body: ResponsiveContainer(
        child: Column(
          children: [
            if (provider.status == TransactionsStatus.offlineWithCache)
              OfflineBanner(cachedAt: provider.cacheTimestamp),
            _FilterBar(current: provider.filter),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TransactionsProvider provider) {
    if (provider.status == TransactionsStatus.loading) {
      return const LoadingView();
    }

    if (provider.status == TransactionsStatus.error && provider.items.isEmpty) {
      return ErrorView(
        message: provider.errorMessage ?? 'Erro ao carregar extrato.',
        onRetry: provider.load,
      );
    }

    if (provider.items.isEmpty) {
      return const EmptyView(message: 'Nenhuma transação encontrada.');
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: provider.items.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.items.length) {
            return provider.status == TransactionsStatus.loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final transaction = provider.items[index];
          return TransactionTile(
            transaction: transaction,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transaction: transaction),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TransactionFilter current;

  const _FilterBar({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<TransactionFilter>(
        segments: const [
          ButtonSegment(value: TransactionFilter.all, label: Text('Todos')),
          ButtonSegment(value: TransactionFilter.credit, label: Text('Crédito')),
          ButtonSegment(value: TransactionFilter.debit, label: Text('Débito')),
        ],
        selected: {current},
        onSelectionChanged: (selection) {
          context.read<TransactionsProvider>().changeFilter(selection.first);
        },
      ),
    );
  }
}
