import 'transaction.dart';

class PaginationInfo {
  final int page;
  final int totalPages;

  const PaginationInfo({required this.page, required this.totalPages});

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
}

class PaginatedTransactions {
  final List<Transaction> data;
  final PaginationInfo pagination;

  const PaginatedTransactions({required this.data, required this.pagination});

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    return PaginatedTransactions(
      data: (json['data'] as List)
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}
