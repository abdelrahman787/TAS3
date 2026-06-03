import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_state.dart';

class AuthResult {
  final String accessToken;
  final UserProfile user;
  const AuthResult({required this.accessToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        accessToken: j['accessToken'] as String,
        user: UserProfile.fromJson(j['user'] as Map<String, dynamic>),
      );
}

class AuthRepository {
  static const _tokenKey = 'auth_token';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<AuthResult> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
    });
    final result = AuthResult.fromJson(res.data as Map<String, dynamic>);
    await _storage.write(key: _tokenKey, value: result.accessToken);
    return result;
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final result = AuthResult.fromJson(res.data as Map<String, dynamic>);
    await _storage.write(key: _tokenKey, value: result.accessToken);
    return result;
  }

  Future<UserProfile> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
