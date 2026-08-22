import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/wallet_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/state_views.dart';
import '../../widgets/transaction_tile.dart';
import '../profile/profile_screen.dart';
import '../statement/statement_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _buildBody(wallet),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatementScreen()),
        ),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Extrato'),
      ),
    );
  }

  Widget _buildBody(WalletProvider wallet) {
    if (wallet.status == WalletStatus.loading && wallet.user == null) {
      return const LoadingView();
    }

    if (wallet.status == WalletStatus.error) {
      return ErrorView(
        message: wallet.errorMessage ?? 'Erro ao carregar dados.',
        onRetry: wallet.load,
      );
    }

    final user = wallet.user!;

    return RefreshIndicator(
      onRefresh: wallet.load,
      child: ResponsiveContainer(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (wallet.status == WalletStatus.offlineWithCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OfflineBanner(cachedAt: wallet.cacheTimestamp),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user.avatarUrl ?? '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.person),
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BalanceCard(balance: user.balance),
          const SizedBox(height: 24),
          Text(
            'Últimas movimentações',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (wallet.recentTransactions.isEmpty)
            const EmptyView(message: 'Nenhuma movimentação ainda.')
          else
            ...wallet.recentTransactions.map(
              (t) => TransactionTile(transaction: t),
            ),
        ],
        ),
      ),
    );
  }
}
