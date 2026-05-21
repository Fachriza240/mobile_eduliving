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
    return BookmarkModel(
      id: json['id'],
      bookmarkableType: json['bookmarkable_type'] ?? '',
      bookmarkable: BookmarkableItem.fromJson(
        json['bookmarkable'] ?? {},
        json['bookmarkable_type'] ?? '',
      ),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class BookmarkableItem {
  final int id;
  final String name;
  final String? address;    // hunian
  final String? location;   // acara
  final double price;
  final List<String> images;
  final double? averageRating;
  final String type; // Residence | Activity | MarketplaceProduct

  BookmarkableItem({
    required this.id,
    required this.name,
    this.address,
    this.location,
    required this.price,
    required this.images,
    this.averageRating,
    required this.type,
  });

  String get displayAddress => address ?? location ?? '';
  String get firstImage => images.isNotEmpty ? images.first : '';

  factory BookmarkableItem.fromJson(Map<String, dynamic> json, String type) {
    return BookmarkableItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      location: json['location'],
      price: (json['price'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      averageRating: json['average_rating'] != null
          ? (json['average_rating']).toDouble()
          : null,
      type: type,
    );
  }
}
