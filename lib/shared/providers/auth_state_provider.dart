import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/push_service.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

/// Tracks whether the app has finished checking persisted session on startup.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription<void>? _expirySub;

  AuthStateNotifier(this._ref) : super(const AuthState()) {
    _expirySub = _ref.read(tokenStorageProvider).sessionExpired.listen((_) {
      if (state.isAuthenticated) {
        setUnauthenticated('Session expired. Please sign in again.');
      }
    });
    _restoreSession();
  }

  /// A stored token is only trusted once a user can be resolved for it
  /// (from `auth/me` or the cached session); otherwise the user signs in again.
  Future<void> _restoreSession() async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      if (!await repo.isAuthenticated()) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final result = await repo.getCurrentUser();
      await result.fold(
        (_) async {
          await repo.logout();
          state = const AuthState(status: AuthStatus.unauthenticated);
        },
        (user) async => setAuthenticated(user),
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading, errorMessage: null);
  }

  void setAuthenticated(User user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      isLoading: false,
      user: user,
    );
    unawaited(_ref.read(pushServiceProvider).registerForUser());
  }

  void setUnauthenticated([String? errorMessage]) {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: false,
      errorMessage: errorMessage,
    );
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
    unawaited(_ref.read(tokenStorageProvider).saveSessionUser(user.toJson()));
  }

  void logout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _expirySub?.cancel();
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

// Convenient providers for accessing auth state
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

/// The role of the signed-in user. Falls back to the least-privileged role
/// while no user is loaded.
final currentUserRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authStateProvider).user?.role ?? UserRole.client;
});
