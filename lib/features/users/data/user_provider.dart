import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/data/evergreen_repository.dart';
import '../../../core/router/routes.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../auth/domain/models/user_model.dart';

/// `user/getAllUser` answers EverGreen admins (all users) and client admins
/// (users of their companies); the screen must also be routable.
bool canListUsers(UserRole role) =>
    _canQueryUsers(role) && Permissions.canAccessRoute(role, Routes.usersList);

bool _canQueryUsers(UserRole role) =>
    role == UserRole.superAdmin ||
    role == UserRole.manager ||
    role == UserRole.clientAdmin;

bool canDeleteUsers(UserRole role) => role == UserRole.superAdmin;

/// Users visible to the signed-in admin (backend-scoped for client admins).
/// Empty for roles the backend refuses.
final usersListProvider = FutureProvider.autoDispose<List<User>>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  if (!_canQueryUsers(role)) {
    return Future.value(const <User>[]);
  }
  return ref.watch(evergreenRepositoryProvider).getUsers();
});

/// A managed application user (distinct from the logged-in auth [User]).
class AppUser {
  final String id;
  final String name;
  final String mobile;
  final UserRole role;

  /// Backend `is_active`; inactive users cannot sign in.
  final bool active;
  final String email;
  final String location;
  final String? designation;
  final List<UserCompany> companies;
  final String? avatarUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.mobile,
    required this.role,
    this.active = true,
    this.email = '',
    this.location = '',
    this.designation,
    this.companies = const [],
    this.avatarUrl,
    this.createdAt,
  });

  factory AppUser.fromUser(User user) => AppUser(
        id: user.id,
        name: user.name,
        mobile: user.phone,
        role: user.role,
        active: user.isActive,
        email: user.email,
        location: user.location,
        designation: user.designation,
        companies: user.companies,
        avatarUrl: user.profilePictureUrl,
        createdAt: user.createdAt,
      );

  bool get isActive => active;

  int get backendId => int.tryParse(id) ?? 0;

  String get companyNames => companies
      .map((c) => c.branchName.isEmpty ? c.name : '${c.name} - ${c.branchName}')
      .join(', ');

  AppUser copyWith({
    String? name,
    String? mobile,
    UserRole? role,
    bool? active,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      active: active ?? this.active,
      email: email,
      location: location,
      designation: designation,
      companies: companies,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'role': role.key,
        'active': active,
        'email': email,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      role: UserRoleX.fromKey(json['role'] as String?),
      active: json['active'] as bool? ?? true,
      email: json['email'] as String? ?? '',
    );
  }
}

/// Mirrors [usersListProvider] as a plain list for widgets that only need the
/// current snapshot. To change users, call the backend and invalidate
/// [usersListProvider].
class UserNotifier extends StateNotifier<List<AppUser>> {
  UserNotifier() : super(const []);

  void setAll(List<AppUser> users) => state = users;

  void add(AppUser user) => state = [user, ...state];

  void toggleActive(String id) {
    state = [
      for (final u in state)
        if (u.id == id) u.copyWith(active: !u.active) else u,
    ];
  }

  void changeRole(String id, UserRole role) {
    state = [
      for (final u in state)
        if (u.id == id) u.copyWith(role: role) else u,
    ];
  }
}

final userProvider = StateNotifierProvider<UserNotifier, List<AppUser>>((ref) {
  final notifier = UserNotifier();
  ref.listen<AsyncValue<List<User>>>(
    usersListProvider,
    (_, next) => next.whenData(
      (users) => notifier.setAll(users.map(AppUser.fromUser).toList()),
    ),
    fireImmediately: true,
  );
  return notifier;
});

/// Counts of users per role, derived from [userProvider].
final userCountsByRoleProvider = Provider<Map<UserRole, int>>((ref) {
  final users = ref.watch(userProvider);
  final counts = <UserRole, int>{
    for (final r in UserRole.values) r: 0,
  };
  for (final u in users) {
    counts[u.role] = (counts[u.role] ?? 0) + 1;
  }
  return counts;
});

/// Technicians for assignment pickers (admins only; see [usersListProvider]).
final techniciansProvider = Provider<List<AppUser>>((ref) {
  return ref
      .watch(userProvider)
      .where((u) => u.role.isTechnicianLevel && u.active)
      .toList();
});
