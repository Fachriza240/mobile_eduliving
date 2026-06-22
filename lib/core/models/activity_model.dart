class ActivityModel {
  final int id;
  final int providerId;
  final int? categoryId;
  final String name;
  final String description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? eventDate;
  final DateTime? registrationDeadline;
  final double price;
  final int? capacity;
  final int? availableSlots;
  final List<String> images;
  final List<Map<String, dynamic>> speakers;
  final List<String> benefits;
  final String? discountType;
  final double? discountValue;
  final bool isActive;
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? category;
  final double? ratingAverage;
  final int? ratingCount;
  final bool? isBookmarked;
  final List<dynamic> ratings;

  ActivityModel({
    required this.id,
    required this.providerId,
    this.categoryId,
    required this.name,
    required this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.eventDate,
    this.registrationDeadline,
    required this.price,
    this.capacity,
    this.availableSlots,
    required this.images,
    required this.speakers,
    required this.benefits,
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

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    List<Map<String, dynamic>> parseSpeakers(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) {
          if (e is Map<String, dynamic>) return e;
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    }

    return ActivityModel(
      id: json['id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'].toString())
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.tryParse(json['registration_deadline'].toString())
          : null,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      capacity: json['capacity'],
      availableSlots: json['available_slots'],
      images: parseStringList(json['images']),
      speakers: parseSpeakers(json['speakers']),
      benefits: parseStringList(json['benefits']),
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

  bool get isFree => price == 0;

  bool get isAvailable => (availableSlots ?? 0) > 0 && isActive;

  bool get isEventPassed {
    if (eventDate == null) return false;
    return DateTime.now().isAfter(eventDate!);
  }

  bool get isDeadlinePassed {
    if (registrationDeadline == null) return false;
    return DateTime.now().isAfter(registrationDeadline!);
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  String get providerName => provider?['name'] ?? 'Penyelenggara';

  String get categoryName => category?['name'] ?? '-';
}
