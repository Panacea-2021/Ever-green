import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/evergreen_repository.dart';
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
      // Unblock the UI immediately from the cached session user (if any) so
      // the Dashboard can start rendering while `auth/me` refreshes in the
      // background. This avoids waiting on a slow/cold backend before any
      // screen can paint.
      final storage = _ref.read(tokenStorageProvider);
      final cachedJson = await storage
          .getSessionUser()
          .timeout(const Duration(milliseconds: 100), onTimeout: () => null);
      User? cachedUser;
      if (cachedJson != null) {
        try {
          cachedUser = User.fromJson(cachedJson);
        } catch (_) {
          cachedUser = null;
        }
      }
      if (cachedUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          isLoading: false,
          user: cachedUser,
        );
      }
      // Refresh the user from the backend (validates the token).
      final result = await repo.getCurrentUser();
      await result.fold(
        (_) async {
          if (cachedUser == null) {
            await repo.logout();
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
          // Otherwise keep the cached session; a transient backend failure
          // must not log the user out.
        },
        (user) async => setAuthenticated(user),
      );
    } catch (_) {
      final cached = await _ref
          .read(tokenStorageProvider)
          .getSessionUser()
          .timeout(const Duration(milliseconds: 100), onTimeout: () => null);
      if (cached != null) {
        try {
          state = AuthState(
            status: AuthStatus.authenticated,
            isLoading: false,
            user: User.fromJson(cached),
          );
          return;
        } catch (_) {}
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading, errorMessage: null);
  }

  /// Drops cached reads that were scoped to the previous session. Those
  /// providers keep their value for a while after their last listener leaves;
  /// without this a technician signing in right after an admin would briefly
  /// see the admin's companies/AMC renewals.
  void _clearSessionScopedCaches() {
    _ref.invalidate(companiesProvider);
    _ref.invalidate(tasksProvider);
    _ref.invalidate(deletedTasksProvider);
    _ref.invalidate(equipmentsProvider);
    _ref.invalidate(techniciansProvider);
  }

  void setAuthenticated(User user) {
    // Only drop session-scoped caches when the signed-in user actually
    // changes, so a background refresh of the same user does not trigger a
    // redundant refetch of dashboard/task data.
    if (state.user?.id != user.id) {
      _clearSessionScopedCaches();
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      isLoading: false,
      user: user,
    );
    unawaited(_ref.read(pushServiceProvider).registerForUser());
  }

  void setUnauthenticated([String? errorMessage]) {
    _clearSessionScopedCaches();
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
    _clearSessionScopedCaches();
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
