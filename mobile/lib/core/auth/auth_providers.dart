import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../network/api_client.dart';
import 'auth_notifier.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final secureStorageProvider =
    Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

/// A dedicated Dio for the auth endpoints — no token interceptor here so
/// login/register can succeed before the user has a token.
final _authDioProvider = Provider<Dio>(
  (_) => Dio(BaseOptions(
    baseUrl: AppConstants.backendUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  )),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(_authDioProvider),
    storage: ref.watch(secureStorageProvider),
  ),
);

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.watch(authRepositoryProvider));

  // Wire the global ApiClient's 401 callback to log the user out so the
  // UI can route back to LoginScreen. ApiClient must be initialised in
  // the same scope; we attach lazily on first read.
  ref.listen<ApiClient>(apiClientProvider, (_, client) {
    client.onUnauthorized = () async {
      await notifier.logout();
    };
  }, fireImmediately: true);

  return notifier;
});
