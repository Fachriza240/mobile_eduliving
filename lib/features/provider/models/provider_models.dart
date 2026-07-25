import 'package:flutter/material.dart';

// ============================================================
// PROVIDER DASHBOARD MODEL
// ============================================================
class ProviderDashboardModel {
  final String role;
  final String providerStatus;
  final int totalItems;
  final int totalBookings;
  final int pendingBookings;
  final int approvedBookings;
  final int monthlyBookings;
  final double bookingRevenue;
  final double marketplaceRevenue;
  final double totalRevenue;
  final double approvalRate;

  ProviderDashboardModel({
    required this.role,
    required this.providerStatus,
    required this.totalItems,
    required this.totalBookings,
    required this.pendingBookings,
    required this.approvedBookings,
    required this.monthlyBookings,
    required this.bookingRevenue,
    required this.marketplaceRevenue,
    required this.totalRevenue,
    required this.approvalRate,
  });

  factory ProviderDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProviderDashboardModel(
      role               : json['role'] ?? '',
      providerStatus     : json['provider_status'] ?? 'pending',
      totalItems         : json['total_items'] ?? 0,
      totalBookings      : json['total_bookings'] ?? 0,
      pendingBookings    : json['pending_bookings'] ?? 0,
      approvedBookings   : json['approved_bookings'] ?? 0,
      monthlyBookings    : json['monthly_bookings'] ?? 0,
      bookingRevenue     : _toDouble(json['booking_revenue']),
      marketplaceRevenue : _toDouble(json['marketplace_revenue']),
      totalRevenue       : _toDouble(json['total_revenue']),
      approvalRate       : _toDouble(json['approval_rate']),
    );
  }

  bool get isResidenceProvider => role == 'provider_residence';
  bool get isApproved          => providerStatus == 'approved';

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ============================================================
// BOOKING DOCUMENT MODEL (KTP / Kartu Keluarga)
// ============================================================
class BookingDocumentModel {
  final String docType; // 'ktp', 'kk', atau 'lainnya'
  final String label;   // 'KTP', 'Kartu Keluarga', dst
  final String url;
  final bool isImage;

  BookingDocumentModel({
    required this.docType,
    required this.label,
    required this.url,
    required this.isImage,
  });

  factory BookingDocumentModel.fromJson(Map<String, dynamic> json) {
    return BookingDocumentModel(
      docType : json['doc_type'] ?? 'lainnya',
      label   : json['label'] ?? 'Dokumen',
      url     : json['url'] ?? '',
      isImage : json['is_image'] ?? true,
    );
  }
}

// ============================================================
// PROVIDER BOOKING MODEL
// ============================================================
class ProviderBookingModel {
  final int id;
  final String bookingCode;
  final String status;
  final String bookableType; // 'residence' or 'activity'
  final String bookableName;
  final int bookableId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalPrice;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final List<BookingDocumentModel> documents;

  ProviderBookingModel({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.bookableType,
    required this.bookableName,
    required this.bookableId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.startDate,
    this.endDate,
    required this.totalPrice,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    required this.documents,
  });

  factory ProviderBookingModel.fromJson(Map<String, dynamic> json) {
    final bookable = json['bookable'] as Map<String, dynamic>? ?? {};
    final user     = json['user']    as Map<String, dynamic>? ?? {};

    final bookableTypeRaw = (json['bookable_type'] as String? ?? '').toLowerCase();
    final bookableType = bookableTypeRaw.contains('activity') ? 'activity' : 'residence';

    final docList = <BookingDocumentModel>[];
    if (json['documents'] != null && json['documents'] is List) {
      for (final doc in (json['documents'] as List)) {
        if (doc is Map<String, dynamic>) {
          docList.add(BookingDocumentModel.fromJson(doc));
        } else if (doc is Map) {
          docList.add(BookingDocumentModel.fromJson(Map<String, dynamic>.from(doc)));
        }
      }
    }

    return ProviderBookingModel(
      id              : json['id'] ?? 0,
      bookingCode     : json['booking_code'] ?? '-',
      status          : json['status'] ?? 'pending',
      bookableType    : bookableType,
      bookableName    : bookable['name'] ?? '-',
      bookableId      : bookable['id'] ?? 0,
      userName        : user['name'] ?? '-',
      userEmail       : user['email'] ?? '-',
      userPhone       : user['phone'],
      startDate       : _parseDate(json['start_date']),
      endDate         : _parseDate(json['end_date']),
      totalPrice      : _toDouble(json['total_price']),
      notes           : json['notes'],
      rejectionReason : json['rejection_reason'],
      createdAt       : _parseDate(json['created_at']) ?? DateTime.now(),
      documents       : docList,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  bool get isPending   => status == 'pending';
  bool get isApproved  => status == 'approved';
  bool get isRejected  => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

// ============================================================
// PROVIDER RESIDENCE MODEL
// ============================================================
class ProviderResidenceModel {
  final int id;
  final String name;
  final String description;
  final String address;
  final double price;
  final int capacity;
  final int availableSlots;
  final bool isActive;
  final List<String> images;
  final List<String> facilities;
  final String residenceType;
  final String rentalPeriod;
  final String? furnishStatus;
  final String? categoryName;
  final int? categoryId;
  final String? kosType;
  final double? roomSize;
  final int? bedroomCount;
  final int? bathroomCount;
  final double? buildingSize;
  final double? landSize;
  final String? unitType;
  final int? floorNumber;
  final String? towerName;
  final String? discountType;
  final double? discountValue;
  final double? discountedPrice;
  final double? latitude;
  final double? longitude;
  final int bookingsCount;
  final double ratingAvg;
  final int ratingsCount;

  ProviderResidenceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.price,
    required this.capacity,
    required this.availableSlots,
    required this.isActive,
    required this.images,
    required this.facilities,
    required this.residenceType,
    required this.rentalPeriod,
    this.furnishStatus,
    this.categoryName,
    this.categoryId,
    this.kosType,
    this.roomSize,
    this.bedroomCount,
    this.bathroomCount,
    this.buildingSize,
    this.landSize,
    this.unitType,
    this.floorNumber,
    this.towerName,
    this.discountType,
    this.discountValue,
    this.discountedPrice,
    this.latitude,
    this.longitude,
    required this.bookingsCount,
    required this.ratingAvg,
    required this.ratingsCount,
  });

  factory ProviderResidenceModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return ProviderResidenceModel(
      id             : json['id'] ?? 0,
      name           : json['name'] ?? '',
      description    : json['description'] ?? '',
      address        : json['address'] ?? '',
      price          : _toDouble(json['price']),
      capacity       : json['capacity'] ?? 0,
      availableSlots : json['available_slots'] ?? 0,
      isActive       : json['is_active'] == true,
      images         : _toList(json['images']),
      facilities     : _toList(json['facilities']),
      residenceType  : json['residence_type'] ?? '',
      rentalPeriod   : json['rental_period'] ?? 'monthly',
      furnishStatus  : json['furnish_status'],
      categoryName   : cat?['name'],
      categoryId     : json['category_id'],
      kosType        : json['kos_type'],
      roomSize       : _toDouble(json['room_size']),
      bedroomCount   : json['bedroom_count'],
      bathroomCount  : json['bathroom_count'],
      buildingSize   : _toDouble(json['building_size']),
      landSize       : _toDouble(json['land_size']),
      unitType       : json['unit_type'],
      floorNumber    : json['floor_number'],
      towerName      : json['tower_name'],
      discountType   : json['discount_type'],
      discountValue  : _toDouble(json['discount_value']),
      discountedPrice: _toDouble(json['discounted_price'] ?? json['price']),
      latitude       : _toDouble(json['latitude']),
      longitude      : _toDouble(json['longitude']),
      bookingsCount  : json['bookings_count'] ?? 0,
      ratingAvg      : _toDouble(json['ratings_avg_rating']),
      ratingsCount   : json['ratings_count'] ?? 0,
    );
  }

  String get mainImage => images.isNotEmpty ? images.first : '';
  bool get hasDiscount => discountType != null && (discountValue ?? 0) > 0;

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

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ============================================================
// PROVIDER ACTIVITY MODEL
// ============================================================
class ProviderActivityModel {
  final int id;
  final String name;
  final String description;
  final String location;
  final double price;
  final int capacity;
  final int availableSlots;
  final bool isActive;
  final List<String> images;
  final List<String> benefits;
  final List<Map<String, dynamic>> speakers;
  final String? categoryName;
  final int? categoryId;
  final DateTime? eventDate;
  final DateTime? registrationDeadline;
  final String? discountType;
  final double? discountValue;
  final double? discountedPrice;
  final double? latitude;
  final double? longitude;
  final int bookingsCount;
  final double ratingAvg;
  final int ratingsCount;

  ProviderActivityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.price,
    required this.capacity,
    required this.availableSlots,
    required this.isActive,
    required this.images,
    required this.benefits,
    required this.speakers,
    this.categoryName,
    this.categoryId,
    this.eventDate,
    this.registrationDeadline,
    this.discountType,
    this.discountValue,
    this.discountedPrice,
    this.latitude,
    this.longitude,
    required this.bookingsCount,
    required this.ratingAvg,
    required this.ratingsCount,
  });

  factory ProviderActivityModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return ProviderActivityModel(
      id                   : json['id'] ?? 0,
      name                 : json['name'] ?? '',
      description          : json['description'] ?? '',
      location             : json['location'] ?? '',
      price                : _toDouble(json['price']),
      capacity             : json['capacity'] ?? 0,
      availableSlots       : json['available_slots'] ?? 0,
      isActive             : json['is_active'] == true,
      images               : _toList(json['images']),
      benefits             : _toList(json['benefits']),
      speakers             : _toMapList(json['speakers']),
      categoryName         : cat?['name'],
      categoryId           : json['category_id'],
      eventDate            : _parseDate(json['event_date']),
      registrationDeadline : _parseDate(json['registration_deadline']),
      discountType         : json['discount_type'],
      discountValue        : _toDouble(json['discount_value']),
      discountedPrice      : _toDouble(json['discounted_price'] ?? json['price']),
      latitude             : _toDouble(json['latitude']),
      longitude            : _toDouble(json['longitude']),
      bookingsCount        : json['bookings_count'] ?? 0,
      ratingAvg            : _toDouble(json['ratings_avg_rating']),
      ratingsCount         : json['ratings_count'] ?? 0,
    );
  }

  String get mainImage  => images.isNotEmpty ? images.first : '';
  bool get isFree       => price == 0;
  bool get hasDiscount  => discountType != null && (discountValue ?? 0) > 0;
  bool get isEventPassed => eventDate != null && eventDate!.isBefore(DateTime.now());
  bool get isDeadlinePassed => registrationDeadline != null && registrationDeadline!.isBefore(DateTime.now());

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  static List<Map<String, dynamic>> _toMapList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ============================================================
// CATEGORY MODEL
// ============================================================
class CategoryModel {
  final int id;
  final String name;
  final String type;

  CategoryModel({required this.id, required this.name, required this.type});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id   : json['id'] ?? 0,
      name : json['name'] ?? '',
      type : json['type'] ?? '',
    );
  }
}

// ============================================================
// PROVIDER MARKETPLACE PRODUCT MODEL
// ============================================================
class ProviderMarketplaceProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String condition; // new | used
  final String? conditionNotes;
  final List<String> images;
  final bool isAvailable;
  final double averageRating;
  final int ratingsCount;
  final String? categoryName;
  final int? categoryId;
  final int ordersCount;
  final DateTime createdAt;
  final List<String> pickupMethods; // cod | delivery | pickup
  final String? pickupAddress;


  ProviderMarketplaceProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.condition,
    this.conditionNotes,
    required this.images,
    required this.isAvailable,
    required this.averageRating,
    required this.ratingsCount,
    this.categoryName,
    this.categoryId,
    required this.ordersCount,
    required this.createdAt,
    this.pickupMethods = const [],
    this.pickupAddress,  
  });

  String get firstImage => images.isNotEmpty ? images.first : '';
  String get conditionLabel => condition == 'new' ? 'Baru' : 'Bekas';

  factory ProviderMarketplaceProductModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return ProviderMarketplaceProductModel(
      id             : json['id'] ?? 0,
      name           : json['name'] ?? '',
      description    : json['description'] ?? '',
      price          : _toDouble(json['price']),
      stockQuantity  : json['stock_quantity'] ?? 0,
      condition      : json['condition'] ?? 'used',
      conditionNotes : json['condition_notes'],
      images         : _toList(json['images']),
      isAvailable    : json['is_available'] == true,
      averageRating  : _toDouble(json['average_rating']),
      ratingsCount   : json['ratings_count'] ?? 0,
      categoryName   : cat?['name'],
      categoryId     : json['category_id'],
      ordersCount    : json['orders_count'] ?? json['transactions_count'] ?? 0,
      createdAt      : _parseDate(json['created_at']) ?? DateTime.now(),
      pickupMethods  : _toList(json['pickup_methods']),
    );
  }

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }
}

// ============================================================
// PROVIDER MARKETPLACE ORDER MODEL
// ============================================================
class ProviderMarketplaceOrderModel {
  final int id;
  final String status;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String pickupMethod; // pickup | delivery | meetup
  final String? pickupAddress;
  final String? pickupNotes;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentProofUrl;
  final ProviderMarketplaceProductModel? product;
  final DateTime createdAt;

  ProviderMarketplaceOrderModel({
    required this.id,
    required this.status,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.pickupMethod,
    required this.pickupAddress,
    this.pickupNotes,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentProofUrl,
    this.product,
    required this.createdAt,
  });

  String get statusLabel {
    const labels = {
      'pending'          : 'Menunggu',
      'payment_uploaded' : 'Bukti Dikirim',
      'confirmed'        : 'Dikonfirmasi',
      'in_progress'      : 'Diproses',
      'shipped'          : 'Dikirim',
      'completed'        : 'Selesai',
      'cancelled'        : 'Dibatalkan',
    };
    if (status == 'pending' && (paymentStatus == 'paid' || paymentProofUrl != null)) {
      return 'Bukti Dikirim';
    }
    return labels[status] ?? status;
  }

  Color get statusColor {
    if (status == 'pending' && (paymentStatus == 'paid' || paymentProofUrl != null)) {
      return const Color(0xFF2563EB);
    }
    switch (status) {
      case 'pending':          return const Color(0xFFD97706);
      case 'payment_uploaded': return const Color(0xFF2563EB);
      case 'confirmed':        return const Color(0xFF16A34A);
      case 'shipped':          return const Color(0xFF7C3AED);
      case 'completed':        return const Color(0xFF16A34A);
      case 'cancelled':        return const Color(0xFFDC2626);
      default:                 return const Color(0xFF6B7280);
    }
  }

  String get pickupMethodLabel {
    const labels = {
      'pickup'   : 'Ambil Sendiri',
      'delivery' : 'Diantar',
      'meetup'   : 'COD / Ketemu',
    };
    return labels[pickupMethod] ?? pickupMethod;
  }

  String get paymentMethodLabel {
    if (pickupMethod == 'pickup' || pickupMethod == 'meetup' || pickupMethod == 'cod') {
      return 'Bayar di Tempat (COD)';
    }
    if (paymentMethod == 'pending' || paymentMethod.isEmpty) {
      return 'Transfer Manual (Menunggu)';
    }
    return paymentMethod.toUpperCase();
  }

  factory ProviderMarketplaceOrderModel.fromJson(Map<String, dynamic> json) {
    return ProviderMarketplaceOrderModel(
      id             : json['id'] ?? 0,
      status         : json['status'] ?? 'pending',
      quantity       : json['quantity'] ?? 1,
      unitPrice      : _toDouble(json['unit_price']),
      totalAmount    : _toDouble(json['total_amount']),
      buyerName      : json['buyer_name'] ?? '',
      buyerPhone     : json['buyer_phone'] ?? '',
      buyerAddress   : json['buyer_address'] ?? '',
      pickupMethod   : json['pickup_method'] ?? 'meetup',
      pickupAddress  : json['pickup_address'],
      pickupNotes    : json['pickup_notes'],
      paymentMethod  : json['payment_method'] ?? '',
      paymentStatus  : json['payment_status'] ?? 'unpaid',
      paymentProofUrl: json['payment_proof_url'] ?? json['payment_proof'],
      product        : json['product'] != null
          ? ProviderMarketplaceProductModel.fromJson(json['product'])
          : null,
      createdAt      : _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }
}

// ============================================================
// SELLER DASHBOARD MODEL
// ============================================================
class SellerDashboardModel {
  final int totalProducts;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double monthlyRevenue;
  final List<ProviderMarketplaceOrderModel> recentOrders;

  SellerDashboardModel({
    required this.totalProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.recentOrders,
  });

  factory SellerDashboardModel.fromJson(Map<String, dynamic> json) {
    final recentList = json['recent_orders'] as List? ?? [];
    return SellerDashboardModel(
      totalProducts   : json['total_products'] ?? 0,
      totalOrders     : json['total_orders'] ?? 0,
      pendingOrders   : json['pending_orders'] ?? 0,
      completedOrders : json['completed_orders'] ?? 0,
      totalRevenue    : _toDouble(json['total_revenue']),
      monthlyRevenue  : _toDouble(json['monthly_revenue']),
      recentOrders    : recentList
          .whereType<Map<String, dynamic>>()
          .map((e) => ProviderMarketplaceOrderModel.fromJson(e))
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }
}
