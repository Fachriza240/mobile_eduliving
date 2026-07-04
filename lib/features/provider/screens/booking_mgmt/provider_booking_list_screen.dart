import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_booking_provider.dart';
import '../../models/provider_models.dart';
import 'provider_booking_detail_screen.dart';

class ProviderBookingListScreen extends StatefulWidget {
  final bool isResidence;
  const ProviderBookingListScreen({super.key, required this.isResidence});

  @override
  State<ProviderBookingListScreen> createState() => _ProviderBookingListScreenState();
}

class _ProviderBookingListScreenState extends State<ProviderBookingListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final _statusFilters = const [
    {'id': '', 'label': 'Semua'},
    {'id': 'pending',   'label': 'Menunggu'},
    {'id': 'approved',  'label': 'Disetujui'},
    {'id': 'rejected',  'label': 'Ditolak'},
    {'id': 'completed', 'label': 'Selesai'},
    {'id': 'cancelled', 'label': 'Dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingProvider>().loadBookings(
        refresh: true,
        isResidence: widget.isResidence,
        search: _searchQuery,
      );
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ProviderBookingProvider>().loadBookings(
          isResidence: widget.isResidence,
          search: _searchQuery,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isResidence ? AppColors.residence : AppColors.activity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.isResidence ? AppColors.residenceLight : AppColors.activityLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Manajemen Booking',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusFilter(color),
          _buildSearchBar(color),
          Expanded(child: _buildContent(color)),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(Color color) {
    return Consumer<ProviderBookingProvider>(
      builder: (_, prov, __) => Container(
        height: 48,
        color: AppColors.white,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _statusFilters.length,
          itemBuilder: (_, i) => FilterChipWidget(
            label: _statusFilters[i]['label']!,
            isSelected: prov.selectedStatus == _statusFilters[i]['id'],
            onTap: () => prov.setStatus(_statusFilters[i]['id']!),
            selectedColor: color,
          ),
        ),
      ),
    );
  }
  Widget _buildSearchBar(Color color) {
  return Container(
    color: AppColors.white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: TextField(
      controller: _searchCtrl,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Cari kode booking atau nama user...',
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
        prefixIcon: Icon(Icons.search_rounded, color: color, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                  context.read<ProviderBookingProvider>().loadBookings(
                    refresh: true,
                    isResidence: widget.isResidence,
                  );
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      onChanged: (v) {
        setState(() => _searchQuery = v);
        context.read<ProviderBookingProvider>().loadBookings(
          refresh: true,
          isResidence: widget.isResidence,
          search: v.trim(),
        );
      },
    ),
  );
}

  Widget _buildContent(Color color) {
    return Consumer<ProviderBookingProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => _BookingSkelCard(),
          );
        }

        if (prov.error != null && prov.bookings.isEmpty) {
          return ErrorState(
            message: prov.error!,
            onRetry: () => prov.loadBookings(
              refresh: true,
              isResidence: widget.isResidence,
              search: _searchQuery,
            ),
          );
        }

        if (prov.bookings.isEmpty) {
          return EmptyState(
            message: 'Belum ada booking masuk.',
            icon: Icons.receipt_long_outlined,
            iconColor: color,
          );
        }

        return RefreshIndicator(
          onRefresh: () => prov.loadBookings(
            refresh: true,
            isResidence: widget.isResidence,
            search: _searchQuery, 
          ),
          color: color,
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: prov.bookings.length + (prov.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == prov.bookings.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  ),
                );
              }
              final b = prov.bookings[i];
              return _BookingCard(
                booking: b,
                color: color,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ProviderBookingDetailScreen(
                      booking: b,
                      isResidence: widget.isResidence,
                    ),
                  ),
                ),
                onApprove: b.isPending
                    ? () => _confirmApprove(ctx, b, prov)
                    : null,
                onReject: b.isPending
                    ? () => _showRejectDialog(ctx, b, prov)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _confirmApprove(
    BuildContext ctx,
    ProviderBookingModel b,
    ProviderBookingProvider prov,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Setujui Booking?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Booking dari ${b.userName} (${b.bookableName}) akan disetujui.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.approveBooking(
                bookingId: b.id,
                isResidence: widget.isResidence,
              );
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? 'Booking disetujui!' : prov.error ?? 'Gagal'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext ctx,
    ProviderBookingModel b,
    ProviderBookingProvider prov,
  ) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tolak Booking',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking dari ${b.userName} (${b.bookableName})',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan *',
                  hintText: 'Jelaskan alasan penolakan...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final ok = await prov.rejectBooking(
                bookingId: b.id,
                isResidence: widget.isResidence,
                rejectionReason: reasonCtrl.text.trim(),
              );
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? 'Booking ditolak.' : prov.error ?? 'Gagal'),
                  backgroundColor: ok ? AppColors.warning : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final ProviderBookingModel booking;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _BookingCard({
    required this.booking,
    required this.color,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _statusColor(booking.status).withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.bookingCode,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: booking.status),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.bookableName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _row(Icons.person_outline_rounded, booking.userName),
                  const SizedBox(height: 4),
                  _row(Icons.email_outlined, booking.userEmail),
                  if (booking.userPhone != null) ...[
                    const SizedBox(height: 4),
                    _row(Icons.phone_outlined, booking.userPhone!),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatRupiah(booking.totalPrice),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        formatDate(booking.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),

                  // Tombol aksi (hanya jika pending)
                  if (onApprove != null || onReject != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (onReject != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(0, 40),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Tolak', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        if (onApprove != null && onReject != null)
                          const SizedBox(width: 8),
                        if (onApprove != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onApprove,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                minimumSize: const Size(0, 40),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Setujui', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.textHint),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':  return AppColors.success;
      case 'rejected':  return AppColors.error;
      case 'completed': return AppColors.primary;
      case 'cancelled': return AppColors.textHint;
      default:          return AppColors.warning;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'approved'  => ('Disetujui', AppColors.success, AppColors.successLight),
      'rejected'  => ('Ditolak',   AppColors.error,   AppColors.errorLight),
      'completed' => ('Selesai',   AppColors.primary, AppColors.primaryLight),
      'cancelled' => ('Dibatalkan',AppColors.textSecondary, AppColors.background),
      _           => ('Menunggu',  AppColors.warning, AppColors.warningLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────
class _BookingSkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 120, height: 14),
              SkeletonBox(width: 70, height: 24, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonBox(width: 200, height: 16),
          const SizedBox(height: 8),
          SkeletonBox(width: 160, height: 13),
          const SizedBox(height: 6),
          SkeletonBox(width: 180, height: 13),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 100, height: 18),
              SkeletonBox(width: 80, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}
