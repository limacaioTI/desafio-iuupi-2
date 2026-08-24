import 'dart:convert';

import 'package:carteira_digital_escolar/core/api_client.dart';
import 'package:carteira_digital_escolar/core/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient.get', () {
    test('retorna o corpo decodificado em caso de sucesso (200)', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(jsonEncode({'name': 'João'}), 200);
        }),
      );

      final result = await client.get('/me');

      expect(result, {'name': 'João'});
    });

    test('inclui o header Authorization depois de setToken', () async {
      String? capturedAuthHeader;

      final client = ApiClient(
        httpClient: MockClient((request) async {
          capturedAuthHeader = request.headers['Authorization'];
          return http.Response('{}', 200);
        }),
      );
      client.setToken('desafio-mobile-token');

      await client.get('/me');

      expect(capturedAuthHeader, 'Bearer desafio-mobile-token');
    });

    test('lança ApiException com os dados do erro em respostas 4xx/5xx', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': 'unauthorized',
              'message': 'Token ausente ou inválido',
            }),
            401,
          );
        }),
      );

      expect(
        () => client.get('/me'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.error, 'error', 'unauthorized')
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
        ),
      );
    });

    test('lança ApiException com isInsufficientBalance quando o saque falha', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': 'insufficient_balance',
              'message': 'Saldo insuficiente',
            }),
            422,
          );
        }),
      );

      expect(
        () => client.post('/transactions', body: {'type': 'debit', 'amount': 1000}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isInsufficientBalance,
            'isInsufficientBalance',
            isTrue,
          ),
        ),
      );
    });

    test('lança NetworkException(noConnection) quando a chamada falha', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          throw const SocketExceptionStub();
        }),
      );

      expect(
        () => client.get('/me'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.kind,
            'kind',
            NetworkErrorKind.noConnection,
          ),
        ),
      );
    });

    test('lança NetworkException(timeout) quando a resposta demora demais', () async {
      final client = ApiClient(
        timeout: const Duration(milliseconds: 50),
        httpClient: MockClient((request) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );

      expect(
        () => client.get('/simulate/slow'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.kind,
            'kind',
            NetworkErrorKind.timeout,
          ),
        ),
      );
    });
  });

  group('ApiClient.post', () {
    test('envia o body como JSON', () async {
      Map<String, dynamic>? capturedBody;

      final client = ApiClient(
        httpClient: MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'balance': 108.4}), 201);
        }),
      );

      await client.post('/transactions', body: {'type': 'credit', 'amount': 50.0});

      expect(capturedBody, {'type': 'credit', 'amount': 50.0});
    });
  });
}

/// Simula uma falha de conexão (ex.: SocketException) sem depender de
/// dart:io diretamente no teste.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
