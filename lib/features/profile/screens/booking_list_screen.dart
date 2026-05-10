import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _tabs = const [
    {'label': 'Semua', 'status': ''},
    {'label': 'Menunggu', 'status': 'pending'},
    {'label': 'Aktif', 'status': 'approved'},
    {'label': 'Selesai', 'status': 'completed'},
    {'label': 'Dibatalkan', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pemesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => const _BookingSkelCard(),
            );
          }

          if (prov.error != null) {
            return ErrorState(
              message: prov.error!,
              onRetry: () => prov.loadBookings(),
            );
          }

          return TabBarView(
            controller: _tabCtrl,
            children: _tabs.map((t) {
              final status = t['status'] as String;
              final items = status.isEmpty
                  ? prov.allBookings
                  : prov.allBookings.where((b) => b.status == status).toList();

              if (items.isEmpty) {
                return EmptyState(
                  message: status.isEmpty
                      ? 'Belum ada riwayat pemesanan.\nMulai pesan hunian atau daftar acara!'
                      : 'Tidak ada pemesanan ${_statusLabel(status)}.',
                  icon: Icons.receipt_long_outlined,
                  actionLabel: status.isEmpty ? 'Jelajahi Hunian' : null,
                  onAction:
                      status.isEmpty ? () => Navigator.pop(context) : null,
                );
              }

              return RefreshIndicator(
                onRefresh: () => prov.loadBookings(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _BookingCard(
                    booking: items[i],
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(booking: items[i]),
                      ),
                    ),
                    onCancel: items[i].isCancellable
                        ? () => _confirmCancel(ctx, prov, items[i].id)
                        : null,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'menunggu';
      case 'approved':
        return 'aktif';
      case 'completed':
        return 'selesai';
      case 'cancelled':
        return 'dibatalkan';
      default:
        return s;
    }
  }

  void _confirmCancel(BuildContext context, BookingProvider prov, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pemesanan?',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Yakin ingin membatalkan? Tindakan ini tidak dapat diurungkan.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await prov.cancelBooking(id);
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
              }
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// CARD BOOKING
// ─────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final images = booking.bookable?['images'] as List?;
    final imgPath =
        images != null && images.isNotEmpty ? images.first.toString() : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: EduImage(
                    path: imgPath,
                    width: 64,
                    height: 64,
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
                      Row(children: [
                        Icon(
                          booking.isResidence
                              ? Icons.home_work_outlined
                              : Icons.event_outlined,
                          size: 13,
                          color: booking.isResidence
                              ? AppColors.residence
                              : AppColors.activity,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.isResidence ? 'Hunian' : 'Acara',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: booking.isResidence
                                ? AppColors.residence
                                : AppColors.activity,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(booking.bookableName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'Dipesan ${formatDateShort(booking.createdAt)}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                StatusBadge.booking(booking.status),
              ]),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // ── Footer ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (booking.isResidence && booking.startDate != null)
                        Text(
                          '${formatDateShort(booking.startDate)} – ${formatDateShort(booking.endDate)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      if (booking.totalPrice != null)
                        Text(
                          formatRupiah(booking.totalPrice!),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                    ],
                  ),
                  Row(children: [
                    if (onCancel != null) ...[
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Batalkan',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Detail',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SKELETON
// ─────────────────────────────────────────────────────
class _BookingSkelCard extends StatelessWidget {
  const _BookingSkelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        SkeletonBox(width: 64, height: 64, borderRadius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 80, height: 12),
              const SizedBox(height: 6),
              SkeletonBox(width: 180, height: 16),
              const SizedBox(height: 6),
              SkeletonBox(width: 120, height: 12),
            ],
          ),
        ),
        SkeletonBox(width: 70, height: 24, borderRadius: 12),
      ]),
    );
  }
}
