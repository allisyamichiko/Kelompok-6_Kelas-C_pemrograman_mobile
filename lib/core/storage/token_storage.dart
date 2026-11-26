import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'teamly_access_token';
  static const _userKey = 'teamly_user_json';
  static const _workspaceKey = 'teamly_workspace_cache';
  static const _apiUrlKey = 'teamly_api_base_url';

  Future<void> saveApiBaseUrl(String url) => _storage.write(key: _apiUrlKey, value: url);
  Future<String?> readApiBaseUrl() => _storage.read(key: _apiUrlKey);

  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> read() => _storage.read(key: _tokenKey);
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWorkspaceCache(Map<String, dynamic> data) =>
      _storage.write(key: _workspaceKey, value: jsonEncode(data));

  Future<Map<String, dynamic>?> readWorkspaceCache() async {
    final raw = await _storage.read(key: _workspaceKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearWorkspaceCache() => _storage.delete(key: _workspaceKey);
}
