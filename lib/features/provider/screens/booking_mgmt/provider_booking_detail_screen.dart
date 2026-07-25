import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_booking_provider.dart';
import '../../models/provider_models.dart';

class ProviderBookingDetailScreen extends StatelessWidget {
  final ProviderBookingModel booking;
  final bool isResidence;

  const ProviderBookingDetailScreen({
    super.key,
    required this.booking,
    required this.isResidence,
  });

  @override
  Widget build(BuildContext context) {
    final color = isResidence ? AppColors.residence : AppColors.activity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          booking.bookingCode,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(booking.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(booking.status),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _statusColor(booking.status),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Listing ───────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    isResidence ? 'Informasi Hunian' : 'Informasi Acara',
                    isResidence ? Icons.home_work_outlined : Icons.event_outlined,
                    color,
                  ),
                  const SizedBox(height: 12),
                  _row('Nama', booking.bookableName),
                  _row('Tipe', isResidence ? 'Hunian' : 'Acara'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Info Pemesan ───────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Informasi Pemesan', Icons.person_outline_rounded, color),
                  const SizedBox(height: 12),
                  _row('Nama', booking.userName),
                  _row('Email', booking.userEmail),
                  if (booking.userPhone != null) _row('Telepon', booking.userPhone!),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Detail Booking ─────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Detail Booking', Icons.receipt_long_outlined, color),
                  const SizedBox(height: 12),
                  _row('Kode Booking', booking.bookingCode),
                  if (booking.startDate != null) _row('Mulai', formatDate(booking.startDate)),
                  if (booking.endDate != null) _row('Selesai', formatDate(booking.endDate)),
                  _row('Total Harga', formatRupiah(booking.totalPrice),
                    valueStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  _row('Dibuat', formatDate(booking.createdAt)),
                  if (booking.notes != null && booking.notes!.isNotEmpty)
                    _row('Catatan', booking.notes!),
                ],
              ),
            ),

            if (booking.documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Dokumen', Icons.badge_outlined, color),
                    const SizedBox(height: 4),
                    const Text(
                      'Untuk verifikasi identitas penyewa',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: booking.documents
                          .map((doc) => _documentPreview(context, doc))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            // ── Alasan penolakan ───────────────────────
            if (booking.isRejected && booking.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.error, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Alasan Penolakan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.rejectionReason!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Tombol Aksi ────────────────────────────
            if (booking.isPending) ...[
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final prov = context.read<ProviderBookingProvider>();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Tolak'),
            onPressed: () => _showRejectDialog(context, prov),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Setujui'),
            onPressed: () => _confirmApprove(context, prov),
          ),
        ),
      ],
    );
  }

  void _confirmApprove(BuildContext ctx, ProviderBookingProvider prov) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Booking?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.approveBooking(
                bookingId: booking.id,
                isResidence: isResidence,
              );
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? 'Booking disetujui!' : prov.error ?? 'Gagal'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
                if (ok) Navigator.pop(ctx);
              }
            },
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext ctx, ProviderBookingProvider prov) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Booking',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan penolakan *',
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final ok = await prov.rejectBooking(
                bookingId: booking.id,
                isResidence: isResidence,
                rejectionReason: reasonCtrl.text.trim(),
              );
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? 'Booking ditolak.' : prov.error ?? 'Gagal'),
                  backgroundColor: ok ? AppColors.warning : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
                if (ok) Navigator.pop(ctx);
              }
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.8),
    ),
    child: child,
  );

  Widget _sectionTitle(String title, IconData icon, Color color) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );

Widget _documentPreview(BuildContext context, BookingDocumentModel doc) {
    return GestureDetector(
      onTap: () => _openDocument(context, doc),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 130,
                height: 90,
                color: AppColors.background,
                child: doc.isImage
                    ? EduImage(
                        path: doc.url,
                        width: 130,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(Icons.picture_as_pdf_outlined,
                            size: 32, color: AppColors.textHint),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    doc.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDocument(BuildContext context, BookingDocumentModel doc) {
    if (!doc.isImage) {
      launchUrl(Uri.parse(doc.url), mode: LaunchMode.externalApplication);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DocumentViewerScreen(doc: doc),
      ),
    );
  }
  Widget _row(String label, String value, {TextStyle? valueStyle}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    ),
  );

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':  return AppColors.success;
      case 'rejected':  return AppColors.error;
      case 'completed': return AppColors.primary;
      case 'cancelled': return AppColors.textSecondary;
      default:          return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':  return 'Disetujui';
      case 'rejected':  return 'Ditolak';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default:          return 'Menunggu';
    }
  }
}

class _DocumentViewerScreen extends StatelessWidget {
  final BookingDocumentModel doc;

  const _DocumentViewerScreen({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          doc.label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: EduImage(
            path: doc.url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}