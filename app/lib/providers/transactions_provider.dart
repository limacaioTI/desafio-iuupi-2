import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/storage_service.dart';
import '../models/paginated_transactions.dart';
import '../models/transaction.dart';

enum TransactionsStatus {
  loading,
  success,
  error,
  loadingMore,
  loadMoreError,
  offlineWithCache,
}

enum TransactionFilter { all, credit, debit }

class TransactionsProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  TransactionsProvider(this._apiClient, this._storage);

  TransactionsStatus status = TransactionsStatus.loading;
  TransactionFilter filter = TransactionFilter.all;
  List<Transaction> items = [];
  String? errorMessage;
  DateTime? cacheTimestamp;

  int _page = 1;
  bool _hasNextPage = true;

  Future<void> load() async {
    _page = 1;
    status = TransactionsStatus.loading;
    notifyListeners();
    await _fetchPage(replace: true);
  }

  Future<void> loadMore() async {
    if (status == TransactionsStatus.loadingMore || !_hasNextPage) return;
    status = TransactionsStatus.loadingMore;
    notifyListeners();
    await _fetchPage(replace: false);
  }

  Future<void> changeFilter(TransactionFilter newFilter) async {
    filter = newFilter;
    await load();
  }

  Future<void> _fetchPage({required bool replace}) async {
    try {
      final query = {
        'page': '$_page',
        'per_page': '10',
        if (filter == TransactionFilter.credit) 'type': 'credit',
        if (filter == TransactionFilter.debit) 'type': 'debit',
      };

      final response = await _apiClient.get('/transactions', query: query);
      final page = PaginatedTransactions.fromJson(response);

      items = replace ? page.data : [...items, ...page.data];
      _hasNextPage = page.pagination.hasNextPage;
      _page++;
      status = TransactionsStatus.success;
    } on ApiException catch (e) {
      _handleFetchFailure(replace: replace, fallbackMessage: e.message);
    } on NetworkException catch (e) {
      _handleFetchFailure(
        replace: replace,
        fallbackMessage: e.kind == NetworkErrorKind.timeout
            ? 'A conexão demorou demais para responder. Tente novamente.'
            : 'Sem conexão com o servidor. Verifique sua internet.',
      );
    }

    notifyListeners();
  }

  void _handleFetchFailure({
    required bool replace,
    required String fallbackMessage,
  }) {
    if (replace && _page == 1 && filter == TransactionFilter.all) {
      _loadFromCache(fallbackMessage: fallbackMessage);
    } else if (!replace && items.isNotEmpty) {
      // Falha ao buscar mais itens: mantém a lista já exibida e permite
      // tentar de novo em vez de descartar o que já foi carregado.
      status = TransactionsStatus.loadMoreError;
      errorMessage = fallbackMessage;
    } else {
      status = TransactionsStatus.error;
      errorMessage = fallbackMessage;
    }
  }

  void _loadFromCache({required String fallbackMessage}) {
    final cached = _storage.cachedTransactions;
    if (cached == null || cached.isEmpty) {
      status = TransactionsStatus.error;
      errorMessage = fallbackMessage;
      return;
    }

    items = cached.map(Transaction.fromJson).toList();
    _hasNextPage = false;
    cacheTimestamp = _storage.cachedAt;
    status = TransactionsStatus.offlineWithCache;
  }

  void prependTransaction(Transaction transaction) {
    items = [transaction, ...items];
    notifyListeners();
  }
}
