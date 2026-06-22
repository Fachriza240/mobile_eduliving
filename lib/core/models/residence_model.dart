class ResidenceModel {
  final int id;
  final int providerId;
  final int? categoryId;
  final String name;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? rentalPeriod;
  final double price;
  final int? capacity;
  final int? availableSlots;
  final List<String> facilities;
  final List<String> images;
  final String? discountType;
  final double? discountValue;
  final bool isActive;
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? category;
  final double? ratingAverage;
  final int? ratingCount;
  final bool? isBookmarked;
  final List<dynamic> ratings;

  ResidenceModel({
    required this.id,
    required this.providerId,
    this.categoryId,
    required this.name,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.rentalPeriod,
    required this.price,
    this.capacity,
    this.availableSlots,
    required this.facilities,
    required this.images,
    this.discountType,
    this.discountValue,
    required this.isActive,
    this.provider,
    this.category,
    this.ratingAverage,
    this.ratingCount,
    this.isBookmarked,
    this.ratings = const [],
  });

  factory ResidenceModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return ResidenceModel(
      id: json['id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      rentalPeriod: json['rental_period'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      capacity: json['capacity'],
      availableSlots: json['available_slots'],
      facilities: parseList(json['facilities']),
      images: parseList(json['images']),
      discountType: json['discount_type'],
      discountValue: json['discount_value'] != null
          ? double.tryParse(json['discount_value'].toString())
          : null,
      isActive: json['is_active'] ?? true,
      provider: json['provider'] as Map<String, dynamic>?,
      category: json['category'] as Map<String, dynamic>?,
      ratingAverage: json['rating_average'] != null
          ? double.tryParse(json['rating_average'].toString())
          : null,
      ratingCount: json['rating_count'],
      isBookmarked: json['is_bookmarked'] as bool?,
      ratings: json['ratings'] as List<dynamic>? ?? [],
    );
  }

  // ── Helpers ──────────────────────────────────────────
  double get discountedPrice {
    if (discountType == null || discountValue == null) return price;
    if (discountType == 'percentage') {
      return (price - (price * discountValue! / 100)).clamp(0, double.infinity);
    }
    return (price - discountValue!).clamp(0, double.infinity);
  }

  bool get hasDiscount =>
      discountType != null && discountValue != null && discountValue! > 0;

  bool get isAvailable => (availableSlots ?? 0) > 0 && isActive;

  String get mainImage => images.isNotEmpty ? images.first : '';

  String get providerName => provider?['name'] ?? 'Provider';

  String get categoryName => category?['name'] ?? '-';

  String get rentalPeriodLabel {
    switch (rentalPeriod) {
      case 'monthly':
        return 'per bulan';
      case 'yearly':
        return 'per tahun';
      case 'daily':
        return 'per hari';
      default:
        return rentalPeriod ?? '';
    }
  }

  String get rentalPeriodShort {
    switch (rentalPeriod) {
      case 'monthly':
        return 'bln';
      case 'yearly':
        return 'thn';
      case 'daily':
        return 'hari';
      default:
        return 'bln';
    }
  }
}
