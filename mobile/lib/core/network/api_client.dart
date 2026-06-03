import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage;

  /// Called when the backend returns 401. Wired up by authNotifierProvider
  /// to flip the AuthNotifier into unauthenticated state.
  FutureOr<void> Function()? onUnauthorized;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        dio = Dio(BaseOptions(
          baseUrl: AppConstants.backendUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          await onUnauthorized?.call();
        }
        handler.next(err);
      },
    ));
  }
}

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
