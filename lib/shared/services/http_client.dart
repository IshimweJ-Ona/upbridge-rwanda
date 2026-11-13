// A small injectable JSON client for non-Firebase HTTP endpoints.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class RemoteRequestException implements Exception {
  const RemoteRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Remote request failed (HTTP $statusCode).';
}

class HttpJsonClient {
  HttpJsonClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<Object?> getJson(Uri uri, {Map<String, String> headers = const {}}) =>
      _send(() => _client.get(uri, headers: headers));

  Future<Object?> postJson(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    () => _client.post(
      uri,
      headers: _jsonHeaders(headers),
      body: jsonEncode(body),
    ),
  );

  Future<Object?> putJson(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    () => _client.put(
      uri,
      headers: _jsonHeaders(headers),
      body: jsonEncode(body),
    ),
  );

  Future<void> delete(Uri uri, {Map<String, String> headers = const {}}) async {
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteRequestException(response.statusCode);
    }
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    final response = await request().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteRequestException(response.statusCode);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Map<String, String> _jsonHeaders(Map<String, String> headers) => {
    'content-type': 'application/json',
    ...headers,
  };

  void close() => _client.close();
}
