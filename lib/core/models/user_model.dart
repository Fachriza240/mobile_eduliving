class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profilePicture;
  final bool isActive;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profilePicture,
    required this.isActive,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> roleList = [];
    if (json['roles'] != null && json['roles'] is List) {
      roleList = List<String>.from(
        (json['roles'] as List).map((r) {
          if (r is Map) return r['name'] ?? '';
          return r.toString();
        }),
      );
    }

    return UserModel(
      id             : json['id'] ?? 0,
      name           : json['name'] ?? '',
      email          : json['email'] ?? '',
      phone          : json['phone'],
      address        : json['address'],
      profilePicture : json['profile_picture'],
      isActive       : json['is_active'] ?? true,
      roles          : roleList,
    );
  }

  // ── Cek Role ─────────────────────────────────────────
  bool get isUser             => roles.contains('user');
  bool get isProviderResidence=> roles.contains('provider_residence');
  bool get isProviderEvent    => roles.contains('provider_event');
  bool get isAdmin            => roles.contains('admin');

  // Role utama (untuk navigasi & badge)
  String get primaryRole {
    if (isAdmin)             return 'admin';
    if (isProviderResidence) return 'provider_residence';
    if (isProviderEvent)     return 'provider_event';
    return 'user';
  }

  // Label role dalam Bahasa Indonesia
  String get roleLabel {
    switch (primaryRole) {
      case 'admin':              return 'Administrator';
      case 'provider_residence': return 'Provider Hunian';
      case 'provider_event':     return 'Provider Acara';
      default:                   return 'Mahasiswa';
    }
  }

  // Inisial untuk avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Untuk update lokal tanpa hit API ulang
  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? profilePicture,
  }) {
    return UserModel(
      id             : id,
      name           : name ?? this.name,
      email          : email,
      phone          : phone ?? this.phone,
      address        : address ?? this.address,
      profilePicture : profilePicture ?? this.profilePicture,
      isActive       : isActive,
      roles          : roles,
    );
  }

  Map<String, dynamic> toJson() => {
    'id'             : id,
    'name'           : name,
    'email'          : email,
    'phone'          : phone,
    'address'        : address,
    'profile_picture': profilePicture,
    'is_active'      : isActive,
    'roles'          : roles,
  };
}