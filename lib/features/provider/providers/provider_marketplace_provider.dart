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

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      final res = await _api.get(
        ApiConstants.categories,
        queryParameters: {'type': 'marketplace'},
      );
      final dataMap = res['data'] as Map<String, dynamic>?;
      final list = dataMap?['categories'] as List? ?? [];
      _categories = list
          .whereType<Map<String, dynamic>>()
          .map((e) => CategoryModel.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[ProviderMarketplace] loadCategories error: $e');
    }
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
  Future<bool> toggleAvailability(int id) async {
    try {
      await _api.patch(ApiConstants.providerMarketplaceProductToggle(id));
      final idx = _products.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final old = _products[idx];
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
      }
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

  Future<bool> confirmOrder(int id) => _updateOrderStatus(
    id,
    ApiConstants.providerMarketplaceOrderConfirm(id),
    'Pesanan dikonfirmasi.',
  );

  Future<bool> shipOrder(int id) => _updateOrderStatus(
    id,
    ApiConstants.providerMarketplaceOrderShip(id),
    'Pesanan ditandai dikirim.',
  );

  Future<bool> completeOrder(int id) => _updateOrderStatus(
    id,
    ApiConstants.providerMarketplaceOrderComplete(id),
    'Pesanan selesai.',
  );

  Future<bool> rejectOrder(int id, {String? reason}) async {
    _isActing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.patch(
        ApiConstants.providerMarketplaceOrderReject(id),
        data: reason != null ? {'reason': reason} : null,
      );
      _successMessage = 'Pesanan ditolak.';
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

  Future<bool> _updateOrderStatus(int id, String endpoint, String successMsg) async {
    _isActing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.patch(endpoint);
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
