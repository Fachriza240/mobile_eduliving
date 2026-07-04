import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/provider_models.dart';

class ProviderResidenceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ProviderResidenceModel> _residences = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ProviderResidenceModel> get residences => _residences;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadResidences({bool refresh = false, String? filterType}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _residences = [];
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
      if (filterType != null) params['residence_type'] = filterType;
      final res = await _api.get(
        ApiConstants.providerResidences,
        queryParameters: params,
      );
      final data = res['data'] as List? ?? [];
      final meta = res['meta'] as Map<String, dynamic>?;

      final items = data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProviderResidenceModel.fromJson(e))
          .toList();

      if (refresh) {
        _residences = items;
      } else {
        _residences.addAll(items);
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
        queryParameters: {'type': 'residence'},
      );
      // Response: { "data": { "categories": [...] } }
      final dataMap = res['data'] as Map<String, dynamic>?;
      final list = dataMap?['categories'] as List? ?? [];
      _categories = list
          .whereType<Map<String, dynamic>>()
          .map((e) => CategoryModel.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      print('[ProviderResidence] loadCategories error: $e');
    }
  }

  // ── CREATE ────────────────────────────────────────────
  Future<bool> createResidence(FormData formData) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.post(ApiConstants.providerResidences, formData: formData);
      _successMessage = 'Hunian berhasil ditambahkan!';
      await loadResidences(refresh: true);
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
  Future<bool> updateResidence(int id, FormData formData) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.put(ApiConstants.providerResidenceUpdate(id), formData: formData);
      _successMessage = 'Hunian berhasil diperbarui!';
      await loadResidences(refresh: true);
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
  Future<bool> deleteResidence(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(ApiConstants.providerResidenceDelete(id));
      _residences.removeWhere((r) => r.id == id);
      _successMessage = 'Hunian berhasil dihapus.';
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

  // ── TOGGLE STATUS ─────────────────────────────────────
  Future<bool> toggleStatus(int id) async {
    try {
      await _api.patch(ApiConstants.providerResidenceToggle(id));
      final idx = _residences.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final old = _residences[idx];
        _residences[idx] = ProviderResidenceModel(
          id             : old.id,
          name           : old.name,
          description    : old.description,
          address        : old.address,
          price          : old.price,
          capacity       : old.capacity,
          availableSlots : old.availableSlots,
          isActive       : !old.isActive,
          images         : old.images,
          facilities     : old.facilities,
          residenceType  : old.residenceType,
          rentalPeriod   : old.rentalPeriod,
          furnishStatus  : old.furnishStatus,
          categoryName   : old.categoryName,
          categoryId     : old.categoryId,
          bookingsCount  : old.bookingsCount,
          ratingAvg      : old.ratingAvg,
          ratingsCount   : old.ratingsCount,
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
