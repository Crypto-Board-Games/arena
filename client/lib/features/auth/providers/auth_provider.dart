import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkStoredAuth();
  }

  Future<void> _checkStoredAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final storedAuth = await _authService.getStoredAuth();

      if (storedAuth != null) {
        final refreshedUser = await _authService.refreshUserData(
          storedAuth.token,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: storedAuth.token,
          user: refreshedUser ?? storedAuth.user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: result.token,
          user: result.user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}
