class Profile {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? phone;
  final String? profilePictureUrl;
  final DateTime? dateOfBirth;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.phone,
    this.profilePictureUrl,
    this.dateOfBirth,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      location: json['location'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class UpdateProfileRequest {
  final String? name;
  final String? bio;
  final String? phone;
  final String? location;
  final DateTime? dateOfBirth;

  const UpdateProfileRequest({
    this.name,
    this.bio,
    this.phone,
    this.location,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    };
  }
}
