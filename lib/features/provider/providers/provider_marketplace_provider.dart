import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/provider_models.dart';

// ============================================================
// PROVIDER MARKETPLACE PRODUCT PROVIDER
// ============================================================
class ProviderMarketplaceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ProviderMarketplaceProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ProviderMarketplaceProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products = [];
    }
    if (!_hasMore || _isLoadingMore) return;

    if (_currentPage == 1) {
      _isLoading = true;
      _error = null;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.providerMarketplaceProducts,
        queryParameters: {'page': _currentPage},
      );

      // Backend mengembalikan Laravel paginate collection
      // Format: { data: [...], meta: { last_page: N, ... } }
      final data = res['data'] as List? ?? [];
      final meta = res['meta'] as Map<String, dynamic>?;

      final items = data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProviderMarketplaceProductModel.fromJson(e))
          .toList();

      if (refresh) {
        _products = items;
      } else {
        _products.addAll(items);
      }

      final lastPage = meta?['last_page'] ?? 1;
      _hasMore = _currentPage < lastPage;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  // Kategori hardcode sesuai ProductCategorySeeder — id match urutan insert di DB
  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    _categories = [
      CategoryModel(id: 1,  name: 'Elektronik',            type: 'marketplace'),
      CategoryModel(id: 2,  name: 'Fashion',                type: 'marketplace'),
      CategoryModel(id: 3,  name: 'Rumah Tangga',           type: 'marketplace'),
      CategoryModel(id: 4,  name: 'Olahraga',               type: 'marketplace'),
      CategoryModel(id: 5,  name: 'Buku & Media',          type: 'marketplace'),
      CategoryModel(id: 6,  name: 'Kesehatan & Kecantikan',type: 'marketplace'),
      CategoryModel(id: 7,  name: 'Otomotif',               type: 'marketplace'),
      CategoryModel(id: 8,  name: 'Hobi & Koleksi',        type: 'marketplace'),
      CategoryModel(id: 9,  name: 'Makanan & Minuman',     type: 'marketplace'),
      CategoryModel(id: 10, name: 'Lainnya',                type: 'marketplace'),
    ];
    notifyListeners();
  }

  // ── CREATE ────────────────────────────────────────────
  Future<bool> createProduct(FormData formData) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.post(ApiConstants.providerMarketplaceProducts, formData: formData);
      _successMessage = 'Produk berhasil ditambahkan!';
      await loadProducts(refresh: true);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE ────────────────────────────────────────────
  Future<bool> updateProduct(int id, FormData formData) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.put(ApiConstants.providerMarketplaceProductUpdate(id), formData: formData);
      _successMessage = 'Produk berhasil diperbarui!';
      await loadProducts(refresh: true);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── DELETE ────────────────────────────────────────────
  Future<bool> deleteProduct(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(ApiConstants.providerMarketplaceProductDelete(id));
      _products.removeWhere((p) => p.id == id);
      _successMessage = 'Produk berhasil dihapus.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── TOGGLE AVAILABILITY ───────────────────────────────
  // Backend tidak punya endpoint toggle terpisah.
  // Pakai PUT /user/seller/products/{id} dengan field status.
  Future<bool> toggleAvailability(int id) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) return false;

    final old = _products[idx];
    final newStatus = old.isAvailable ? 'inactive' : 'active';

    try {
      await _api.put(
        ApiConstants.providerMarketplaceProductToggle(id),
        data: {'status': newStatus},
      );

      _products[idx] = ProviderMarketplaceProductModel(
        id            : old.id,
        name          : old.name,
        description   : old.description,
        price         : old.price,
        stockQuantity : old.stockQuantity,
        condition     : old.condition,
        conditionNotes: old.conditionNotes,
        images        : old.images,
        isAvailable   : !old.isAvailable,
        averageRating : old.averageRating,
        ratingsCount  : old.ratingsCount,
        categoryName  : old.categoryName,
        categoryId    : old.categoryId,
        ordersCount   : old.ordersCount,
        createdAt     : old.createdAt,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _successMessage = null;
    _error = null;
  }
}

// ============================================================
// PROVIDER MARKETPLACE ORDER PROVIDER
// ============================================================
class ProviderMarketplaceOrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ProviderMarketplaceOrderModel> _orders = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isActing = false;
  String? _error;
  String? _successMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _filterStatus;

  List<ProviderMarketplaceOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isActing => _isActing;
  String? get error => _error;
  String? get successMessage => _successMessage;
  String? get filterStatus => _filterStatus;

  void setFilter(String? status) {
    _filterStatus = status;
    loadOrders(refresh: true);
  }

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _orders = [];
    }
    if (!_hasMore || _isLoadingMore) return;

    if (_currentPage == 1) {
      _isLoading = true;
      _error = null;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final params = <String, dynamic>{'page': _currentPage};
      if (_filterStatus != null) params['status'] = _filterStatus;

      final res = await _api.get(
        ApiConstants.providerMarketplaceOrders,
        queryParameters: params,
      );
      final data = res['data'] as List? ?? [];
      final meta = res['meta'] as Map<String, dynamic>?;

      final items = data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProviderMarketplaceOrderModel.fromJson(e))
          .toList();

      if (refresh) {
        _orders = items;
      } else {
        _orders.addAll(items);
      }

      final lastPage = meta?['last_page'] ?? 1;
      _hasMore = _currentPage < lastPage;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<ProviderMarketplaceOrderModel?> fetchDetail(int id) async {
    try {
      final res = await _api.get(ApiConstants.providerMarketplaceOrderDetail(id));
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ProviderMarketplaceOrderModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // Backend hanya punya PATCH /user/seller/orders/{id}/status
  // dengan body { status: 'confirmed'|'in_progress'|'completed'|'cancelled' }
  Future<bool> confirmOrder(int id) =>
      _updateStatus(id, 'confirmed', 'Pesanan dikonfirmasi.');

  Future<bool> shipOrder(int id) =>
      _updateStatus(id, 'in_progress', 'Pesanan ditandai dikirim.');

  Future<bool> completeOrder(int id) =>
      _updateStatus(id, 'completed', 'Pesanan selesai.');

  Future<bool> rejectOrder(int id, {String? reason}) =>
      _updateStatus(id, 'cancelled', 'Pesanan ditolak.',
          extra: reason != null ? {'cancellation_reason': reason} : null);

  Future<bool> _updateStatus(
    int id,
    String status,
    String successMsg, {
    Map<String, dynamic>? extra,
  }) async {
    _isActing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{'status': status};
      if (extra != null) body.addAll(extra);

      await _api.patch(
        ApiConstants.providerMarketplaceOrderUpdateStatus(id),
        data: body,
      );
      _successMessage = successMsg;
      await loadOrders(refresh: true);
      _isActing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isActing = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _successMessage = null;
    _error = null;
  }
}
