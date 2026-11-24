import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.status, this.message);

  /// 0 = tidak bisa terhubung ke server.
  final int status;
  final String message;

  bool get isConflict => status == 409;

  @override
  String toString() => message;
}

/// Service API: semua request lewat sini, token Bearer disisipkan otomatis.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _tokenKey = 'auth_token';

  String? _token;
  String? get token => _token;

  /// Dipanggil saat server menjawab 401 padahal token sudah dikirim (sesi habis).
  void Function()? onUnauthorized;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    var uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (body != null) request.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 15));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException(
        0,
        'Tidak bisa terhubung ke server. Periksa alamat server (${AppConfig.apiBaseUrl}) dan koneksi.',
      );
    }

    Map<String, dynamic> json = {};
    if (res.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // Bukan JSON (mis. halaman error HTML); pakai pesan umum di bawah.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    if (res.statusCode == 401 && _token != null) onUnauthorized?.call();

    var message = (json['message'] is String)
        ? json['message'] as String
        : 'Terjadi kesalahan (${res.statusCode}).';
    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) message = first.first.toString();
    }
    throw ApiException(res.statusCode, message);
  }
}
