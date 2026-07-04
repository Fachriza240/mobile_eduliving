import 'marketplace_model.dart';

class CartItemModel {
  final MarketplaceProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      // Kita hanya perlu menyimpan ID produk dan quantity di lokal,
      // tapi karena SharedPreferences butuh string, kita simpan full json product
      // supaya mudah me-load ulang jika tidak sedang konek API. 
      // Atau lebih baik simpan full product dalam JSON:
      'product': _productToJson(product),
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: MarketplaceProductModel.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
    );
  }

  // Helper untuk mengekstrak data dari model produk agar bisa di-encode ke SharedPreferences
  Map<String, dynamic> _productToJson(MarketplaceProductModel p) {
    return {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'price': p.price,
      'stock_quantity': p.stockQuantity,
      'condition': p.condition,
      'condition_notes': p.conditionNotes,
      'images': p.images,
      'is_available': p.isAvailable,
      'average_rating': p.averageRating,
      'ratings_count': p.ratingsCount,
      'created_at': p.createdAt.toIso8601String(),
      'seller': {
        'id': p.seller.id,
        'name': p.seller.name,
        'profile_picture': p.seller.profilePicture,
        'phone': p.seller.phone,
      },
      'category': p.category != null ? {
        'id': p.category!.id,
        'name': p.category!.name,
      } : null,
    };
  }
}
