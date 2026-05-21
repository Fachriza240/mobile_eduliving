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

  List<MarketplaceProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _lastPage;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCondition => _selectedCondition;

  void setFilter({
    String? search,
    int? categoryId,
    String? condition,
  }) {
    _searchQuery = search ?? _searchQuery;
    _selectedCategoryId = categoryId;
    _selectedCondition = condition;
    fetchProducts(reset: true);
  }

  void clearFilter() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedCondition = null;
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
      };

      final response =
          await _api.dio.get('/marketplace', queryParameters: params);
      final data = response.data;
      final List items = data['data'] ?? [];

      _products.addAll(items.map((e) => MarketplaceProductModel.fromJson(e)));
      _lastPage = data['last_page'] ?? 1;
      _currentPage++;
    } catch (e) {
      _error = 'Gagal memuat produk. Tarik untuk coba lagi.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<MarketplaceProductModel?> fetchDetail(int id) async {
    try {
      final response = await _api.dio.get('/marketplace/$id');
      return MarketplaceProductModel.fromJson(response.data['data']);
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
    final response =
        await _api.dio.post('/user/transactions/$productId', data: payload);
    return response.data;
  }

  Future<void> cancelTransaction(int id) async {
    await _api.dio.patch('/user/transactions/$id/cancel');
    await fetchTransactions();
  }

  Future<void> uploadPaymentProof(int id, String filePath) async {
    final formData = FormData.fromMap({
      'payment_proof': await MultipartFile.fromFile(
        filePath,
        filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    await _api.dio.post(
      '/user/transactions/$id/payment-proof',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    await fetchTransactions();
  }
}
