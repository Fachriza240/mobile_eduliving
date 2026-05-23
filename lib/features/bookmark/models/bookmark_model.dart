class BookmarkModel {
  final int id;
  final String bookmarkableType; // Residence | Activity | MarketplaceProduct
  final BookmarkableItem bookmarkable;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.bookmarkableType,
    required this.bookmarkable,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    // Backend return 'type' bukan 'bookmarkable_type'
    // dan 'item' bukan 'bookmarkable'
    final rawType = json['type']?.toString() ?? '';

    return BookmarkModel(
      id: json['id'],
      bookmarkableType: _toFlutterType(rawType),
      bookmarkable: BookmarkableItem.fromJson(
        json['item'] ?? {},
      ),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Backend kirim 'Residence'|'Activity'|'MarketplaceProduct'
  // sudah cocok, tapi jaga-jaga jika ada variasi
  static String _toFlutterType(String raw) {
    switch (raw.toLowerCase()) {
      case 'residence':
        return 'Residence';
      case 'activity':
        return 'Activity';
      case 'marketplaceproduct':
        return 'MarketplaceProduct';
      default:
        return raw; // pakai apa adanya
    }
  }
}

class BookmarkableItem {
  final int id;
  final String name;
  final String? address;
  final double price;
  final List<String> images;
  final double? averageRating;

  BookmarkableItem({
    required this.id,
    required this.name,
    this.address,
    required this.price,
    required this.images,
    this.averageRating,
  });

  String get displayAddress => address ?? '';
  String get firstImage => images.isNotEmpty ? images.first : '';

  factory BookmarkableItem.fromJson(Map<String, dynamic> json) {
    return BookmarkableItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      averageRating: json['average_rating'] != null
          ? (json['average_rating']).toDouble()
          : null,
    );
  }
}
