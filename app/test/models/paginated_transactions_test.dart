import 'package:carteira_digital_escolar/models/paginated_transactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedTransactions.fromJson', () {
    test('mapeia a lista de dados e a paginação', () {
      final json = {
        'data': [
          {
            'id': 1,
            'type': 'credit',
            'description': 'Recarga de saldo',
            'amount': 50.0,
            'created_at': '2026-08-06T12:00:00-03:00',
          },
        ],
        'pagination': {
          'page': 1,
          'per_page': 10,
          'total': 25,
          'total_pages': 3,
        },
      };

      final page = PaginatedTransactions.fromJson(json);

      expect(page.data, hasLength(1));
      expect(page.data.first.id, 1);
      expect(page.pagination.page, 1);
      expect(page.pagination.totalPages, 3);
    });

    test('lida com uma página vazia (além do total)', () {
      final json = {
        'data': [],
        'pagination': {
          'page': 5,
          'per_page': 10,
          'total': 25,
          'total_pages': 3,
        },
      };

      final page = PaginatedTransactions.fromJson(json);

      expect(page.data, isEmpty);
    });
  });

  group('PaginationInfo.hasNextPage', () {
    test('true quando a página atual é menor que o total de páginas', () {
      const pagination = PaginationInfo(page: 1, totalPages: 3);
      expect(pagination.hasNextPage, isTrue);
    });

    test('false quando a página atual é a última', () {
      const pagination = PaginationInfo(page: 3, totalPages: 3);
      expect(pagination.hasNextPage, isFalse);
    });

    test('false quando a página atual passou do total (defensivo)', () {
      const pagination = PaginationInfo(page: 5, totalPages: 3);
      expect(pagination.hasNextPage, isFalse);
    });
  });
}
