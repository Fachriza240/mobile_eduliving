class BookingModel {
  final int id;
  final int userId;
  final int bookableId;
  final String bookableType;
  final String? bookingCode;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? totalPrice;
  final String? fullName;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? bookable;
  final Map<String, dynamic>? transaction;
  final DateTime? createdAt;
  final DateTime? paymentDeadline;
  final bool paymentExpired;

  BookingModel({
    required this.id,
    required this.userId,
    required this.bookableId,
    required this.bookableType,
    required this.status,
    this.bookingCode,
    this.startDate,
    this.endDate,
    this.totalPrice,
    this.fullName,
    this.email,
    this.phone,
    this.bookable,
    this.transaction,
    this.createdAt,
    this.paymentDeadline,
    this.paymentExpired = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      bookingCode: json['booking_code'],
      userId: json['user_id'] ?? 0,
      bookableId: json['bookable_id'] ?? 0,
      bookableType: json['bookable_type'] ?? '',
      status: json['status'] ?? 'pending',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : (json['check_in_date'] != null
              ? DateTime.tryParse(json['check_in_date'].toString())
              : null),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : (json['check_out_date'] != null
              ? DateTime.tryParse(json['check_out_date'].toString())
              : null),
      totalPrice: json['total_price'] != null
          ? double.tryParse(json['total_price'].toString())
          : null,
      fullName: json['participant_name'] ?? json['full_name'],
      email: json['participant_email'] ?? json['email'],
      phone: json['participant_phone'] ?? json['phone'],
      bookable: json['bookable'] as Map<String, dynamic>?,
      transaction: json['transaction'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      paymentDeadline: json['payment_deadline'] != null
          ? DateTime.tryParse(json['payment_deadline'].toString())
          : null,
      paymentExpired: json['payment_expired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'bookable_id': bookableId,
        'bookable_type': bookableType,
        'status': status,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'total_price': totalPrice,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'bookable': bookable,
        'transaction': transaction,
        'created_at': createdAt?.toIso8601String(),
      };

  // ── Helpers ──────────────────────────────────────────
  bool get isResidence => bookableType.toLowerCase().contains('residence');

  bool get isActivity => bookableType.toLowerCase().contains('activity');

  String get bookableName => bookable?['name'] ?? '-';

  // Label status Bahasa Indonesia
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  // Warna tiap status
  static const Map<String, int> _statusColors = {
    'pending': 0xFFD97706, // amber
    'approved': 0xFF16A34A, // green
    'rejected': 0xFFDC2626, // red
    'cancelled': 0xFF6B7280, // gray
    'completed': 0xFF2563EB, // blue
  };

  int get statusColorValue => _statusColors[status] ?? 0xFF6B7280;

  // Cek apakah booking bisa dibatalkan
  bool get isCancellable => status == 'pending';
}
