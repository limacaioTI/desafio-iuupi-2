import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  static const _defaultTimeout = Duration(seconds: 8);

  final http.Client _httpClient;
  final Duration _timeout;
  String? _token;

  ApiClient({http.Client? httpClient, Duration? timeout})
    : _httpClient = httpClient ?? http.Client(),
      _timeout = timeout ?? _defaultTimeout;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _send(() => _httpClient.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    final uri = Uri.parse('$baseUrl$path');
    return _send(
      () => _httpClient.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException(NetworkErrorKind.timeout);
    } catch (_) {
      throw const NetworkException(NetworkErrorKind.noConnection);
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      statusCode: response.statusCode,
      error: decoded['error'] as String? ?? 'unknown_error',
      message: decoded['message'] as String? ?? 'Erro desconhecido',
    );
  }
}
