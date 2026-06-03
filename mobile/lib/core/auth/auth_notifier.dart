import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repo;

  AuthNotifier(this.repo) : super(const AuthState());

  Future<void> init() async {
    final token = await repo.readToken();
    if (token == null || token.isEmpty) {
      state = state.unauthenticated();
      return;
    }
    try {
      final me = await repo.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: me, token: token);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await repo.clearToken();
      }
      state = state.unauthenticated();
    } catch (_) {
      state = state.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final result = await repo.login(email: email, password: password);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: result.user,
      token: result.accessToken,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final result =
        await repo.register(email: email, password: password, displayName: displayName);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: result.user,
      token: result.accessToken,
    );
  }

  Future<void> logout() async {
    await repo.clearToken();
    state = state.unauthenticated();
  }
}
