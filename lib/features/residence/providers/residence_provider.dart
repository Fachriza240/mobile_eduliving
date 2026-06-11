import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/services/api_service.dart';

class ResidenceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ResidenceModel> _residences = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';
  int _currentPage = 1;
  bool _hasMore = true;

  ResidenceModel? _selectedResidence;
  bool _isLoadingDetail = false;
  String? _detailError;

  // ── Getters ──────────────────────────────────────────
  List<ResidenceModel> get residences => _residences;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  ResidenceModel? get selectedResidence => _selectedResidence;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // ── Load List ────────────────────────────────────────
  Future<void> loadResidences({bool refresh = false}) async {
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
      final params = <String, dynamic>{
        'page': _currentPage,
      };
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }
      if (_selectedCategory.isNotEmpty) {
        params['residence_type'] = _selectedCategory;
      }

      final res = await _api.get(
        ApiConstants.residences,
        queryParameters: params,
      );

      List<dynamic> rawList = [];

      if (res['data'] is List) {
        rawList = res['data'] as List;
        _hasMore = false;
      } else if (res['data'] is Map) {
        final map = res['data'] as Map<String, dynamic>;
        if (map['data'] is List) {
          rawList = map['data'] as List;
          final cur = map['current_page'] ?? 1;
          final last = map['last_page'] ?? 1;
          _hasMore = cur < last;
        }
      }

      final newItems = rawList
          .map((e) => ResidenceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_currentPage == 1) {
        _residences = newItems;
      } else {
        _residences.addAll(newItems);
      }

      _currentPage++;
      _isLoading = false;
      _isLoadingMore = false;
    } catch (e) {
      _error = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      _isLoadingMore = false;
    }

    notifyListeners();
  }

  // ── Search ───────────────────────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    loadResidences(refresh: true);
  }

  // ── Filter Kategori ──────────────────────────────────
  void setCategory(String category) {
    _selectedCategory = category;
    loadResidences(refresh: true);
  }

  void clearFilter() {
    _searchQuery = '';
    _selectedCategory = '';
    loadResidences(refresh: true);
  }

  // ── Load Detail ──────────────────────────────────────
  Future<void> loadResidenceDetail(int id) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedResidence = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.residenceDetail(id));
      final data = res['data'] ?? res;
      _selectedResidence =
          ResidenceModel.fromJson(data as Map<String, dynamic>);
      _isLoadingDetail = false;
    } catch (e) {
      _detailError = e.toString().replaceAll('ApiException: ', '');
      _isLoadingDetail = false;
    }

    notifyListeners();
  }

  // ── Toggle Bookmark ──────────────────────────────────
  Future<bool> toggleBookmark(int id) async {
    try {
      await _api.post(
        ApiConstants.userBookmarksToggle,
        data: {
          'bookmarkable_id': id,
          'bookmarkable_type': 'App\\Models\\Residence',
        },
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearDetail() {
    _selectedResidence = null;
    _detailError = null;
  }
}
