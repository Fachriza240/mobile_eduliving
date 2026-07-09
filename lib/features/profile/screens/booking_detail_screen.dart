import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../residence/screens/residence_detail_screen.dart';
import '../../activity/screens/activity_detail_screen.dart';
import 'rating_screen.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel get booking => widget.booking;
  final _api = ApiService();
  final _picker = ImagePicker();
  String? _selectedPaymentMethod;
  File? _paymentProofFile;
  String? _paymentProofName;
  bool _isPaymentLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (booking.status == 'approved' &&
        booking.paymentDeadline != null &&
        !booking.paymentExpired &&
        (booking.transaction == null ||
            booking.transaction!['payment_status'] == 'pending' ||
            booking.transaction!['payment_status'] == 'unpaid')) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {}); // refresh UI for countdown
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EduAppBar(title: 'Detail Pemesanan'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (booking.status == 'approved' &&
                booking.paymentDeadline != null &&
                !booking.paymentExpired &&
                (booking.transaction == null ||
                    booking.transaction!['payment_status'] == 'pending' ||
                    booking.transaction!['payment_status'] == 'unpaid')) ...[
              _buildPaymentCountdown(),
              const SizedBox(height: 8),
            ],
            _buildStatusCard(),
            const SizedBox(height: 8),
            _buildItemCard(),
            const SizedBox(height: 8),
            _buildPemesanCard(),
            const SizedBox(height: 8),
            _buildProviderCard(),
            const SizedBox(height: 8),
            if (booking.isResidence && (booking.startDate != null || booking.endDate != null)) ...[
              _buildDateCard(),
              const SizedBox(height: 8),
            ],
            _buildPriceCard(),
            if (booking.status == 'completed' || (booking.status == 'approved' && booking.transaction?['payment_status'] == 'paid')) ...[
              const SizedBox(height: 8),
              _buildRatingButton(context),
            ],
            if (booking.status == 'approved') ...[
              const SizedBox(height: 8),
              if (booking.transaction != null &&
                  booking.transaction!['payment_status'] != 'pending' &&
                  booking.transaction!['payment_status'] != 'unpaid')
                _buildPaidSection()
              else
                _buildPaymentSection(),
            ],
            if (booking.isCancellable) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmCancel(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorLight,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batalkan Pemesanan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pemesanan?',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yakin ingin membatalkan? Tindakan ini tidak dapat diurungkan.',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text('Alasan Pembatalan (Opsional):',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan...',
                hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final prov = context.read<BookingProvider>();
              final ok = await prov.cancelBooking(booking.id,
                  reason: reasonCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    ok
                        ? 'Pemesanan berhasil dibatalkan.'
                        : 'Gagal membatalkan. Coba lagi.',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                if (ok) {
                  Navigator.pop(context, true);
                }
              }
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCountdown() {
    if (booking.paymentDeadline == null) return const SizedBox();
    
    final now = DateTime.now();
    final diff = booking.paymentDeadline!.difference(now);
    
    if (diff.isNegative) {
      return const SizedBox(); // Harusnya dihandle backend jika expired
    }

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(diff.inHours);
    String minutes = twoDigits(diff.inMinutes.remainder(60));
    String seconds = twoDigits(diff.inSeconds.remainder(60));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED), // orange-50
          border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFFF59E0B), size: 20), // orange-500
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Segera Lakukan Pembayaran!',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706))), // orange-600
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B), // orange-500
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Bayar Sekarang',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Booking kamu telah disetujui. Selesaikan pembayaran sebelum batas waktu habis, atau booking akan dibatalkan otomatis.',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFFB45309)), // orange-700
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Sisa waktu: ',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFFB45309))), // orange-700
                Text(
                  '$hours:$minutes:$seconds',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E)), // orange-800
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Batas akhir: ${formatDateWithTime(booking.paymentDeadline)}',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFFD97706))), // orange-600
          ],
        ),
      ),
    );
  }

  Widget _buildPaidSection() {
    final method = booking.transaction?['payment_method'] ?? 'Transfer Bank';
    final status = booking.transaction?['payment_status'] ?? 'paid';
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Informasi Pembayaran',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          InfoRow(
            icon: Icons.payments_outlined,
            label: 'Metode Pembayaran',
            value: method.toString().replaceAll('_', ' ').toUpperCase(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Pembayaran',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textHint)),
                      const SizedBox(height: 2),
                      Text(status.toString().toUpperCase(),
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: status == 'paid' ? AppColors.success : AppColors.warning)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (booking.transaction?['payment_proof'] != null)
            const InfoRow(
              icon: Icons.image_outlined,
              label: 'Bukti Pembayaran',
              value: 'Terlampir',
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return StatefulBuilder(
      builder: (context, setS) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.payment_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Proses Pembayaran',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Booking disetujui. Pilih metode pembayaran dan upload bukti bayar.',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Pilih metode pembayaran
            const Text('Metode Pembayaran *',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...[
              {
                'value': 'bank_transfer',
                'label': 'Transfer Bank',
                'icon': Icons.account_balance_outlined
              },
              {
                'value': 'e_wallet',
                'label': 'E-Wallet',
                'icon': Icons.account_balance_wallet_outlined
              },
              {'value': 'cash', 'label': 'Tunai', 'icon': Icons.money_outlined},
            ].map((m) => GestureDetector(
                  onTap: () => setState(
                      () => _selectedPaymentMethod = m['value'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == m['value']
                          ? AppColors.primaryLight
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedPaymentMethod == m['value']
                            ? AppColors.primary
                            : AppColors.border,
                        width: _selectedPaymentMethod == m['value'] ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(m['icon'] as IconData,
                          size: 20,
                          color: _selectedPaymentMethod == m['value']
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(m['label'] as String,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: _selectedPaymentMethod == m['value']
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedPaymentMethod == m['value']
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                      const Spacer(),
                      if (_selectedPaymentMethod == m['value'])
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 18),
                    ]),
                  ),
                )),

            const SizedBox(height: 12),

            // Upload bukti bayar (opsional)
            const Text('Bukti Pembayaran (opsional)',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _paymentProofFile != null
                  ? null
                  : () async {
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setState(() {
                          _paymentProofFile = File(picked.path);
                          _paymentProofName = picked.name;
                        });
                      }
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _paymentProofFile != null
                      ? AppColors.primaryLight
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _paymentProofFile != null
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _paymentProofFile != null
                        ? Icons.image_outlined
                        : Icons.upload_file_outlined,
                    size: 20,
                    color: _paymentProofFile != null
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _paymentProofFile != null
                          ? _paymentProofName!
                          : 'Upload bukti bayar (JPG/PNG)',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: _paymentProofFile != null
                              ? AppColors.primary
                              : AppColors.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_paymentProofFile != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _paymentProofFile = null;
                        _paymentProofName = null;
                      }),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.error),
                    ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Tombol bayar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                ),
                onPressed: _isPaymentLoading || _selectedPaymentMethod == null
                    ? null
                    : () => _submitPayment(),
                icon: _isPaymentLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  _isPaymentLoading ? 'Memproses...' : 'Konfirmasi Pembayaran',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    setState(() => _isPaymentLoading = true);

    try {
      final formData = FormData.fromMap({
        'payment_method': _selectedPaymentMethod!,
        if (_paymentProofFile != null)
          'payment_proof': await MultipartFile.fromFile(
            _paymentProofFile!.path,
            filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      await _api.post(
        ApiConstants.userBookingPayment(booking.id),
        formData: formData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil dikonfirmasi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // true = perlu refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaymentLoading = false);
    }
  }

  Widget _buildRatingButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ulasan',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Bagikan pengalaman kamu agar mahasiswa lain bisa mendapat info yang lebih baik.',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    isResidence: booking.isResidence,
                    rateableId: booking.bookable?['id'] ?? 0,
                    rateableName: booking.bookableName,
                  ),
                ),
              ),
              icon: const Icon(Icons.star_outline_rounded, size: 18),
              label: const Text('Beri Ulasan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status + Timeline ─────────────────────────────
  Widget _buildStatusCard() {
    final steps = [
      {'label': 'Dipesan', 'status': 'pending'},
      {'label': 'Disetujui', 'status': 'approved'},
      {'label': 'Selesai', 'status': 'completed'},
    ];

    final isCancelled =
        booking.status == 'cancelled' || booking.status == 'rejected';

    final currentIdx = isCancelled
        ? -1
        : steps.indexWhere((s) => s['status'] == booking.status);

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status Pemesanan',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              StatusBadge.booking(booking.status),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline atau Alasan Batal
          if (isCancelled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alasan Pembatalan:',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                  const SizedBox(height: 4),
                  Text(
                    booking.rejectionReason ??
                        'Dibatalkan oleh sistem atau pengguna.',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.error),
                  ),
                ],
              ),
            ),
          ] else
            Row(
              children: List.generate(
                steps.length * 2 - 1,
                (i) {
                  if (i.isOdd) {
                    final stepIdx = i ~/ 2;
                    final isActive = stepIdx < currentIdx;
                    return Expanded(
                      child: Container(
                        height: 3,
                        color: isActive ? AppColors.success : AppColors.border,
                      ),
                    );
                  }
                  final stepIdx = i ~/ 2;
                  final isDone = stepIdx <= currentIdx;
                  final isCurrent = stepIdx == currentIdx;
                  return _TimelineStep(
                    label: steps[stepIdx]['label']!,
                    isDone: isDone,
                    isCurrent: isCurrent,
                  );
                },
              ),
            ),

          // Pesan cancelled
          if (booking.status == 'cancelled')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Text('Pemesanan ini telah dibatalkan.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.error)),
              ]),
            ),

          if (booking.status == 'rejected')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.block_outlined, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pemesanan ditolak provider. Hubungi provider untuk info lebih lanjut.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.error),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Item yang Dipesan ─────────────────────────────
  Widget _buildItemCard() {
    final images = booking.bookable?['images'] as List?;
    final imgPath =
        images != null && images.isNotEmpty ? images.first.toString() : null;

    return InkWell(
      onTap: () {
        if (booking.isResidence) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResidenceDetailScreen(id: booking.bookableId),
            ),
          );
        } else if (booking.isActivity) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(id: booking.bookableId),
            ),
          );
        }
      },
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            booking.isResidence ? 'Hunian Dipesan' : 'Acara Didaftar',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: EduImage(
                path: imgPath,
                width: 76,
                height: 76,
                placeholderIcon: booking.isResidence
                    ? Icons.home_work_outlined
                    : Icons.event_outlined,
                placeholderColor: booking.isResidence
                    ? AppColors.residenceLight
                    : AppColors.activityLight,
                iconColor: booking.isResidence
                    ? AppColors.residence
                    : AppColors.activity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.bookableName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  if (booking.bookable?['address'] != null)
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          booking.bookable!['address'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ]),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: booking.isResidence
                          ? AppColors.residenceLight
                          : AppColors.activityLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.isResidence ? 'Hunian' : 'Acara',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: booking.isResidence
                            ? AppColors.residence
                            : AppColors.activity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    ),
    );
  }

  // ── Info Penyedia ─────────────────────────────────
  Widget _buildProviderCard() {
    final provider = booking.bookable?['provider'];
    if (provider == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Penyedia',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          InfoRow(
              icon: Icons.store_outlined,
              label: 'Nama Penyedia',
              value: provider['name']?.toString() ?? '-'),
          InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: provider['email']?.toString() ?? '-'),
          InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telepon',
              value: provider['phone']?.toString() ?? '-'),
        ],
      ),
    );
  }

  // ── Info Pemesan ──────────────────────────────────
  Widget _buildPemesanCard() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Pemesan',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // ← UBAH: Bungkus dengan kondisi isResidence
          if (booking.isResidence) ...[
            if (booking.fullName != null)
              InfoRow(
                  icon: Icons.person_outline,
                  label: 'Nama',
                  value: booking.fullName!),
            if (booking.email != null)
              InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: booking.email!),
            if (booking.phone != null)
              InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: booking.phone!),
          ],
          // ← UBAH: add 'bookingCode' dengan title 'Kode Booking'
          if (booking.bookingCode != null)
            InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Kode Booking',
                value: booking.bookingCode!),
          InfoRow(
              icon: Icons.receipt_outlined,
              label: 'ID Pemesanan',
              value: '#${booking.id.toString().padLeft(6, '0')}'),
          InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal Pesan',
              value: formatDateWithTime(booking.createdAt)),
          // Info peserta untuk booking acara
          if (booking.isActivity) ...[
            const SizedBox(height: 16),
            const Text('Informasi Peserta',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (booking.fullName != null)
              InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Nama Peserta',
                  value: booking.fullName!),
            if (booking.email != null)
              InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: booking.email!),
            if (booking.phone != null)
              InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: booking.phone!),
          ],
        ],
      ),
    );
  }

  // ── Periode Sewa ──────────────────────────────────
  Widget _buildDateCard() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Periode Sewa',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dateBox('Mulai', booking.startDate)),
            const SizedBox(width: 12),
            Expanded(child: _dateBox('Selesai', booking.endDate)),
          ]),
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.residenceSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.residence.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textHint)),
        const SizedBox(height: 4),
        Text(formatDateShort(date),
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.residence)),
      ]),
    );
  }

  // ── Harga ─────────────────────────────────────────
  Widget _buildPriceCard() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _priceRow(
            'Total Pembayaran',
            booking.totalPrice != null
                ? formatRupiah(booking.totalPrice!)
                : 'Gratis',
            bold: true,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Status pembayaran
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _paymentBg(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(_paymentIcon(), color: _paymentColor(), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_paymentLabel(),
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _paymentColor())),
                    Text(_paymentDesc(),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? AppColors.textPrimary)),
      ],
    );
  }

  Color _paymentColor() {
    switch (booking.status) {
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Color _paymentBg() {
    switch (booking.status) {
      case 'approved':
      case 'completed':
        return AppColors.successLight;
      case 'cancelled':
      case 'rejected':
        return AppColors.errorLight;
      default:
        return AppColors.warningLight;
    }
  }

  IconData _paymentIcon() {
    switch (booking.status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.block_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _paymentLabel() {
    switch (booking.status) {
      case 'approved':
        final isPaid = booking.transaction != null && 
                       booking.transaction!['payment_status'] != 'pending' && 
                       booking.transaction!['payment_status'] != 'unpaid';
        return isPaid ? 'Pembayaran Dikonfirmasi' : 'Menunggu Pembayaran';
      case 'completed':
        return 'Transaksi Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'rejected':
        return 'Ditolak Provider';
      default:
        return 'Menunggu Persetujuan';
    }
  }

  String _paymentDesc() {
    switch (booking.status) {
      case 'approved':
        final isPaid = booking.transaction != null && 
                       booking.transaction!['payment_status'] != 'pending' && 
                       booking.transaction!['payment_status'] != 'unpaid';
        return isPaid 
            ? 'Pemesanan Anda telah disetujui provider.' 
            : 'Silakan lakukan pembayaran sebelum batas waktu.';
      case 'completed':
        return 'Terima kasih telah menggunakan EduLiving.';
      case 'cancelled':
        return 'Pemesanan ini telah dibatalkan.';
      case 'rejected':
        return 'Provider tidak dapat memproses pemesanan ini.';
      default:
        return 'Menunggu konfirmasi provider. Biasanya 1–2 hari kerja.';
    }
  }
}

// ─────────────────────────────────────────────────────
// TIMELINE STEP
// ─────────────────────────────────────────────────────
class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isDone, isCurrent;

  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDone ? AppColors.success : AppColors.border,
          shape: BoxShape.circle,
          border:
              isCurrent ? Border.all(color: AppColors.success, width: 2) : null,
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              color: isDone ? AppColors.success : AppColors.textHint)),
    ]);
  }
}
