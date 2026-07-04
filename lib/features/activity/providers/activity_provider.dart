import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/services/api_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';
  String? _sortBy;
  double? _minPrice;
  double? _maxPrice;
  int _currentPage = 1;
  bool _hasMore = true;

  ActivityModel? _selectedActivity;
  bool _isLoadingDetail = false;
  String? _detailError;

  // ── Getters ──────────────────────────────────────────
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  ActivityModel? get selectedActivity => _selectedActivity;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get sortBy => _sortBy;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  // ── Setters ──────────────────────────────────────────
  void setSearch(String q) {
    if (_searchQuery == q) return;
    _searchQuery = q;
    loadActivities(refresh: true);
  }

  void setFilter({
    String? category,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) {
    if (category != null) _selectedCategory = category;
    _sortBy = sortBy;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    loadActivities(refresh: true);
  }

  void setCategory(String cat) {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    loadActivities(refresh: true);
  }

  // ── Load List ────────────────────────────────────────
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
      final params = <String, dynamic>{
        'page': _currentPage,
      };
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }
      if (_selectedCategory.isNotEmpty) {
        params['category_id'] = _selectedCategory;
      }
      if (_sortBy != null) {
        params['sort'] = _sortBy;
      }
      if (_minPrice != null) {
        params['min_price'] = _minPrice;
      }
      if (_maxPrice != null) {
        params['max_price'] = _maxPrice;
      }

      final res = await _api.get(
        ApiConstants.activities,
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
          .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_currentPage == 1) {
        _activities = newItems;
      } else {
        _activities.addAll(newItems);
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

  void clearFilter() {
    _searchQuery = '';
    _selectedCategory = '';
    _sortBy = null;
    _minPrice = null;
    _maxPrice = null;
    loadActivities(refresh: true);
  }

  // ── Load Detail ──────────────────────────────────────
  Future<void> loadActivityDetail(int id) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedActivity = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.activityDetail(id));
      final data = res['data'] ?? res;
      _selectedActivity = ActivityModel.fromJson(data as Map<String, dynamic>);
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
          'bookmarkable_type': 'App\\Models\\Activity',
        },
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearDetail() {
    _selectedActivity = null;
    _detailError = null;
  }
}
