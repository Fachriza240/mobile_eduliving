class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profilePicture;
  final bool isActive;
  final List<String> roles;
  // ── Seller fields dari backend ────────────────────
  final bool isSeller;
  final String? sellerStatus; // null | 'pending' | 'approved' | 'rejected'
  final bool isSellerModeActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profilePicture,
    required this.isActive,
    required this.roles,
    this.isSeller = false,
    this.sellerStatus,
    bool? isSellerModeActive,
  }): isSellerModeActive = isSellerModeActive ?? isSeller;

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

    final sellerVal = json['is_seller'] == true;

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      isActive: json['is_active'] ?? true,
      roles: roleList,
      isSeller: sellerVal,  
      // Baca is_seller & seller_status dari backend
      sellerStatus: json['seller_status'] as String?,
      isSellerModeActive: false,  
    );
  }

  // ── Cek Role ─────────────────────────────────────────
  bool get isUser => roles.contains('user');
  bool get isProviderResidence => roles.contains('provider_residence');
  bool get isProviderEvent => roles.contains('provider_event');
  // Cek provider_marketplace dari roles ATAU is_seller dari backend
bool get isProviderMarketplace =>
      (roles.contains('provider_marketplace') || isSeller) &&
      isSellerModeActive;
  // ── Seller status helpers ─────────────────────────────
  /// Sudah di-approve dan bisa buka toko
  bool get isApprovedSeller => isSeller || sellerStatus == 'approved';

  /// Sudah submit form, menunggu admin
  bool get isPendingSeller =>
      !isSeller && sellerStatus == 'pending';

  /// Belum pernah daftar sama sekali
  bool get isNotRegisteredSeller =>
      !isSeller && (sellerStatus == null || sellerStatus == 'none' || sellerStatus == 'rejected');

  // Role utama (untuk navigasi & badge)
  String get primaryRole {
    if (isProviderResidence) return 'provider_residence';
    if (isProviderEvent) return 'provider_event';
    if (isApprovedSeller && isSellerModeActive) return 'provider_marketplace';
    return 'user';
  }

  // Label role dalam Bahasa Indonesia
  String get roleLabel {
    switch (primaryRole) {
      case 'provider_residence':
        return 'Provider Hunian';
      case 'provider_event':
        return 'Provider Acara';
      case 'provider_marketplace':
        return 'Provider Marketplace';
      default:
        return 'Mahasiswa';
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
    bool? isSeller,
    String? sellerStatus,
    bool? isSellerModeActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      isActive: isActive,
      roles: roles,
      isSeller: isSeller ?? this.isSeller,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      isSellerModeActive: isSellerModeActive ?? this.isSellerModeActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'profile_picture': profilePicture,
        'is_active': isActive,
        'roles': roles,
        'is_seller': isSeller,
        'seller_status': sellerStatus,
      };
}
