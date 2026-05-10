import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/widgets/common_widgets.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EduAppBar(title: 'Detail Pemesanan'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 8),
            _buildItemCard(),
            const SizedBox(height: 8),
            _buildPemesanCard(),
            const SizedBox(height: 8),
            if (booking.isResidence) ...[
              _buildDateCard(),
              const SizedBox(height: 8),
            ],
            _buildPriceCard(),
            const SizedBox(height: 32),
          ],
        ),
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

          // Timeline
          if (!isCancelled)
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

    return Container(
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
          InfoRow(
              icon: Icons.receipt_outlined,
              label: 'ID Pemesanan',
              value: '#${booking.id.toString().padLeft(6, '0')}'),
          InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal Pesan',
              value: formatDate(booking.createdAt)),
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
        return 'Pembayaran Dikonfirmasi';
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
        return 'Pemesanan Anda telah disetujui provider.';
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
