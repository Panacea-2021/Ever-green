/// The four access levels in the app. Drives RBAC gating of menu items,
/// routes and the audit-log actor role.
enum UserRole {
  superAdmin,
  manager,
  seniorTechnician,
  technician,
  clientAdmin,
  client,
}

extension UserRoleX on UserRole {
  /// Human-readable label shown in the UI (drawer, profile, audit log).
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.seniorTechnician:
        return 'Senior Service Engineer';
      case UserRole.technician:
        return 'Junior Service Engineer';
      case UserRole.clientAdmin:
        return 'Client Admin';
      case UserRole.client:
        return 'Client / POC';
    }
  }

  /// True for any technician-level role (field staff).
  bool get isTechnicianLevel =>
      this == UserRole.technician || this == UserRole.seniorTechnician;

  /// True for any client-side role.
  bool get isClientSide =>
      this == UserRole.client || this == UserRole.clientAdmin;

  /// Stable key used for serialization (== enum name).
  String get key => name;

  /// Unknown keys fall back to the least-privileged role.
  static UserRole fromKey(String? key) {
    return UserRole.values.firstWhere(
      (r) => r.name == key,
      orElse: () => UserRole.client,
    );
  }

  /// Maps the backend `access_level` (+ technician `designation`) to a role.
  static UserRole fromBackend(String? accessLevel, String? designation) {
    switch (accessLevel) {
      case 'eg_super_admin':
        return UserRole.superAdmin;
      case 'eg_admin':
        return UserRole.manager;
      case 'technician':
        return designation == seniorDesignation
            ? UserRole.seniorTechnician
            : UserRole.technician;
      case 'client_admin':
        return UserRole.clientAdmin;
      default:
        return UserRole.client;
    }
  }

  /// Backend `access_level` value for this role.
  String get accessLevel {
    switch (this) {
      case UserRole.superAdmin:
        return 'eg_super_admin';
      case UserRole.manager:
        return 'eg_admin';
      case UserRole.seniorTechnician:
      case UserRole.technician:
        return 'technician';
      case UserRole.clientAdmin:
        return 'client_admin';
      case UserRole.client:
        return 'client';
    }
  }

  /// Backend technician `designation` for this role, or null.
  String? get designation {
    switch (this) {
      case UserRole.seniorTechnician:
        return seniorDesignation;
      case UserRole.technician:
        return juniorDesignation;
      default:
        return null;
    }
  }

  static const seniorDesignation = 'Senior Service Engineer';
  static const juniorDesignation = 'Junior Service Engineer';

  /// Designation still stored on older backend rows; parsed as junior.
  static const legacyJuniorDesignation = 'Junior Technician';

  /// Whether [designation] is a junior designation (current or legacy).
  static bool isJuniorDesignation(String? designation) =>
      designation == juniorDesignation ||
      designation == legacyJuniorDesignation;
}

/// A company the user is linked to through `company_user`.
class UserCompany {
  final int id;
  final String name;
  final String branchName;

  const UserCompany(
      {required this.id, required this.name, this.branchName = ''});

  factory UserCompany.fromJson(Map<String, dynamic> json) => UserCompany(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        branchName: json['branch_name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'branch_name': branchName};
}

class User {
  /// Backend `user.id` as a string.
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String phone;
  final String location;
  final String? designation;
  final List<UserCompany> companies;
  final bool isActive;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? profilePictureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.client,
    this.phone = '',
    this.location = '',
    this.designation,
    this.companies = const [],
    this.isActive = true,
    this.bio,
    this.dateOfBirth,
    this.profilePictureUrl,
    this.createdAt,
    this.updatedAt,
  });

  int get backendId => int.tryParse(id) ?? 0;

  /// The first linked company, used to lock company pickers for client roles.
  UserCompany? get primaryCompany => companies.isEmpty ? null : companies.first;

  /// Parses a backend user row (`auth/signIn` data, `auth/me`, `getAllUser`).
  factory User.fromBackend(Map<String, dynamic> json) {
    final links = json['company_user'];
    final companies = <UserCompany>[];
    if (links is List) {
      for (final link in links) {
        final company = link is Map ? link['company'] : null;
        if (company is Map<String, dynamic>) {
          companies.add(UserCompany.fromJson(company));
        }
      }
    }
    // `getAllUser` flattens the links into `companies`.
    final flat = json['companies'];
    if (companies.isEmpty && flat is List) {
      companies.addAll(
        flat
            .whereType<Map<String, dynamic>>()
            .where((c) => c['id'] is num)
            .map(UserCompany.fromJson),
      );
    }
    final designation = json['designation']?.toString();
    return User(
      id: '${json['id']}',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role:
          UserRoleX.fromBackend(json['access_level']?.toString(), designation),
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      designation: designation,
      companies: companies,
      isActive: json['is_active'] != false,
      bio: json['bio']?.toString(),
      dateOfBirth: DateTime.tryParse(json['date_of_birth']?.toString() ?? ''),
      profilePictureUrl: json['avatar_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Local session format (see [toJson]).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: '${json['id']}',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: UserRoleX.fromKey(json['role'] as String?),
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      designation: json['designation']?.toString(),
      companies: (json['companies'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UserCompany.fromJson)
          .toList(),
      isActive: json['isActive'] != false,
      bio: json['bio']?.toString(),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.key,
      'phone': phone,
      'location': location,
      'designation': designation,
      'companies': companies.map((c) => c.toJson()).toList(),
      'isActive': isActive,
      'bio': bio,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? location,
    String? designation,
    List<UserCompany>? companies,
    bool? isActive,
    String? bio,
    DateTime? dateOfBirth,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      designation: designation ?? this.designation,
      companies: companies ?? this.companies,
      isActive: isActive ?? this.isActive,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
    };
  }
}

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}
