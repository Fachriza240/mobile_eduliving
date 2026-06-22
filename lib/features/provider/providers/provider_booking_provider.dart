import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/provider_models.dart';

class ProviderBookingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ProviderBookingModel> _bookings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isActing = false;
  String? _error;
  String? _successMessage;
  String _selectedStatus = '';
  int _currentPage = 1;
  bool _hasMore = true;

  List<ProviderBookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isActing => _isActing;
  String? get error => _error;
  String? get successMessage => _successMessage;
  String get selectedStatus => _selectedStatus;

  void setStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadBookings(refresh: true, isResidence: _lastIsResidence);
  }

  bool _lastIsResidence = true;

  Future<void> loadBookings({
    bool refresh = false,
    required bool isResidence,
  }) async {
    _lastIsResidence = isResidence;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _bookings = [];
    }

    if (!_hasMore) return;
    if (_isLoadingMore) return;

    if (_currentPage == 1) {
      _isLoading = true;
      _error = null;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final endpoint = isResidence
          ? ApiConstants.providerResidenceBookings
          : ApiConstants.providerEventBookings;

      final params = <String, dynamic>{'page': _currentPage};
      if (_selectedStatus.isNotEmpty) params['status'] = _selectedStatus;

      final res = await _api.get(endpoint, queryParameters: params);
      final rawData = res['data'];
      final data = rawData is List ? rawData : <dynamic>[];
      final meta = res['meta'] is Map ? res['meta'] as Map<String, dynamic> : null;

      final newItems = data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProviderBookingModel.fromJson(e))
          .toList();

      if (refresh) {
        _bookings = newItems;
      } else {
        _bookings.addAll(newItems);
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

  Future<bool> approveBooking({
    required int bookingId,
    required bool isResidence,
    String? notes,
  }) async {
    _isActing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final endpoint = isResidence
          ? ApiConstants.providerResidenceBookingApprove(bookingId)
          : ApiConstants.providerEventBookingApprove(bookingId);

      await _api.patch(endpoint, data: {'notes': notes});
      _successMessage = 'Booking berhasil disetujui.';
      _updateStatus(bookingId, 'approved');
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

  Future<bool> rejectBooking({
    required int bookingId,
    required bool isResidence,
    required String rejectionReason,
    String? notes,
  }) async {
    _isActing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final endpoint = isResidence
          ? ApiConstants.providerResidenceBookingReject(bookingId)
          : ApiConstants.providerEventBookingReject(bookingId);

      await _api.patch(endpoint, data: {
        'rejection_reason': rejectionReason,
        if (notes != null) 'notes': notes,
      });
      _successMessage = 'Booking berhasil ditolak.';
      _updateStatus(bookingId, 'rejected');
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

  void _updateStatus(int id, String status) {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      // rebuild list item with new status
      final old = _bookings[idx];
      _bookings[idx] = ProviderBookingModel(
        id              : old.id,
        bookingCode     : old.bookingCode,
        status          : status,
        bookableType    : old.bookableType,
        bookableName    : old.bookableName,
        bookableId      : old.bookableId,
        userName        : old.userName,
        userEmail       : old.userEmail,
        userPhone       : old.userPhone,
        startDate       : old.startDate,
        endDate         : old.endDate,
        totalPrice      : old.totalPrice,
        notes           : old.notes,
        rejectionReason : old.rejectionReason,
        createdAt       : old.createdAt,
      );
    }
  }

  int get pendingCount => _bookings.where((b) => b.isPending).length;

  void clearMessages() {
    _successMessage = null;
    _error = null;
  }
}
