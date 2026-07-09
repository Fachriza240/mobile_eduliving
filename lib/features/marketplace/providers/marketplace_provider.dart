import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/marketplace_model.dart';
import '../../../core/services/api_service.dart';

class MarketplaceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<MarketplaceProductModel> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  // Filter state
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedCondition; // new | used | null
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;

  List<MarketplaceProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _lastPage;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCondition => _selectedCondition;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get sortBy => _sortBy;

  // Sentinel untuk membedakan 'tidak dikirim' vs 'set ke null'
  static const _sentinel = Object();

  void setFilter({
    String? search,
    Object? categoryId = _sentinel,
    Object? condition = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? sortBy = _sentinel,
  }) {
    if (search != null) _searchQuery = search;
    if (categoryId != _sentinel) _selectedCategoryId = categoryId as int?;
    if (condition != _sentinel) _selectedCondition = condition as String?;
    if (minPrice != _sentinel) _minPrice = minPrice as double?;
    if (maxPrice != _sentinel) _maxPrice = maxPrice as double?;
    if (sortBy != _sentinel) _sortBy = sortBy as String?;
    fetchProducts(reset: true);
  }

  void clearFilter() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedCondition = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = null;
    fetchProducts(reset: true);
  }

  Future<void> fetchProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _products = [];
    }

    if (_currentPage == 1) {
      _isLoading = true;
      _error = null;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'per_page': 12,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedCondition != null) 'condition': _selectedCondition,
        if (_minPrice != null) 'min_price': _minPrice,
        if (_maxPrice != null) 'max_price': _maxPrice,
        if (_sortBy != null) 'sort': _sortBy,
      };

      final response =
          await _api.dio.get('/marketplace', queryParameters: params);
      final data = response.data;
      final List items = data['data'] ?? [];
      _products.addAll(
        items.map((e) => MarketplaceProductModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            )),
      );
      // last_page ada di dalam 'meta' pada Laravel Resource collection
      _lastPage = data['meta']?['last_page'] ?? data['last_page'] ?? 1;
      _currentPage++;
    } catch (e) {
      _error = 'Gagal memuat produk. Tarik untuk coba lagi.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchDetailData(int id) async {
    try {
      final response = await _api.dio.get('/marketplace/$id');
      return {
        'product': MarketplaceProductModel.fromJson(response.data['data']),
        'related_products': (response.data['related_products'] as List?)
            ?.map((e) => MarketplaceProductModel.fromJson(e))
            .toList() ?? [],
      };
    } catch (_) {
      return null;
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Transaction Provider (sisi buyer)
// ────────────────────────────────────────────────────────────────────────────

class MarketplaceTransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<MarketplaceTransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<MarketplaceTransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTransactions({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        if (status != null) 'status': status,
      };
      final response =
          await _api.dio.get('/user/transactions', queryParameters: params);
      final List data = response.data['data'] ?? [];
      _transactions =
          data.map((e) => MarketplaceTransactionModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Gagal memuat transaksi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MarketplaceTransactionModel?> fetchDetail(int id) async {
    try {
      final response = await _api.dio.get('/user/transactions/$id');
      return MarketplaceTransactionModel.fromJson(response.data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> buyProduct(
      int productId, Map<String, dynamic> payload) async {
    final response = await _api.post('/user/transactions/$productId', data: payload);
    return response;
  }

  Future<void> cancelTransaction(int id, String reason) async {
    final formData = FormData.fromMap({
      '_method': 'PATCH',
      'cancellation_reason': reason,
    });
    await _api.post(
      '/user/transactions/$id/cancel', 
      formData: formData,
    );
    await fetchTransactions();
  }

  Future<void> uploadPaymentProof(int id, String filePath, String paymentMethod) async {
    final formData = FormData.fromMap({
      'payment_method': paymentMethod,
      'payment_proof': await MultipartFile.fromFile(
        filePath,
        filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    // Add _method spoofing for PUT if the backend expects it, though post is used.
    // wait, we used _api.post with formData before in BookingProvider.
    await _api.post(
      '/user/transactions/$id/payment-proof',
      formData: formData,
    );
    await fetchTransactions();
  }
}
