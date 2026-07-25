import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String _filterStatus = '';

  // ── Getters ──────────────────────────────────────────
  List<BookingModel> get allBookings => _bookings;

  List<BookingModel> get bookings {
    if (_filterStatus.isEmpty) return _bookings;
    return _bookings.where((b) => b.status == _filterStatus).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;

  // ── Load Semua Booking ───────────────────────────────
  Future<void> loadBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.userBookings);

      List<dynamic> rawList = [];

      if (res['data'] is List) {
        rawList = res['data'] as List;
      } else if (res['data'] is Map) {
        final map = res['data'] as Map<String, dynamic>;
        if (map['data'] is List) {
          rawList = map['data'] as List;
        }
      }

      _bookings = rawList
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLoading = false;
    } catch (e) {
      _error = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    try {
      await _api.patch(
        ApiConstants.userBookingCancel(bookingId),
        data: {'reason': reason},
      );

      // Update status lokal tanpa reload
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        final old = _bookings[idx];
        _bookings[idx] = BookingModel.fromJson({
          ...old.toJson(),
          'status': 'cancelled',
          'rejection_reason': reason,
        });
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> renewBooking(int bookingId, int durationMonths) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.userBookingRenew(bookingId),
        data: {'duration_months': durationMonths},
      );
      
      // Data yang dikembalikan adalah booking baru (pending).
      // Kita tambahkan ke list di bagian depan agar muncul pertama.
      if (res['data'] != null) {
        final newBooking = BookingModel.fromJson(res['data'] as Map<String, dynamic>);
        _bookings.insert(0, newBooking);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Filter by Status ─────────────────────────────────
  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void clearFilter() {
    _filterStatus = '';
    notifyListeners();
  }

  // ── Hitung per Status ────────────────────────────────
  int countByStatus(String status) =>
      _bookings.where((b) => b.status == status).length;

  // ── Reset ────────────────────────────────────────────
  void reset() {
    _bookings = [];
    _filterStatus = '';
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
