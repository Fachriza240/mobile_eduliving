import 'package:flutter/foundation.dart';
import '../models/bookmark_model.dart';
import '../../../core/services/api_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<BookmarkModel> _bookmarks = [];
  bool _isLoading = false;
  String? _error;

  // Set lokal id yang sedang di-bookmark (untuk optimistic update)
  final Set<String> _bookmarkedKeys = {};

  List<BookmarkModel> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter per tipe
  List<BookmarkModel> get residenceBookmarks =>
      _bookmarks.where((b) => b.bookmarkableType == 'Residence').toList();

  List<BookmarkModel> get activityBookmarks =>
      _bookmarks.where((b) => b.bookmarkableType == 'Activity').toList();

  List<BookmarkModel> get marketplaceBookmarks => _bookmarks
      .where((b) => b.bookmarkableType == 'MarketplaceProduct')
      .toList();

  String _bookmarkKey(String type, int id) => '${type}_$id';

  bool isBookmarked(String type, int id) =>
      _bookmarkedKeys.contains(_bookmarkKey(type, id));

  Future<void> fetchBookmarks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/user/bookmarks');
      // Backend return: { status, data: { bookmarks: [...], pagination: {...} } }
      final List items = response.data['data']['bookmarks'] ?? [];

      _bookmarks = items
          .map((e) =>
              BookmarkModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      _bookmarkedKeys.clear();
      for (final b in _bookmarks) {
        _bookmarkedKeys
            .add(_bookmarkKey(b.bookmarkableType, b.bookmarkable.id));
      }
    } catch (e) {
      _error = 'Gagal memuat bookmark. Coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle bookmark dengan optimistic update:
  /// UI langsung berubah, baru hit API di background.
  Future<void> toggle(String type, int id) async {
    // type dari Flutter: 'Residence' | 'Activity' | 'MarketplaceProduct'
    // Backend expect: 'residence' | 'activity' | 'marketplace_product'
    final backendType = _toBackendType(type);
    final key = _bookmarkKey(type, id);
    final wasBookmarked = _bookmarkedKeys.contains(key);

    // Optimistic update
    if (wasBookmarked) {
      _bookmarkedKeys.remove(key);
      _bookmarks.removeWhere(
        (b) => b.bookmarkableType == type && b.bookmarkable.id == id,
      );
    } else {
      _bookmarkedKeys.add(key);
    }
    notifyListeners();

    try {
      await _api.dio.post('/user/bookmarks/toggle', data: {
        'type': backendType,
        'id': id,
      });
      await fetchBookmarks();
    } catch (e) {
      // Rollback
      if (wasBookmarked) {
        _bookmarkedKeys.add(key);
      } else {
        _bookmarkedKeys.remove(key);
      }
      notifyListeners();
    }
  }

  String _toBackendType(String flutterType) {
    switch (flutterType) {
      case 'Residence':
        return 'residence';
      case 'Activity':
        return 'activity';
      case 'MarketplaceProduct':
        return 'marketplace_product';
      default:
        return 'residence';
    }
  }
}
