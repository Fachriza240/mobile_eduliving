import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/provider_models.dart';

class ProviderActivityProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ProviderActivityModel> _activities = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ProviderActivityModel> get activities => _activities;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadActivities({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _activities = [];
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
        ApiConstants.providerActivities,
        queryParameters: {'page': _currentPage},
      );
      final data = res['data'] as List? ?? [];
      final meta = res['meta'] as Map<String, dynamic>?;

      final items = data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProviderActivityModel.fromJson(e))
          .toList();

      if (refresh) {
        _activities = items;
      } else {
        _activities.addAll(items);
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
        queryParameters: {'type': 'activity'},
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
      print('[ProviderActivity] loadCategories error: $e');
    }
  }

  Future<bool> createActivity(FormData formData) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.post(ApiConstants.providerActivities, formData: formData);
      _successMessage = 'Acara berhasil ditambahkan!';
      await loadActivities(refresh: true);
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

  Future<bool> updateActivity(int id, FormData formData) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.put(ApiConstants.providerActivityUpdate(id), formData: formData);
      _successMessage = 'Acara berhasil diperbarui!';
      await loadActivities(refresh: true);
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

  Future<bool> deleteActivity(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(ApiConstants.providerActivityDelete(id));
      _activities.removeWhere((a) => a.id == id);
      _successMessage = 'Acara berhasil dihapus.';
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

  Future<bool> toggleStatus(int id) async {
    try {
      await _api.patch(ApiConstants.providerActivityToggle(id));
      final idx = _activities.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final old = _activities[idx];
        _activities[idx] = ProviderActivityModel(
          id                   : old.id,
          name                 : old.name,
          description          : old.description,
          location             : old.location,
          price                : old.price,
          capacity             : old.capacity,
          availableSlots       : old.availableSlots,
          isActive             : !old.isActive,
          images               : old.images,
          benefits             : old.benefits,
          speakers             : old.speakers,
          categoryName         : old.categoryName,
          categoryId           : old.categoryId,
          eventDate            : old.eventDate,
          registrationDeadline : old.registrationDeadline,
          bookingsCount        : old.bookingsCount,
          ratingAvg            : old.ratingAvg,
          ratingsCount         : old.ratingsCount,
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
