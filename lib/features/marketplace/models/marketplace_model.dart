class MarketplaceProductModel {
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
  final MarketplaceSeller seller;
  final MarketplaceCategory? category;
  final DateTime createdAt;

  MarketplaceProductModel({
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
    required this.seller,
    this.category,
    required this.createdAt,
  });

  String get firstImage => images.isNotEmpty ? images.first : '';
  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Baru';
      case 'like_new':
        return 'Seperti Baru';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'needs_repair':
        return 'Perlu Perbaikan';
      default:
        return condition;
    }
  }

  factory MarketplaceProductModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stockQuantity: json['stock_quantity'] ?? 0,
      condition: json['condition'] ?? 'used',
      conditionNotes: json['condition_notes'],
      images: List<String>.from(json['images'] ?? []),
      isAvailable: json['is_available'] ?? false,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      ratingsCount: json['ratings_count'] ?? 0,
      seller: MarketplaceSeller.fromJson(json['seller'] ?? {}),
      category: json['category'] != null
          ? MarketplaceCategory.fromJson(json['category'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class MarketplaceSeller {
  final int id;
  final String name;
  final String? profilePicture;
  final String? phone;

  MarketplaceSeller({
    required this.id,
    required this.name,
    this.profilePicture,
    this.phone,
  });

  factory MarketplaceSeller.fromJson(Map<String, dynamic> json) =>
      MarketplaceSeller(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        profilePicture: json['profile_picture'],
        phone: json['phone'],
      );
}

class MarketplaceCategory {
  final int id;
  final String name;

  MarketplaceCategory({required this.id, required this.name});

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) =>
      MarketplaceCategory(id: json['id'] ?? 0, name: json['name'] ?? '');
}

// ────────────────────────────────────────────────────────────────────────────

class MarketplaceTransactionModel {
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
  final String? paymentProofUrl;
  final MarketplaceProductModel? product;
  final MarketplaceSeller? seller;
  final DateTime createdAt;

  MarketplaceTransactionModel({
    required this.id,
    required this.status,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.pickupMethod,
    this.pickupAddress,
    this.pickupNotes,
    required this.paymentMethod,
    this.paymentProofUrl,
    this.product,
    this.seller,
    required this.createdAt,
  });

  String get statusLabel {
    const labels = {
      'pending': 'Menunggu',
      'payment_uploaded': 'Bukti Dikirim',
      'confirmed': 'Dikonfirmasi',
      'shipped': 'Dikirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    return labels[status] ?? status;
  }

  String get pickupMethodLabel {
    const labels = {
      'pickup': 'Ambil Sendiri',
      'delivery': 'Diantar',
      'meetup': 'COD / Ketemu',
    };
    return labels[pickupMethod] ?? pickupMethod;
  }

  factory MarketplaceTransactionModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceTransactionModel(
      id: json['id'],
      status: json['status'] ?? 'pending',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      buyerName: json['buyer_name'] ?? '',
      buyerPhone: json['buyer_phone'] ?? '',
      buyerAddress: json['buyer_address'] ?? '',
      pickupMethod: json['pickup_method'] ?? 'meetup',
      pickupAddress: json['pickup_address'],
      pickupNotes: json['pickup_notes'],
      paymentMethod: json['payment_method'] ?? '',
      paymentProofUrl: json['payment_proof_url'],
      product: json['product'] != null
          ? MarketplaceProductModel.fromJson(json['product'])
          : null,
      seller: json['seller'] != null
          ? MarketplaceSeller.fromJson(json['seller'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
