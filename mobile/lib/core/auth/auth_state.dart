import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

@immutable
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String?,
        createdAt:
            j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}

@immutable
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? token;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.token,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && token != null;

  AuthState copyWith({AuthStatus? status, UserProfile? user, String? token}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        token: token ?? this.token,
      );

  AuthState unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated, user: null, token: null);
}
